import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

// Return the server timestamp
export const getServerTime = onRequest(async (req, res) => {
  res.json({ now: Date.now() });
});




// Initialize Firebase Admin SDK once
initializeApp();

export const dailyRewardNotification = onSchedule(
  {
    schedule: '10 11 * * *',
    timeZone: 'America/New_York',
  },
  async () => {
    const message = {
      topic: 'daily_reward',
      notification: {
        title: 'Daily Reward',
        body: '🎁 Your daily reward is ready! Open the app to claim it.'
      },
      apns: {
        headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
        payload: { aps: { sound: 'default', badge: 1 } }
      },
      android: { priority: 'high' }
    };

    try {
      const res = await getMessaging().send(message);
      console.log(`✅ Sent daily reward: ${res}`);
    } catch (err) {
      console.error('❌ Failed to send daily reward:', err);
    }
  }
);

export const giveawayNotification = onDocumentCreated(
  { document: 'giveaways/{giveawayId}' },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { amount, keyword, endTimestamp } = data;
    const timeLeft = Math.floor((endTimestamp - Date.now()) / 1000);

    const message = {
      topic: 'global_users',
      notification: {
        title: '🎉 New Giveaway!',
        body: `Type "${keyword}" to win ${amount} $BUCKAZOIDS! Ends in ${timeLeft}s`,
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
    };

    try {
      const res = await getMessaging().send(message);
      console.log(`✅ Giveaway notification sent: ${res}`);
    } catch (err) {
      console.error('❌ Giveaway notification error:', err);
    }
  }
);

export const pickGiveawayWinner = onSchedule(
  { schedule: '* * * * *', timeZone: 'America/New_York' },
  async () => {
    const db = getFirestore();
    const now = Date.now();

    try {
      const snapshot = await db
        .collection('giveaways')
        .where('status', '==', 'started')
        .where('endTimestamp', '<=', now)
        .get();

      if (snapshot.empty) {
        console.log('🟡 No giveaways to close');
        return;
      }

      for (const doc of snapshot.docs) {
        try {
          const data = doc.data();
          const participants = Array.isArray(data.participants) ? data.participants : [];
          const amount = typeof data.amount === 'number' ? data.amount : 0;
          const host = data.host || 'system';
          const winner = participants.length
            ? participants[Math.floor(Math.random() * participants.length)]
            : null;

          await doc.ref.update({
            status: 'ended',
            winner: winner ?? 'No winner',
            hasSent: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          if (winner) {
            await db.collection('chat').add({
              message: `/send ${amount} ${winner}`,
              sender: host,
              tier: 'adventurer',
              room: 'General',
              timestamp: Date.now(),
            });
            console.log(`💸 Injected /send ${amount} to ${winner}`);
          }

          console.log(`✅ Giveaway ended: ${doc.id}, winner: ${winner ?? 'none'}`);

          const message = {
            topic: 'global_users',
            notification: {
              title: '🏁 Giveaway Ended!',
              body: winner
                ? `${winner} won ${amount} $BUCKAZOIDS!`
                : 'No one entered this giveaway.',
            },
            android: { priority: 'high' },
            apns: {
              headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
              payload: { aps: { sound: 'default' } },
            },
          };

          await getMessaging().send(message);
          console.log(`✅ Sent winner notification for ${doc.id}`);
        } catch (innerErr) {
          console.error(`❌ Failed to process giveaway ${doc.id}:`, innerErr);
        }
      }
    } catch (outerErr) {
      console.error('🔥 Error running pickGiveawayWinner:', outerErr);
    }
  }
);


export const runGiveawayWinnerNow = onRequest(async (req, res) => {
  const db = getFirestore();
  const now = Date.now();

  try {
    const snapshot = await db
      .collection('giveaways') // change to 'giveaways_test' if needed
      .where('status', '==', 'started')
      .where('endTimestamp', '<=', now)
      .get();

    if (snapshot.empty) {
      console.log('🟡 No giveaways to close');
      return res.status(200).send('No active giveaways to end.');
    }

    for (const doc of snapshot.docs) {
      try {
        const data = doc.data();
        const participants = Array.isArray(data.participants) ? data.participants : [];
        const amount = typeof data.amount === 'number' ? data.amount : 0;
        const winner = participants.length
          ? participants[Math.floor(Math.random() * participants.length)]
          : null;

        try {
  await doc.ref.update({
    status: 'ended',
    winner: winner ?? 'No winner',
    hasSent: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (winner) {
  await db.collection('chat').add({
    message: `/send ${amount} ${winner}`,
    sender: host,
    tier: 'adventurer',
    room: 'General',
    timestamp: Date.now(),
  });
  console.log(`💸 Injected /send ${amount} to ${winner}`);
}

  console.log(`✅ Giveaway ended: ${doc.id}, winner: ${winner ?? 'none'}`);
} catch (err) {
  console.error(`❌ Failed to end giveaway ${doc.id}`, data, err);
}


        const message = {
          topic: 'global_users',
          notification: {
            title: '🏁 Giveaway Ended!',
            body: winner
              ? `${winner} won ${amount} $BUCKAZOIDS!`
              : 'No one entered this giveaway.',
          },
          android: { priority: 'high' },
          apns: {
            headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } },
          },
        };

        await getMessaging().send(message);
        console.log(`✅ Sent winner notification for ${doc.id}`);
      } catch (err) {
        console.error(`❌ Failed to process giveaway ${doc.id}`, err);
      }
    }

    res.status(200).send('Giveaway logic executed.');
  } catch (err) {
    console.error('🔥 Manual trigger failed', err);
    res.status(500).send('Internal error');
  }
});