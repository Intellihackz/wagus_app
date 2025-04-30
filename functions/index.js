import { onSchedule } from 'firebase-functions/v2/scheduler';
import { initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

// Initialize Firebase Admin SDK (uses default service account credentials)
initializeApp();

// Schedule the function to run at 10:40 AM Eastern Time every day
export const dailyRewardNotification = onSchedule(
  {
    schedule: '10 11 * * *',            // Cron: 11:10 AM every day
    timeZone: 'America/New_York',      // Time zone for EST/EDT&#8203;:contentReference[oaicite:7]{index=7}
    // region: 'us-central1',          // (Optional) Specify region for the function
    // memory: '128MiB', timeoutSeconds: 30  (Optional tuning)
  },
  async (event) => {
    // Define the message payload for FCM
    const message = {
      topic: 'daily_reward',  // Target the 'daily_reward' topic
      notification: {
        title: 'Daily Reward',
        body: '🎁 Your daily reward is ready! Open the app to claim it.'
      },
      // Optionally, add platform-specific overrides:
      apns: {  // APNs-specific options for iOS
        headers: {
          'apns-push-type': 'alert',    // Ensure it's an alert notification
          'apns-priority': '10'         // Send as immediate high-priority
        },
        payload: {
          aps: {
            sound: 'default',           // Play default sound
            badge: 1                    // Increment app badge count
            // (Avoid content-available here, since we want a visible notification)
          }
        }
      },
      android: {  // Android-specific options
        priority: 'high'
        // (By default, FCM will display the notification on Android using the notification payload)
      }
    };

    try {
      // Send the message via FCM to all devices subscribed to 'daily_reward'
      const response = await getMessaging().send(message);
      console.log(`Successfully sent daily reward notification: ${response}`);
    } catch (error) {
      console.error('Error sending daily reward notification:', error);
    }
  }
);
