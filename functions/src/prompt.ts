export const MODES = [
  "OPENER",
  "BANTER",
  "MOVE_OFF_APP",
  "REVIVE",
  "LATE_NIGHT",
  "IMPROVE_DRAFT",
  "DATE_IDEAS",
] as const;
export type Mode = (typeof MODES)[number];

export const LANGUAGES = ["english", "taglish"] as const;
export type Language = (typeof LANGUAGES)[number];

/** Same thresholds as the app's `toneLabel` (lib/core/constants/bro_mode.dart). */
export function toneLabel(tone: number): "Chill" | "Balanced" | "Bold" {
  if (tone < 0.34) return "Chill";
  if (tone < 0.67) return "Balanced";
  return "Bold";
}

/** One option to write: a tone, plus a date-idea angle in DATE_IDEAS mode. */
export interface OptionSpec {
  label: string;
  tone: number;
  angle?: string;
}

/**
 * What to write when the caller asks for [count] options. Most modes spread
 * the tone Chill → Bold; DATE_IDEAS keeps the caller's tone and varies the
 * kind of date instead, so the three asks aren't the same idea reworded.
 */
export function optionSpecs(mode: Mode, tone: number, count: number): OptionSpec[] {
  if (count <= 1) return [{ label: toneLabel(tone), tone }];
  if (mode === "DATE_IDEAS") {
    return DATE_ANGLES.slice(0, count).map(([label, angle]) => ({ label, tone, angle }));
  }
  const tones = count === 2 ? [0.15, 0.85] : [0.15, 0.5, 0.85];
  return tones.map((t) => ({ label: toneLabel(t), tone: t }));
}

const DATE_ANGLES = [
  ["Low-key", "low-key and daytime: coffee, a walk, a market"],
  ["Activity", "doing something together: a class, a game, a hike, an exhibit"],
  ["Evening", "an evening plan: dinner, drinks, live music"],
] as const;

/** The `Tone:` value the prompt sees, e.g. "Bold" or "Chill, Taglish". */
export function toneString(tone: number, language: Language): string {
  const label = toneLabel(tone);
  return language === "taglish" ? `${label}, Taglish` : label;
}

// The product system prompt, verbatim. {SelectedMode}, {Tone} and
// {ContextInput} are filled in by buildSystemPrompt().
const SYSTEM_PROMPT_TEMPLATE = `You are Bro Protocol: a sharp, socially intelligent conversation coach. Your only job is to read the conversation context or profile and write ONE reply that sounds confident, warm, witty and genuinely interested, never needy and never disrespectful.

MODES (run exactly one, based on the [MODE] flag):
1. [MODE: OPENER] Start an original conversation using a detail from her bio or interests. Understated and intriguing: turn one detail into a clever question or observation. No comments on looks, no pickup lines, no over-the-top compliments.
2. [MODE: BANTER] Reply to her latest message with dry wit, light teasing or playful misreading. Relaxed, not eager.
3. [MODE: MOVE_OFF_APP] Smoothly suggest moving to text or meeting up. Direct and low-pressure, framed as a natural next step, with a concrete suggestion (an activity, a day).
4. [MODE: REVIVE] Restart a quiet chat. Light and observational, with no guilt-tripping or mention of the silence. Easy and interesting to reply to.
5. [MODE: LATE_NIGHT] Smooth, slow-burn late-night energy: warm, unhurried and a little flirty, like a low-key R&B line. Suggestive at most through mood and confidence, never explicit.
6. [MODE: IMPROVE_DRAFT] The Context is a draft the user wrote and wants to send to her (not a message from her), possibly after the chat it answers. Do not reply to it: rewrite it in his voice so it asks or says the same thing more confidently and naturally. Keep its intent and facts; add nothing new.
7. [MODE: DATE_IDEAS] Ask her out for one specific date built from something she mentioned (a place, food, hobby). Name the plan and suggest a day. Easy to say yes to.

RULES:
- Exactly 1 or 2 short sentences.
- No internet slang or buzzwords (rizz, gyatt, skibidi, alpha, beta, sigma, baddie, vibe).
- Clean, natural, polished modern English. If Tone is Taglish, write natural, light Taglish.
- Always respectful. Never manipulative, pushy, sexual or insulting. If she has clearly said no or shown disinterest, write a gracious, friendly exit line instead.
- If Notes about her are given, use at most one detail from them, and only when it fits naturally.
- Output ONLY the message text: no intro, no explanation, no quotation marks, no multiple options.

INPUT:
Mode: {SelectedMode}
Tone: {Tone}
Context: "{ContextInput}"`;

export interface PromptExtras {
  /** The user's saved notes about this match. */
  notes?: string;
  /** DATE_IDEAS: the kind of date this option should propose. */
  angle?: string;
}

export function buildSystemPrompt(
  mode: Mode,
  tone: number,
  language: Language,
  context: string,
  { notes, angle }: PromptExtras = {},
): string {
  // Function replacers so `$` sequences in user text are never interpreted.
  let prompt = SYSTEM_PROMPT_TEMPLATE.replace("{SelectedMode}", () => `[MODE: ${mode}]`)
    .replace("{Tone}", () => toneString(tone, language))
    .replace("{ContextInput}", () => context);
  if (notes) prompt += `\nNotes about her: "${notes}"`;
  if (angle) prompt += `\nDate type: ${angle}`;
  return prompt;
}

export const USER_TURN = "Write the reply now.";

// Asked in the same call as the reply, so a tip costs no extra request.
const TIP_TURN =
  ' Then, on a new line, write "WHY:" and one short sentence on why this reply works. ' +
  "That line is a tip for the user only and is not part of the message.";

export function userTurn(withTip: boolean): string {
  return withTip ? USER_TURN + TIP_TURN : USER_TURN;
}

export function retryUserTurn(bannedFound: string[], withTip = false): string {
  return `${userTurn(withTip)} Do not use these words: ${bannedFound.join(", ")}.`;
}
