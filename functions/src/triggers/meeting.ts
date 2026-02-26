import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {sendGroupNotification} from "../whatsapp/sender";

const db = admin.firestore();

/**
 * Firestore trigger: on meeting create.
 * Sends WhatsApp notification to group members when a meeting is scheduled.
 * Example: "📅 Meeting scheduled: Sat 1 March, 10:00 at Mam' Nkosi's house."
 */
export const onMeetingCreate = functions.firestore
  .document("stokvels/{stokvelId}/meetings/{meetingId}")
  .onCreate(async (snap, context) => {
    const {stokvelId} = context.params;
    const meetingData = snap.data();

    try {
      // Get stokvel info
      const stokvelDoc = await db.collection("stokvels").doc(stokvelId).get();
      const stokvelData = stokvelDoc.data();
      if (!stokvelData) return;

      const title = meetingData.title || "Monthly Meeting";
      const date = meetingData.date?.toDate?.()
        ? meetingData.date.toDate().toLocaleDateString("en-ZA", {
          weekday: "short",
          day: "numeric",
          month: "long",
          hour: "2-digit",
          minute: "2-digit",
        })
        : "TBD";

      const location = meetingData.locationName ||
        meetingData.virtualLink ||
        "TBD";

      const message =
        `📅 *Meeting Scheduled — ${stokvelData.name}*\n\n` +
        `${title}\n` +
        `Date: ${date}\n` +
        `Location: ${location}\n\n` +
        `Reply YES or NO to RSVP.`;

      // Get all member phone numbers
      const membersSnap = await db
        .collection("stokvels")
        .doc(stokvelId)
        .collection("members")
        .where("status", "==", "active")
        .get();

      const phones = membersSnap.docs
        .map((doc) => doc.data().phone as string)
        .filter((p) => !!p);

      if (phones.length > 0) {
        await sendGroupNotification(phones, message);
      }

      logger.info(
        `Meeting notification sent for ${stokvelData.name}: ${title}`
      );
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : String(error);
      logger.error(`Error in meeting trigger: ${msg}`);
    }
  });
