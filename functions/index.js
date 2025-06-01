import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated } from "firebase-functions/v2/firestore"; // ✅ keep this ONCE
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onRequest } from "firebase-functions/v2/https";
import admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

const FieldValue = admin.firestore.FieldValue;

// Return the server timestamp
export const getServerTime = onRequest(async (req, res) => {
  res.json({ now: Date.now() });
});

const bannedPhrases = [
  "mike",
  "poor",
  "idiot",
  "scam",
  "scammer",
  "rug",
  "dev is poor",
];

export const notifyEligibleRewards = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "America/New_York",
  },
  async () => {
    const db = getFirestore();
    const now = Date.now();

    const snapshot = await db
      .collection("users")
      .where("last_claimed", "<=", new Date(now - 24 * 60 * 60 * 1000)) // 24h
      .where("rewardNotified", "in", [false, null])
      .get();

    if (snapshot.empty) {
      console.log("🟡 No users eligible for reward notifications");
      return;
    }

    for (const doc of snapshot.docs) {
      const user = doc.data();
      const fcmToken = user.fcmToken;
      const username = user.username || "user";

      if (!fcmToken) {
        console.warn(`⚠️ ${doc.id} missing FCM token`);
        continue;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: "🎁 Daily Reward Ready!",
          body: `Hey ${username}, your daily reward is ready to claim.`,
        },
        android: { priority: "high" },
        apns: {
          headers: { "apns-push-type": "alert", "apns-priority": "10" },
          payload: { aps: { sound: "default", badge: 1 } },
        },
      };

      try {
        await getMessaging().send(message);
        console.log(`✅ Sent reward notification to ${doc.id}`);
        await doc.ref.update({ rewardNotified: true });
      } catch (err) {
        console.error(`❌ Failed to notify ${doc.id}`, err);
      }
    }
  }
);

export const moderateChatMessage = onDocumentCreated(
  { document: "chat/{messageId}" },
  async (event) => {
    const db = getFirestore();
    const data = event.data?.data();
    const ref = event.data?.ref;

    if (!data || !ref) return;

    const messageText = data.message || "";
    const sender = data.sender;

    // ✅ /silence command handling
    if (messageText.trim().toLowerCase() === "/silence" && sender !== "System") {
      const chatControlRef = db.collection("app_settings").doc("chat_controls");

      await chatControlRef.set(
        {
          isSilenced: true,
          updatedBy: sender,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      console.log(`🔇 Chat silenced by ${sender}`);

      await db.collection("chat").add({
        message: "🔇 Chat has been silenced for 10 seconds.",
        sender: "System",
        tier: "system",
        room: data.room || "General",
        timestamp: admin.firestore.Timestamp.now(),
        createdAt: FieldValue.serverTimestamp(),
      });

      await ref.delete(); // Remove /silence message

      setTimeout(async () => {
        await chatControlRef.set(
          {
            isSilenced: false,
            updatedBy: "auto",
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        await db.collection("chat").add({
          message: "🔊 Chat has been automatically unsilenced.",
          sender: "System",
          tier: "system",
          room: data.room || "General",
          timestamp: admin.firestore.Timestamp.now(),
          createdAt: FieldValue.serverTimestamp(),
        });

        console.log(`🔊 Auto-unsilenced after 10s`);
      }, 10_000); // 10 seconds

      return;
    }

    // ✅ /unsilence fallback (manual)
    if (messageText.trim().toLowerCase() === "/unsilence" && sender !== "System") {
      const chatControlRef = db.collection("app_settings").doc("chat_controls");

      await chatControlRef.set(
        {
          isSilenced: false,
          updatedBy: sender,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await db.collection("chat").add({
        message: "🔊 Chat has been manually unsilenced.",
        sender: "System",
        tier: "system",
        room: data.room || "General",
        timestamp: admin.firestore.Timestamp.now(),
        createdAt: FieldValue.serverTimestamp(),
      });

      console.log(`🔊 Manual unsilence by ${sender}`);
      await ref.delete(); // Remove command
      return;
    }

    // ✅ Global chat silence enforcement
    const chatControlDoc = await db.collection("app_settings").doc("chat_controls").get();
    const isSilenced = chatControlDoc.exists && chatControlDoc.data()?.isSilenced === true;

    if (isSilenced && sender !== "System") {
      console.log(`🚫 Chat is silenced. Auto-deleting message from ${sender}`);
      await ref.delete();
      return;
    }

    // ✅ Banned phrase filtering
    const bannedPhrases = [
      "mike", "poor", "idiot", "scam", "scammer", "rug", "dev is poor"
    ];

    const containsBanned = bannedPhrases.some((phrase) => {
      const regex = new RegExp(`\\b${phrase}\\b`, "i");
      return regex.test(messageText);
    });

    if (containsBanned) {
      console.log(`🔥 Auto-deleting banned message: "${data.message}" from ${sender}`);
      await ref.delete();

      const strikesRef = db.collection("spam_strikes").doc(sender);
      const strikesSnap = await strikesRef.get();
      const currentStrikes = strikesSnap.exists ? strikesSnap.data().count || 0 : 0;

      await strikesRef.set({ count: currentStrikes + 1 }, { merge: true });
      console.log(`⚠️ Strike ${currentStrikes + 1} for ${sender}`);

      if (currentStrikes + 1 >= 3) {
        await db.collection("banned_wallets").doc(sender).set({
          reason: "Repeated message violations",
          bannedAt: FieldValue.serverTimestamp(),
        });
        console.log(`🚫 ${sender} added to banned_wallets after 3 strikes`);
      }
    }
  }
);


export const giveawayNotification = onDocumentCreated(
  { document: "giveaways/{giveawayId}" },
  async (event) => {
    const db = getFirestore();
    const ref = event.data?.ref;
    const data = event.data?.data();

    if (!data || !ref) return;

    let token;
    try {
      const tokenId = data.tokenId || "WAGUS"; // fallback to WAGUS if somehow missing
      const tokenDoc = await db
        .collection("supported_tokens")
        .doc(tokenId)
        .get();

      if (!tokenDoc.exists) throw new Error("Token not found");

      token = {
        name: tokenDoc.data().name,
        ticker: tokenDoc.data().ticker,
        address: tokenDoc.data().address,
        decimals: tokenDoc.data().decimals,
      };
    } catch (err) {
      console.warn("❌ Token not found. Falling back to BUCKAZOIDS");
      token = {
        name: "WAGUS",
        ticker: "WAGUS",
        address: "7BMxgTQhTthoBcQizzFoLyhmSDscM56uMramXGMhpump",
        decimals: 6,
      };
    }

    let { amount, keyword, endTimestamp, duration } = data;

    // ✅ Patch: If endTimestamp missing, generate it using server time
    if (!endTimestamp) {
      const fallbackDuration = typeof duration === "number" ? duration : 60;
      endTimestamp = Date.now() + fallbackDuration * 1000;

      // Update Firestore doc with trusted server time
      await ref.update({ endTimestamp });
      console.log(`⏱️ Patched endTimestamp on server for ${ref.id}`);
    }

    const timeLeft = Math.floor((endTimestamp - Date.now()) / 1000);

    const message = {
      topic: "global_users",
      notification: {
        title: "🎉 New Giveaway!",
        body: `Type "${keyword}" to win ${amount} $${token.ticker}! Ends in ${timeLeft}s`,
      },
      android: { priority: "high" },
      apns: {
        headers: { "apns-push-type": "alert", "apns-priority": "10" },
        payload: { aps: { sound: "default" } },
      },
    };

    try {
      const res = await getMessaging().send(message);
      console.log(`✅ Giveaway notification sent: ${res}`);
    } catch (err) {
      console.error("❌ Giveaway notification error:", err);
    }
  }
);

export const sugawAiResponder = onDocumentCreated(
  { document: "chat/{messageId}" },
  async (event) => {
    console.log("✅ Triggered sugawAiResponder");

    const snapshot = event.data;
    if (!snapshot || !snapshot.data) {
      console.log("⚠️ No snapshot data");
      return;
    }

    const data = snapshot.data();
    console.log("📦 Data:", data);

    const messageText = data.message || "";
    const sender = data.sender;
    const room = data.room || "General";

    if (sender === "System") {
      console.log("ℹ️ Skipping system sender");
      return;
    }

    const triggers = ["sugaw", "wagus", "project", "how", "what", "?"];
    const shouldRespond = triggers.some((word) =>
      messageText.toLowerCase().includes(word)
    );

    console.log("🧠 shouldRespond:", shouldRespond);

    if (!shouldRespond) return;

    const responses = [
      "SUGAW? That’s classified info, but you’re on the right path.",
      "WAGUS was built by one dev. You’re witnessing the blueprint.",
      "Need help? Just type /commands. Or don’t. I’ll survive.",
      "This project? No fluff. No VC leash. Just proof-of-grind.",
      "SUGAW sees you. Stay sharp.",
    ];

    const response = responses[Math.floor(Math.random() * responses.length)];

    console.log("💬 Responding with:", response);

    await snapshot.ref.firestore.collection("chat").add({
      message: response,
      sender: "System",
      tier: "system",
      room,
      timestamp: admin.firestore.Timestamp.fromMillis(Date.now()), // ✅ immediate
      createdAt: FieldValue.serverTimestamp(), // optional audit trail
    });

    console.log("✅ Bot response sent");
  }
);

export const pickGiveawayWinner = onSchedule(
  { schedule: "* * * * *", timeZone: "America/New_York" },
  async () => {
    const db = getFirestore();
    const now = Date.now();

    try {
      const snapshot = await db
        .collection("giveaways")
        .where("status", "==", "started")
        .where("endTimestamp", "<=", now)
        .get();

      if (snapshot.empty) {
        console.log("🟡 No giveaways to close");
        return;
      }

      for (const doc of snapshot.docs) {
        try {
          const data = doc.data();
          const participants = Array.isArray(data.participants)
            ? data.participants
            : [];
          const amount = typeof data.amount === "number" ? data.amount : 0;
          const host = data.host || "system";
          const winner = participants.length
            ? participants[Math.floor(Math.random() * participants.length)]
            : null;

          await doc.ref.update({
            status: "ended",
            winner: winner ?? "No winner",
            hasSent: winner ? false : true,
            updatedAt: FieldValue.serverTimestamp(),
          });

          let token;
          try {
            const tokenId = data.tokenId || "WAGUS"; // fallback
            const tokenDoc = await db
              .collection("supported_tokens")
              .doc(tokenId)
              .get();
            if (!tokenDoc.exists) throw new Error("Token not found");

            token = {
              name: tokenDoc.data().name,
              ticker: tokenDoc.data().ticker,
              address: tokenDoc.data().address,
              decimals: tokenDoc.data().decimals,
            };
          } catch (err) {
            console.warn("❌ Token not found. Falling back to WAGUS");
            token = {
              name: "WAGUS",
              ticker: "WAGUS",
              address: "7BMxgTQhTthoBcQizzFoLyhmSDscM56uMramXGMhpump",
              decimals: 6,
            };
          }

          if (winner) {
            await db.collection("chat").add({
              message: `/send ${amount} ${winner} ${token.ticker}`,
              sender: host,
              tier: "adventurer",
              room: "General",
              timestamp: Date.now(),
            });
            console.log(`💸 Injected /send ${amount} to ${winner}`);
          }

          console.log(
            `✅ Giveaway ended: ${doc.id}, winner: ${winner ?? "none"}`
          );

          const message = {
            topic: "global_users",
            notification: {
              title: "🏁 Giveaway Ended!",
              body: winner
                ? `${winner} won ${amount} $${token.ticker}!`
                : "No one entered this giveaway.",
            },
            android: { priority: "high" },
            apns: {
              headers: { "apns-push-type": "alert", "apns-priority": "10" },
              payload: { aps: { sound: "default" } },
            },
          };

          await getMessaging().send(message);
          console.log(`✅ Sent winner notification for ${doc.id}`);
        } catch (innerErr) {
          console.error(`❌ Failed to process giveaway ${doc.id}:`, innerErr);
        }
      }
    } catch (outerErr) {
      console.error("🔥 Error running pickGiveawayWinner:", outerErr);
    }
  }
);

export const runGiveawayWinnerNow = onRequest(async (req, res) => {
  const db = getFirestore();
  const now = Date.now();

  try {
    const snapshot = await db
      .collection("giveaways") // change to 'giveaways_test' if needed
      .where("status", "==", "started")
      .where("endTimestamp", "<=", now)
      .get();

    if (snapshot.empty) {
      console.log("🟡 No giveaways to close");
      return res.status(200).send("No active giveaways to end.");
    }

    for (const doc of snapshot.docs) {
      try {
        const data = doc.data();
        const participants = Array.isArray(data.participants)
          ? data.participants
          : [];
        const amount = typeof data.amount === "number" ? data.amount : 0;
        const host = data.host || "system";
        const winner = participants.length
          ? participants[Math.floor(Math.random() * participants.length)]
          : null;

        let token;
        try {
          const tokenId = data.tokenId || "WAGUS"; // fallback
          const tokenDoc = await db
            .collection("supported_tokens")
            .doc(tokenId)
            .get();
          if (!tokenDoc.exists) throw new Error("Token not found");

          token = {
            name: tokenDoc.data().name,
            ticker: tokenDoc.data().ticker,
            address: tokenDoc.data().address,
            decimals: tokenDoc.data().decimals,
          };
        } catch (err) {
          console.warn("❌ Token not found. Falling back to WAGUS");
          token = {
            name: "WAGUS",
            ticker: "WAGUS",
            address: "7BMxgTQhTthoBcQizzFoLyhmSDscM56uMramXGMhpump",
            decimals: 6,
          };
        }

        try {
          await doc.ref.update({
            status: "ended",
            winner: winner ?? "No winner",
            hasSent: winner ? false : true,
            updatedAt: FieldValue.serverTimestamp(),
          });
          if (winner) {
            await db.collection("chat").add({
              message: `/send ${amount} ${winner} ${token.ticker}`,
              sender: host,
              tier: "adventurer",
              room: "General",
              timestamp: Date.now(),
            });
            console.log(`💸 Injected /send ${amount} to ${winner}`);
          }

          console.log(
            `✅ Giveaway ended: ${doc.id}, winner: ${winner ?? "none"}`
          );
        } catch (err) {
          console.error(`❌ Failed to end giveaway ${doc.id}`, data, err);
        }

        const message = {
          topic: "global_users",
          notification: {
            title: "🏁 Giveaway Ended!",
            body: winner
              ? `${winner} won ${amount} $${token.ticker}!`
              : "No one entered this giveaway.",
          },
          android: { priority: "high" },
          apns: {
            headers: { "apns-push-type": "alert", "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
        };

        await getMessaging().send(message);
        console.log(`✅ Sent winner notification for ${doc.id}`);
      } catch (err) {
        console.error(`❌ Failed to process giveaway ${doc.id}`, err);
      }
    }

    res.status(200).send("Giveaway logic executed.");
  } catch (err) {
    console.error("🔥 Manual trigger failed", err);
    res.status(500).send("Internal error");
  }
});
