import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {ParsedCommand} from "./types";

const db = admin.firestore();

/**
 * Parse an incoming message into a command + args.
 */
export function parseCommand(
  text: string,
  senderPhone: string,
  senderName: string
): ParsedCommand {
  const trimmed = text.trim().toLowerCase();
  const parts = trimmed.split(/\s+/);
  const command = parts[0] || "";
  const args = parts.slice(1);

  return {
    command,
    args,
    rawText: trimmed,
    senderPhone,
    senderName,
  };
}

/**
 * Route a parsed command to its handler. Returns response text.
 */
export async function handleCommand(cmd: ParsedCommand): Promise<string> {
  // Handle multi-word commands
  if (cmd.rawText === "my balance") {
    return handleMyBalance(cmd);
  }
  if (cmd.rawText === "next payout") {
    return handleNextPayout(cmd);
  }
  if (cmd.rawText === "next meeting") {
    return handleNextMeeting(cmd);
  }

  switch (cmd.command) {
  case "balance":
    return handleBalance(cmd);
  case "help":
    return handleHelp();
  case "remind":
    return handleRemind(cmd);
  default:
    return handleHelp();
  }
}

/**
 * Find the stokvel linked to this WhatsApp group/phone.
 */
async function findStokvelByPhone(
  phone: string
): Promise<{stokvelId: string; stokvelName: string} | null> {
  // Look up user by phone number
  const usersSnap = await db
    .collection("users")
    .where("phone", "==", phone)
    .limit(1)
    .get();

  if (usersSnap.empty) return null;

  const userData = usersSnap.docs[0].data();
  const stokvels = userData.stokvels as string[] | undefined;
  if (!stokvels || stokvels.length === 0) return null;

  // Use the first stokvel for now
  const stokvelId = stokvels[0];
  const stokvelDoc = await db.collection("stokvels").doc(stokvelId).get();
  if (!stokvelDoc.exists) return null;

  return {
    stokvelId,
    stokvelName: stokvelDoc.data()?.name || "Unknown",
  };
}

/** balance — Show group balance + who owes */
async function handleBalance(cmd: ParsedCommand): Promise<string> {
  const stokvel = await findStokvelByPhone(cmd.senderPhone);
  if (!stokvel) {
    return "You're not linked to any stokvel group yet. Ask your chairperson to add your number.";
  }

  const stokvelDoc = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .get();
  const data = stokvelDoc.data();
  if (!data) return "Could not load group data.";

  const totalCollected = data.totalCollected || 0;
  const memberCount = data.memberCount || 0;
  const amount = data.contributionAmount || 0;

  // Count paid contributions for current month
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const contribSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("contributions")
    .where("status", "==", "paid")
    .where("paidDate", ">=", startOfMonth)
    .get();

  const paidCount = contribSnap.size;

  return (
    `📊 *${stokvel.stokvelName}*\n` +
    `Balance: R${totalCollected.toLocaleString()}\n` +
    `${paidCount}/${memberCount} paid for ${now.toLocaleString("en-ZA", {month: "long"})}\n` +
    `Contribution: R${amount}/month`
  );
}

/** my balance — Show individual contribution history */
async function handleMyBalance(cmd: ParsedCommand): Promise<string> {
  const stokvel = await findStokvelByPhone(cmd.senderPhone);
  if (!stokvel) {
    return "You're not linked to any stokvel group yet.";
  }

  // Find member by phone
  const membersSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("members")
    .where("phone", "==", cmd.senderPhone)
    .limit(1)
    .get();

  if (membersSnap.empty) {
    return "Could not find your membership record.";
  }

  const memberId = membersSnap.docs[0].id;

  // Get recent contributions
  const contribSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("contributions")
    .where("memberId", "==", memberId)
    .orderBy("createdAt", "desc")
    .limit(6)
    .get();

  if (contribSnap.empty) {
    return `📊 *${stokvel.stokvelName}*\nNo contributions recorded yet.`;
  }

  const lines = contribSnap.docs.map((doc) => {
    const d = doc.data();
    const status = d.status === "paid" ? "✅" : d.status === "late" ? "❌" : "⏳";
    const date = d.paidDate?.toDate?.()
      ? d.paidDate.toDate().toLocaleDateString("en-ZA", {month: "short", year: "numeric"})
      : "Pending";
    return `${status} R${d.amount} — ${date}`;
  });

  return `📊 *Your balance — ${stokvel.stokvelName}*\n${lines.join("\n")}`;
}

/** next payout — Show who's next in rotation */
async function handleNextPayout(cmd: ParsedCommand): Promise<string> {
  const stokvel = await findStokvelByPhone(cmd.senderPhone);
  if (!stokvel) {
    return "You're not linked to any stokvel group yet.";
  }

  const payoutsSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("payouts")
    .where("status", "==", "scheduled")
    .orderBy("payoutDate", "asc")
    .limit(1)
    .get();

  if (payoutsSnap.empty) {
    return `💰 *${stokvel.stokvelName}*\nNo upcoming payouts scheduled.`;
  }

  const payout = payoutsSnap.docs[0].data();
  const date = payout.payoutDate?.toDate?.()
    ? payout.payoutDate.toDate().toLocaleDateString("en-ZA", {
      day: "numeric", month: "long", year: "numeric",
    })
    : "TBD";

  return (
    `💰 *Next Payout — ${stokvel.stokvelName}*\n` +
    `Recipient: ${payout.recipientName}\n` +
    `Amount: R${payout.amount?.toLocaleString() || "0"}\n` +
    `Date: ${date}`
  );
}

/** next meeting — Show next scheduled meeting */
async function handleNextMeeting(cmd: ParsedCommand): Promise<string> {
  const stokvel = await findStokvelByPhone(cmd.senderPhone);
  if (!stokvel) {
    return "You're not linked to any stokvel group yet.";
  }

  const now = new Date();
  const meetingsSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("meetings")
    .where("date", ">=", now)
    .orderBy("date", "asc")
    .limit(1)
    .get();

  if (meetingsSnap.empty) {
    return `📅 *${stokvel.stokvelName}*\nNo upcoming meetings scheduled.`;
  }

  const meeting = meetingsSnap.docs[0].data();
  const date = meeting.date?.toDate?.()
    ? meeting.date.toDate().toLocaleDateString("en-ZA", {
      weekday: "short", day: "numeric", month: "long", hour: "2-digit", minute: "2-digit",
    })
    : "TBD";

  const location = meeting.locationName || meeting.virtualLink || "TBD";

  return (
    `📅 *Next Meeting — ${stokvel.stokvelName}*\n` +
    `${meeting.title || "Monthly Meeting"}\n` +
    `Date: ${date}\n` +
    `Location: ${location}`
  );
}

/** help — List all commands */
function handleHelp(): string {
  return (
    "🤖 *StokvelManager Bot Commands*\n\n" +
    "📊 *balance* — Group balance & who's paid\n" +
    "👤 *my balance* — Your contribution history\n" +
    "💰 *next payout* — Who's next in rotation\n" +
    "📅 *next meeting* — Next scheduled meeting\n" +
    "🔔 *remind* — Send payment reminder (admin)\n" +
    "❓ *help* — Show this message"
  );
}

/** remind — Trigger contribution reminder (chair/treasurer only) */
async function handleRemind(cmd: ParsedCommand): Promise<string> {
  const stokvel = await findStokvelByPhone(cmd.senderPhone);
  if (!stokvel) {
    return "You're not linked to any stokvel group yet.";
  }

  // Check if sender is chairperson or treasurer
  const membersSnap = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .collection("members")
    .where("phone", "==", cmd.senderPhone)
    .limit(1)
    .get();

  if (membersSnap.empty) {
    return "Could not find your membership record.";
  }

  const memberData = membersSnap.docs[0].data();
  const role = memberData.role as string;

  if (role !== "chairperson" && role !== "treasurer") {
    return "⚠️ Only the chairperson or treasurer can send reminders.";
  }

  const stokvelDoc = await db
    .collection("stokvels")
    .doc(stokvel.stokvelId)
    .get();
  const data = stokvelDoc.data();
  if (!data) return "Could not load group data.";

  const amount = data.contributionAmount || 0;

  logger.info(
    `Reminder triggered by ${cmd.senderName} for ${stokvel.stokvelName}`
  );

  return (
    `🔔 *Payment Reminder — ${stokvel.stokvelName}*\n\n` +
    `Your R${amount} contribution is due. ` +
    `Please pay as soon as possible and send proof of payment to the treasurer.`
  );
}
