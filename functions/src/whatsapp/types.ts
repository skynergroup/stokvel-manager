/** WhatsApp Cloud API webhook payload types */

export interface WebhookPayload {
  object: string;
  entry: WebhookEntry[];
}

export interface WebhookEntry {
  id: string;
  changes: WebhookChange[];
}

export interface WebhookChange {
  value: ChangeValue;
  field: string;
}

export interface ChangeValue {
  messaging_product: string;
  metadata: MessageMetadata;
  contacts?: Contact[];
  messages?: IncomingMessage[];
  statuses?: MessageStatus[];
}

export interface MessageMetadata {
  display_phone_number: string;
  phone_number_id: string;
}

export interface Contact {
  profile: {
    name: string;
  };
  wa_id: string;
}

export interface IncomingMessage {
  from: string;
  id: string;
  timestamp: string;
  type: "text" | "image" | "document" | "audio" | "video" | "location" | "reaction" | "interactive";
  text?: {
    body: string;
  };
}

export interface MessageStatus {
  id: string;
  status: "sent" | "delivered" | "read" | "failed";
  timestamp: string;
  recipient_id: string;
}

export interface SendMessagePayload {
  messaging_product: "whatsapp";
  to: string;
  type: "text" | "template";
  text?: {
    body: string;
  };
  template?: {
    name: string;
    language: {
      code: string;
    };
    components?: TemplateComponent[];
  };
}

export interface TemplateComponent {
  type: "body" | "header" | "button";
  parameters: TemplateParameter[];
}

export interface TemplateParameter {
  type: "text" | "currency" | "date_time";
  text?: string;
}

/** Parsed command from incoming WhatsApp message */
export interface ParsedCommand {
  command: string;
  args: string[];
  rawText: string;
  senderPhone: string;
  senderName: string;
}
