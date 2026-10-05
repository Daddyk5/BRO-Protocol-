export type Mode = "OPENER" | "BANTER" | "MOVE_OFF_APP" | "REVIVE" | "LATE_NIGHT";
export type Language = "english" | "taglish";

export interface ModeInfo {
  id: Mode;
  title: string;
  description: string;
}

export const MODES: readonly ModeInfo[] = [
  { id: "OPENER", title: "Opener", description: "Start the conversation from her profile" },
  { id: "BANTER", title: "Banter", description: "Reply to her last message" },
  { id: "MOVE_OFF_APP", title: "Move it off-app", description: "Get the number or set the date" },
  { id: "REVIVE", title: "Revive", description: "Restart a chat that went quiet" },
  { id: "LATE_NIGHT", title: "Late night", description: "Smooth, slow-burn flirting" },
];

/** Same thresholds as the app and the backend. */
export function toneLabel(tone: number): string {
  if (tone < 0.34) return "Chill";
  if (tone < 0.67) return "Balanced";
  return "Bold";
}

export const MAX_CONTEXT_LENGTH = 5000;
