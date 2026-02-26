import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {sendGroupNotification} from "../whatsapp/sender";

const db = admin.firestore();

/**
 * Firestore trigger: on contribution create/update.
 * Sends WhatsApp notification to group members when a contribution is recorded.
 * Example: "✅ Thabo paid R500. 9/12 members have now paid for February."
 */
export const onContributionWrite = functions.firestore
  .document("stokvels/{stokvelId}/contributions/{contributionId}")
  .onWrite(async (change, context) => {
    const {stokvelId} = context.params;
    const after = change.after.data();
    if (!after) return; // Deleted — ignore

    // Only notify on paid status
    if (after.status !== "paid") return;

    // Avoid re-notifying on updates that don't change status
    const before = change.before.data();
    if (before?.status === "paid") return;

    try {
      // Get stokvel info
      const stokvelDoc = await db.collection("stokvels").doc(stokvelId).get();
      const stokvelData = stokvelDoc.data();
      if (!stokvelData) return;

      const memberCount = stokvelData.memberCount || 0;
      const memberName = after.memberName || "A member";
      const amount = after.amount || 0;

      // Count paid contributions for current month
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const paidSnap = await db
        .collection("stokvels")
        .doc(stokvelId)
        .collection("contributions")
        .where("status", "==", "paid")
        .where("paidDate", ">=", startOfMonth)
        .get();

      const paidCount = paidSnap.size;
      const monthName = now.toLocaleString("en-ZA", {month: "long"});

      const message =
        `✅ ${memberName} paid R${amount.toLocaleString()}. ` +
        `${paidCount}/${memberCount} members have now paid for ${monthName}.`;

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
        `Contribution notification sent for ${stokvelData.name}: ${message}`
      );
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : String(error);
      logger.error(`Error in contribution trigger: ${msg}`);
    }
  });
