import axios from "axios";
import {logger} from "firebase-functions";
import {SendMessagePayload, TemplateComponent} from "./types";

const GRAPH_API_URL = "https://graph.facebook.com/v19.0";

function getConfig() {
  const token = process.env.WHATSAPP_TOKEN;
  const phoneId = process.env.WHATSAPP_PHONE_ID;
  if (!token || !phoneId) {
    throw new Error("Missing WHATSAPP_TOKEN or WHATSAPP_PHONE_ID env vars");
  }
  return {token, phoneId};
}

/**
 * Send a free-form text message via WhatsApp Cloud API.
 */
export async function sendTextMessage(
  to: string,
  body: string
): Promise<void> {
  const {token, phoneId} = getConfig();

  const payload: SendMessagePayload = {
    messaging_product: "whatsapp",
    to,
    type: "text",
    text: {body},
  };

  try {
    await axios.post(
      `${GRAPH_API_URL}/${phoneId}/messages`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );
    logger.info(`Message sent to ${to}`);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to send message to ${to}: ${message}`);
    throw error;
  }
}

/**
 * Send a pre-approved template message via WhatsApp Cloud API.
 * Used for proactive/outbound notifications (contribution reminders, etc.).
 */
export async function sendTemplateMessage(
  to: string,
  templateName: string,
  languageCode: string = "en",
  components?: TemplateComponent[]
): Promise<void> {
  const {token, phoneId} = getConfig();

  const payload: SendMessagePayload = {
    messaging_product: "whatsapp",
    to,
    type: "template",
    template: {
      name: templateName,
      language: {code: languageCode},
      components,
    },
  };

  try {
    await axios.post(
      `${GRAPH_API_URL}/${phoneId}/messages`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );
    logger.info(`Template '${templateName}' sent to ${to}`);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to send template to ${to}: ${message}`);
    throw error;
  }
}

/**
 * Send a message to multiple recipients (e.g., all group members).
 */
export async function sendGroupNotification(
  phoneNumbers: string[],
  body: string
): Promise<void> {
  const results = await Promise.allSettled(
    phoneNumbers.map((phone) => sendTextMessage(phone, body))
  );

  const failed = results.filter((r) => r.status === "rejected");
  if (failed.length > 0) {
    logger.warn(
      `${failed.length}/${phoneNumbers.length} messages failed to send`
    );
  }
}
