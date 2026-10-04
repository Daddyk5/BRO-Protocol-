import type { Language, Mode } from "./modes";

export interface Settings {
  tone: number;
  language: Language;
}

const DEFAULT_SETTINGS: Settings = { tone: 0.5, language: "english" };

export async function getSettings(): Promise<Settings> {
  const stored = await chrome.storage.local.get(["tone", "language"]);
  return {
    tone: typeof stored.tone === "number" ? stored.tone : DEFAULT_SETTINGS.tone,
    language: stored.language === "taglish" ? "taglish" : DEFAULT_SETTINGS.language,
  };
}

export async function saveSettings(settings: Partial<Settings>): Promise<void> {
  await chrome.storage.local.set(settings);
}

/** Random per-install ID for the backend's rate limit. */
export async function getDeviceId(): Promise<string> {
  const stored = await chrome.storage.local.get("deviceId");
  if (typeof stored.deviceId === "string" && stored.deviceId) return stored.deviceId;
  const deviceId = `ext-${crypto.randomUUID()}`;
  await chrome.storage.local.set({ deviceId });
  return deviceId;
}

/** Text highlighted on a page via the context menu, waiting for the popup. */
export interface PendingSelection {
  text: string;
  mode: Mode;
}

export async function setPendingSelection(pending: PendingSelection): Promise<void> {
  await chrome.storage.session.set({ pendingSelection: pending });
}

export async function takePendingSelection(): Promise<PendingSelection | null> {
  const stored = await chrome.storage.session.get("pendingSelection");
  await chrome.storage.session.remove("pendingSelection");
  const pending = stored.pendingSelection as PendingSelection | undefined;
  return pending && typeof pending.text === "string" ? pending : null;
}
