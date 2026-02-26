import * as functions from "firebase-functions";
import {logger} from "firebase-functions";
import {Request, Response} from "express";
import {WebhookPayload} from "./types";
import {parseCommand, handleCommand} from "./commands";
import {sendTextMessage} from "./sender";

/**
 * WhatsApp Cloud API webhook handler.
 * - GET: Webhook verification (subscription challenge).
 * - POST: Incoming messages from WhatsApp users.
 */
export const whatsappWebhook = functions.https.onRequest(
  async (req: Request, res: Response) => {
    if (req.method === "GET") {
      return handleVerification(req, res);
    }

    if (req.method === "POST") {
      return handleIncomingMessage(req, res);
    }

    res.status(405).send("Method Not Allowed");
  }
);

/**
 * GET — Webhook verification.
 * Meta sends a challenge to verify the webhook URL.
 */
function handleVerification(req: Request, res: Response): void {
  const mode = req.query["hub.mode"] as string;
  const token = req.query["hub.verify_token"] as string;
  const challenge = req.query["hub.challenge"] as string;

  const verifyToken = process.env.VERIFY_TOKEN;

  if (mode === "subscribe" && token === verifyToken) {
    logger.info("Webhook verified successfully");
    res.status(200).send(challenge);
  } else {
    logger.warn("Webhook verification failed");
    res.status(403).send("Forbidden");
  }
}

/**
 * POST — Handle incoming WhatsApp messages.
 * Parses the webhook payload, extracts text messages,
 * routes to command handlers, and sends replies.
 */
async function handleIncomingMessage(
  req: Request,
  res: Response
): Promise<void> {
  // Respond immediately to avoid webhook timeout
  res.status(200).send("EVENT_RECEIVED");

  try {
    const payload = req.body as WebhookPayload;

    if (payload.object !== "whatsapp_business_account") {
      return;
    }

    for (const entry of payload.entry) {
      for (const change of entry.changes) {
        const value = change.value;
        if (!value.messages) continue;

        for (const message of value.messages) {
          if (message.type !== "text" || !message.text) continue;

          const senderPhone = message.from;
          const senderName = value.contacts?.[0]?.profile?.name || "Unknown";
          const text = message.text.body;

          logger.info(
            `Message from ${senderName} (${senderPhone}): ${text}`
          );

          const cmd = parseCommand(text, senderPhone, senderName);
          const response = await handleCommand(cmd);

          await sendTextMessage(senderPhone, response);
        }
      }
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Error processing webhook: ${message}`);
  }
}
