import {
  CalendarCheck,
  Coffee,
  MessageCircle,
  Moon,
  RotateCcw,
  WandSparkles,
  Zap,
  type LucideIcon,
} from "lucide-react";

export type ModeId =
  | "BANTER"
  | "MOVE_OFF_APP"
  | "REVIVE"
  | "IMPROVE_DRAFT"
  | "DATE_IDEAS"
  | "LATE_NIGHT"
  | "OPENER";

export interface ModeInfo {
  id: ModeId;
  title: string;
  subtitle: string;
  accent: string;
  icon: LucideIcon;
  /** Placeholder for the composer's text box. */
  inputHint: string;
}

/** The six plays on Home, in order (keys 1–6 open them). */
export const HOME_MODES: readonly ModeInfo[] = [
  {
    id: "BANTER",
    title: "Banter",
    subtitle: "Quick, witty replies",
    accent: "#E8336D",
    icon: MessageCircle,
    inputHint: "Paste her last message (or the chat)…",
  },
  {
    id: "MOVE_OFF_APP",
    title: "Move it off-app",
    subtitle: "Get the number or set the date",
    accent: "#3B5BFD",
    icon: Coffee,
    inputHint: "Paste the chat so far…",
  },
  {
    id: "REVIVE",
    title: "Revive",
    subtitle: "Restart a chat that went quiet",
    accent: "#F59E0B",
    icon: RotateCcw,
    inputHint: "Paste the last few messages…",
  },
  {
    id: "IMPROVE_DRAFT",
    title: "Fix my draft",
    subtitle: "Same message, sharper",
    accent: "#10B981",
    icon: WandSparkles,
    inputHint: "Paste your draft (her message above it is fine)…",
  },
  {
    id: "DATE_IDEAS",
    title: "Date ideas",
    subtitle: "Turn the chat into a real plan",
    accent: "#06B6D4",
    icon: CalendarCheck,
    inputHint: "Paste the chat so far…",
  },
  {
    id: "LATE_NIGHT",
    title: "Late night",
    subtitle: "Smooth, slow-burn flirting",
    accent: "#8B5CF6",
    icon: Moon,
    inputHint: "Paste the chat so far…",
  },
];

/** Not on the Home grid, but still available in the composer. */
export const OPENER: ModeInfo = {
  id: "OPENER",
  title: "Opener",
  subtitle: "Start from her profile",
  accent: "#EC4899",
  icon: Zap,
  inputHint: "Paste her bio or interests…",
};

export const ALL_MODES: readonly ModeInfo[] = [...HOME_MODES, OPENER];

export function modeById(id: string | null | undefined): ModeInfo {
  return ALL_MODES.find((m) => m.id === id) ?? HOME_MODES[0];
}
