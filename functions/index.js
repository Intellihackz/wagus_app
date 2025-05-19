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

export const moderateChatMessage = onDocumentCreated(
  { document: "chat/{messageId}" },
  async (event) => {
    const data = event.data?.data();
    const ref = event.data?.ref;

    if (!data || !ref) return;

    const messageText = data.message || "";
    const sender = data.sender;

    const containsBanned = bannedPhrases.some((phrase) => {
      const regex = new RegExp(`\\b${phrase}\\b`, "i");
      return regex.test(messageText);
    });

    if (containsBanned) {
      console.log(`🔥 Auto-deleting message: "${data.message}" from ${sender}`);
      await ref.delete();

      // Strike logic
      const strikesRef = db.collection("spam_strikes").doc(sender);
      const strikesSnap = await strikesRef.get();
      const currentStrikes = strikesSnap.exists
        ? strikesSnap.data().count || 0
        : 0;

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

export const dailyRewardNotification = onSchedule(
  {
    schedule: "10 11 * * *",
    timeZone: "America/New_York",
  },
  async () => {
    const message = {
      topic: "daily_reward",
      notification: {
        title: "Daily Reward",
        body: "🎁 Your daily reward is ready! Open the app to claim it.",
      },
      apns: {
        headers: { "apns-push-type": "alert", "apns-priority": "10" },
        payload: { aps: { sound: "default", badge: 1 } },
      },
      android: { priority: "high" },
    };

    try {
      const res = await getMessaging().send(message);
      console.log(`✅ Sent daily reward: ${res}`);
    } catch (err) {
      console.error("❌ Failed to send daily reward:", err);
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

    const token = {
      name: data.name || "Buckazoids",
      ticker: data.ticker || "BUCKAZOIDS",
      address: data.address || "BQQzEvYT4knThhkSPBvSKBLg1LEczisWLhx5ydJipump",
      decimals: typeof data.decimals === "number" ? data.decimals : 6,
    };

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

          const token = {
            name: data.name || "Buckazoids",
            ticker: data.ticker || "BUCKAZOIDS",
            address:
              data.address || "BQQzEvYT4knThhkSPBvSKBLg1LEczisWLhx5ydJipump",
            decimals: typeof data.decimals === "number" ? data.decimals : 6,
          };

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

          // ✅ Mark as announced to prevent re-display in frontend
          await doc.ref.update({ announced: true });

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

        const token = {
          name: data.name || "Buckazoids",
          ticker: data.ticker || "BUCKAZOIDS",
          address:
            data.address || "BQQzEvYT4knThhkSPBvSKBLg1LEczisWLhx5ydJipump",
          decimals: typeof data.decimals === "number" ? data.decimals : 6,
        };

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

          await doc.ref.update({
            announced: true,
            hasSent: true,
          });

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
