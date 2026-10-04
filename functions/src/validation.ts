import { ReplyError } from "./errors";

import { LANGUAGES, Language, MODES, Mode } from "./prompt";

export const MAX_CONTEXT_LENGTH = 5000;

export interface GenerateReplyInput {
  mode: Mode;
  context: string;
  tone: number;
  language: Language;
  deviceId: string;
}

const DEVICE_ID = /^[A-Za-z0-9_-]{8,128}$/;

/** Validates the callable payload; throws `invalid-argument` with a user-facing message. */
export function parseInput(data: unknown): GenerateReplyInput {
  if (typeof data !== "object" || data === null) {
    throw new ReplyError("invalid-argument", "Missing request body.");
  }
  const body = data as Record<string, unknown>;

  const mode = body.mode;
  if (typeof mode !== "string" || !(MODES as readonly string[]).includes(mode)) {
    throw new ReplyError("invalid-argument", "Pick a mode: OPENER, BANTER, MOVE_OFF_APP or REVIVE.");
  }

  const context = typeof body.context === "string" ? body.context.trim() : "";
  if (!context) {
    throw new ReplyError("invalid-argument", "Paste her bio or the chat first.");
  }
  if (context.length > MAX_CONTEXT_LENGTH) {
    throw new ReplyError(
      "invalid-argument",
      `That's a lot of chat. Trim it to the last few messages (max ${MAX_CONTEXT_LENGTH} characters).`,
    );
  }

  const rawTone = body.tone;
  const tone = typeof rawTone === "number" && Number.isFinite(rawTone) ? Math.min(1, Math.max(0, rawTone)) : 0.5;

  const language =
    typeof body.language === "string" && (LANGUAGES as readonly string[]).includes(body.language)
      ? (body.language as Language)
      : "english";

  const deviceId = body.deviceId;
  if (typeof deviceId !== "string" || !DEVICE_ID.test(deviceId)) {
    throw new ReplyError("invalid-argument", "Missing device ID. Update the app and try again.");
  }

  return { mode: mode as Mode, context, tone, language, deviceId };
}
