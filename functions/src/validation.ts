import { ReplyError } from "./errors";

import { LANGUAGES, Language, MODES, Mode, ReplyPrefs, TWEAKS, Tweak } from "./prompt";

export const MAX_CONTEXT_LENGTH = 5000;
export const MAX_REPLIES = 3;
export const MAX_NOTES_LENGTH = 1000;
export const MAX_STYLE_LENGTH = 300;
export const MAX_PREVIOUS_LENGTH = 600;

export interface GenerateReplyInput {
  mode: Mode;
  context: string;
  tone: number;
  language: Language;
  deviceId: string;
  /** How many options to write (1..MAX_REPLIES); more than one spreads them Chill → Bold. */
  count: number;
  /** Also return a one-line "why this works" tip per reply. */
  tips: boolean;
  /** The user's saved notes about this match (optional). */
  notes?: string;
  /** Set internally per option in DATE_IDEAS mode; never read from the request. */
  angle?: string;
  /** The user's standing preferences (emoji, length, own style). */
  prefs?: ReplyPrefs;
  /** Rework [previous] instead of writing from scratch (always one reply). */
  tweak?: Tweak;
  previous?: string;
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
    throw new ReplyError("invalid-argument", `Pick a mode: ${MODES.join(", ")}.`);
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

  const rawCount = body.count;
  const count =
    typeof rawCount === "number" && Number.isInteger(rawCount) ? Math.min(MAX_REPLIES, Math.max(1, rawCount)) : 1;

  const tips = body.tips === true;

  const notes = typeof body.notes === "string" ? body.notes.trim() : "";
  if (notes.length > MAX_NOTES_LENGTH) {
    throw new ReplyError("invalid-argument", `Match notes are too long (max ${MAX_NOTES_LENGTH} characters).`);
  }

  const prefs = parsePrefs(body.prefs);

  let tweak: Tweak | undefined;
  let previous: string | undefined;
  if (body.tweak !== undefined) {
    if (typeof body.tweak !== "string" || !(body.tweak in TWEAKS)) {
      throw new ReplyError("invalid-argument", `Unknown tweak. Use one of: ${Object.keys(TWEAKS).join(", ")}.`);
    }
    previous = typeof body.previous === "string" ? body.previous.trim() : "";
    if (!previous || previous.length > MAX_PREVIOUS_LENGTH) {
      throw new ReplyError("invalid-argument", "Send the reply to rework (max 600 characters).");
    }
    tweak = body.tweak as Tweak;
  }

  return {
    mode: mode as Mode,
    context,
    tone,
    language,
    deviceId,
    count: tweak ? 1 : count,
    tips,
    ...(notes ? { notes } : {}),
    ...(prefs ? { prefs } : {}),
    ...(tweak ? { tweak, previous } : {}),
  };
}

function parsePrefs(raw: unknown): ReplyPrefs | undefined {
  if (typeof raw !== "object" || raw === null) return undefined;
  const body = raw as Record<string, unknown>;
  const style = typeof body.style === "string" ? body.style.trim() : "";
  if (style.length > MAX_STYLE_LENGTH) {
    throw new ReplyError("invalid-argument", `Your style notes are too long (max ${MAX_STYLE_LENGTH} characters).`);
  }
  const prefs: ReplyPrefs = {
    ...(typeof body.emoji === "boolean" ? { emoji: body.emoji } : {}),
    ...(body.short === true ? { short: true } : {}),
    ...(style ? { style } : {}),
  };
  return Object.keys(prefs).length > 0 ? prefs : undefined;
}
