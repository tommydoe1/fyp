const { onDocumentWritten, pubsub } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const moment = require("moment");

admin.initializeApp();

// ============================
// Caffeine Notification Function
// ============================
exports.scheduledCaffeineCheck = pubsub.schedule('every 5 minutes').onRun(async () => {
  logger.log('Checking caffeine events for notifications.');

  const snapshot = await admin.firestore().collection('caffeine').get();

  snapshot.forEach(async (doc) => {
    const caffeineDoc = doc.data();
    const userId = doc.id;

    if (!caffeineDoc || !caffeineDoc.cafEnd) {
      logger.log(`No cafEnd field found for user ${userId}`);
      return;
    }

    const cafEndTimestamp = caffeineDoc.cafEnd.toDate();
    const currentTime = moment();
    const targetTime = moment(cafEndTimestamp);

    if (targetTime.isBefore(currentTime)) {
      logger.log(`cafEnd time is in the past for user ${userId}, skipping notification.`);
      return;
    }

    if (caffeineDoc.notified) {
      logger.log(`Notification already sent for user ${userId}`);
      return;
    }

    const diffMinutes = targetTime.diff(currentTime, 'minutes');

    if (diffMinutes > 0 && diffMinutes <= 15) {
      const message = `Your caffeine crash will begin in ${diffMinutes} minutes!`;
      await sendNotification(userId, message);

      await admin.firestore().collection('caffeine').doc(userId).update({
        notified: true,
      });

      logger.log(`Notification sent to user: ${userId}`);
    } else {
      logger.log(`No notification sent for user ${userId} (diff: ${diffMinutes} minutes)`);
    }
  });
});

// ============================
// Hydration Notification Function
// ============================
exports.scheduledHydrationCheck = pubsub.schedule('every 15 minutes').onRun(async () => {
  logger.log('Checking hydration levels for reminders.');

  const usersSnapshot = await admin.firestore().collection('users').get();

  usersSnapshot.forEach(async (doc) => {
    const user = doc.data();
    const userId = doc.id;

    if (!user || !user.bedtime) {
      logger.log(`No bedtime set for user ${userId}, skipping hydration check.`);
      return;
    }

    const hydrationDoc = await admin.firestore().collection('hydration').doc(userId).get();
    const hydrationData = hydrationDoc.data();

    if (!hydrationData || !hydrationData.dailyGoal || !hydrationData.currentIntake) {
      logger.log(`Missing hydration data for user ${userId}`);
      return;
    }

    const bedtime = moment(user.bedtime, "hh:mm A");
    const twelveHoursBeforeBedtime = bedtime.clone().subtract(12, 'hours');
    const currentTime = moment();

    // If it's within the 12-hour window before bedtime, check hydration levels
    if (currentTime.isAfter(twelveHoursBeforeBedtime)) {
      const dailyGoal = hydrationData.dailyGoal;
      const currentIntake = hydrationData.currentIntake;

      if (currentIntake < dailyGoal / 2 && !hydrationData.notified) {
        const message = "You're below 50% of your daily hydration goal! Time to drink some water. 💧";
        await sendNotification(userId, message);

        // Mark as notified to avoid duplicate messages
        await admin.firestore().collection('hydration').doc(userId).update({
          notified: true,
        });

        logger.log(`Hydration reminder sent to user: ${userId}`);
      } else {
        logger.log(`User ${userId} is above 50% of hydration goal or already notified.`);
      }
    } else {
      logger.log(`Skipping hydration check for user ${userId}, not within 12-hour window.`);
    }
  });
});

// ============================
// Reset Notification Flags on Update
// ============================
exports.resetHydrationNotifiedFlag = onDocumentWritten('hydration/{userId}', async (event) => {
  const userId = event.params.userId;
  const hydrationDoc = event.data.data();

  if (hydrationDoc && hydrationDoc.currentIntake !== undefined) {
    await admin.firestore().collection('hydration').doc(userId).update({
      notified: false,
    });

    logger.log(`Reset 'notified' flag for user ${userId} as hydration intake was updated.`);
  }
});

exports.resetCaffeineNotifiedFlag = onDocumentWritten('caffeine/{userId}', async (event) => {
  const userId = event.params.userId;
  const caffeineDoc = event.data.data();

  if (caffeineDoc && caffeineDoc.cafEnd) {
    await admin.firestore().collection('caffeine').doc(userId).update({
      notified: false,
    });

    logger.log(`Reset 'notified' flag for user ${userId} as 'cafEnd' was updated.`);
  }
});

// ============================
// Send Notification Function
// ============================
async function sendNotification(userId, message) {
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const user = userDoc.data();

  if (!user || !user.fcmToken) {
    logger.error(`FCM token not found for user: ${userId}`);
    return;
  }

  const payload = {
    notification: {
      title: 'Health Reminder!',
      body: message,
    },
  };

  try {
    await admin.messaging().sendToDevice(user.fcmToken, payload);
    logger.log(`Notification sent to user: ${userId}`);
  } catch (error) {
    logger.error(`Error sending notification to ${userId}:`, error);
  }
}
