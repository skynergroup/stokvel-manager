import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {sendTextMessage} from "../whatsapp/sender";

const db = admin.firestore();

/**
 * Scheduled function: runs daily at 9:00 AM SAST (7:00 UTC).
 * Checks for contributions due in 3 days and sends WhatsApp reminders
 * to members who haven't paid yet.
 */
export const dailyContributionReminder = functions.pubsub
  .schedule("0 7 * * *")
  .timeZone("Africa/Johannesburg")
  .onRun(async () => {
    try {
      const now = new Date();
      const threeDaysFromNow = new Date(now);
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

      // Start and end of the target day
      const targetStart = new Date(
        threeDaysFromNow.getFullYear(),
        threeDaysFromNow.getMonth(),
        threeDaysFromNow.getDate()
      );
      const targetEnd = new Date(targetStart);
      targetEnd.setDate(targetEnd.getDate() + 1);

      // Get all stokvels
      const stokvelsSnap = await db.collection("stokvels").get();

      let totalReminders = 0;

      for (const stokvelDoc of stokvelsSnap.docs) {
        const stokvelData = stokvelDoc.data();
        const stokvelId = stokvelDoc.id;
        const amount = stokvelData.contributionAmount || 0;

        // Find pending contributions due in 3 days
        const pendingSnap = await db
          .collection("stokvels")
          .doc(stokvelId)
          .collection("contributions")
          .where("status", "==", "pending")
          .where("dueDate", ">=", targetStart)
          .where("dueDate", "<", targetEnd)
          .get();

        if (pendingSnap.empty) continue;

        // Get member phone numbers for unpaid members
        for (const contribDoc of pendingSnap.docs) {
          const contrib = contribDoc.data();
          const memberId = contrib.memberId;

          const memberDoc = await db
            .collection("stokvels")
            .doc(stokvelId)
            .collection("members")
            .doc(memberId)
            .get();

          if (!memberDoc.exists) continue;
          const memberData = memberDoc.data();
          if (!memberData?.phone) continue;

          const dueDateStr = threeDaysFromNow.toLocaleDateString("en-ZA", {
            weekday: "long",
            day: "numeric",
            month: "long",
          });

          const message =
            `🔔 *Reminder — ${stokvelData.name}*\n\n` +
            `Your R${amount.toLocaleString()} contribution is due on ${dueDateStr}.\n` +
            `Please pay and send proof to your treasurer.`;

          try {
            await sendTextMessage(memberData.phone, message);
            totalReminders++;
          } catch {
            logger.warn(
              `Failed to send reminder to ${memberData.phone}`
            );
          }
        }
      }

      logger.info(`Daily reminder complete: ${totalReminders} reminders sent`);
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : String(error);
      logger.error(`Error in daily reminder: ${msg}`);
    }
  });
