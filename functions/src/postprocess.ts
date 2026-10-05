const BANNED_WORDS = ["rizz", "gyatt", "skibidi", "alpha", "beta", "sigma", "baddie", "vibe"] as const;

// Catches simple inflections too: vibes, vibing, vibey, baddies, rizzed...
const BANNED_PATTERNS = BANNED_WORDS.map(
  (word) => [word, new RegExp(`\\b${word.replace(/e$/, "")}(?:e|es|ed|ing|ey|s|z|zed|zing|ies)?\\b`, "i")] as const,
);

/** Returns the banned words present in [text] (empty when clean). */
export function findBannedWords(text: string): string[] {
  return BANNED_PATTERNS.filter(([, pattern]) => pattern.test(text)).map(([word]) => word);
}

const QUOTES = /["“”„‟«»]/g;
// Single quotes only when they wrap the whole reply, so apostrophes survive.
const WRAPPING_SINGLE = /^['‘’‚‛](.*)['‘’‚‛]$/s;

/**
 * Splits a completion written with the tip instruction into the message and
 * the "WHY:" tip. Without a WHY line the whole text is the message.
 */
export function splitTip(raw: string): { message: string; tip?: string } {
  const match = raw.match(/^([\s\S]*?)\n\s*\**WHY\**\s*:\s*([\s\S]*)$/i);
  if (!match) return { message: raw };
  const tip = limitSentences(match[2].replace(QUOTES, "").replace(/\s+/g, " ").trim(), 1).slice(0, 240);
  return { message: match[1], ...(tip ? { tip } : {}) };
}

// Pictographs plus skin-tone modifiers, variation selectors and ZWJ joiners.
const EMOJI = /[\p{Extended_Pictographic}\p{Emoji_Modifier}\uFE0F\u200D]+/gu;

export interface PostProcessOptions {
  /** Keep 1 sentence instead of 2. */
  short?: boolean;
  /** false strips every emoji. */
  emoji?: boolean;
}

/** Strips quotation marks, collapses whitespace and keeps at most 2 sentences (1 when short). */
export function postProcess(raw: string, { short = false, emoji = true }: PostProcessOptions = {}): string {
  let text = raw.trim();
  text = text.replace(/^(reply|message|you)\s*:\s*/i, "");
  text = text.replace(QUOTES, "");
  const wrapped = text.match(WRAPPING_SINGLE);
  if (wrapped) text = wrapped[1];
  if (!emoji) text = text.replace(EMOJI, "");
  // Collapse whitespace, and drop the gap a removed emoji leaves before punctuation.
  text = text.replace(/\s+/g, " ").replace(/ ([.,!?…])/g, "$1").trim();
  return limitSentences(text, short ? 1 : 2);
}

/**
 * Keeps the first [max] sentences. A sentence boundary is . ! ? or …
 * (possibly repeated, possibly followed by a closing bracket or emoji) followed
 * by whitespace and more text, so "3.5" or "a.m." mid-word never splits.
 */
export function limitSentences(text: string, max: number): string {
  const boundary = /[.!?…]+[)\]]*(?:\s*\p{Extended_Pictographic}+)?(?=\s+\S)/gu;
  let count = 0;
  for (const match of text.matchAll(boundary)) {
    count += 1;
    if (count === max) return text.slice(0, (match.index ?? 0) + match[0].length).trim();
  }
  return text;
}
