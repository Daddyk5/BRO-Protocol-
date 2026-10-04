import type { Language, Mode } from "./modes";

export interface GeneratePayload {
  mode: Mode;
  context: string;
  tone: number;
  language: Language;
}

/** Popup / content script → background service worker. */
export type BackgroundRequest = { type: "generate"; payload: GeneratePayload };

export type GenerateResponse = { ok: true; reply: string } | { ok: false; error: string };

export async function requestReply(payload: GeneratePayload): Promise<GenerateResponse> {
  try {
    const response = (await chrome.runtime.sendMessage<BackgroundRequest, GenerateResponse>({
      type: "generate",
      payload,
    })) as GenerateResponse | undefined;
    return response ?? { ok: false, error: "No answer from the extension. Reload the page and try again." };
  } catch {
    return { ok: false, error: "The extension was updated. Reload the page and try again." };
  }
}
