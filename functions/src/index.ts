import * as admin from "firebase-admin";

admin.initializeApp();

// WhatsApp webhook
export {whatsappWebhook} from "./whatsapp/webhook";

// Firestore triggers
export {onContributionWrite} from "./triggers/contribution";
export {onMeetingCreate} from "./triggers/meeting";

// Scheduled functions
export {dailyContributionReminder} from "./triggers/reminder";
