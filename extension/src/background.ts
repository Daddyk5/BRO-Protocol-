import { generateReply } from "./shared/api";
import type { BackgroundRequest, GenerateResponse } from "./shared/messages";
import { MAX_CONTEXT_LENGTH } from "./shared/modes";
import { setPendingSelection } from "./shared/storage";

const MENU_ID = "bro-protocol-reply";

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: MENU_ID,
    title: "Bro Protocol: reply to this",
    contexts: ["selection"],
  });
  void chrome.action.setBadgeBackgroundColor({ color: "#E63946" });
});

chrome.contextMenus.onClicked.addListener((info) => {
  if (info.menuItemId !== MENU_ID || !info.selectionText) return;
  const text = info.selectionText.trim().slice(0, MAX_CONTEXT_LENGTH);
  void (async () => {
    await setPendingSelection({ text, mode: "BANTER" });
    try {
      // The popup picks up the selection and generates immediately.
      await chrome.action.openPopup();
    } catch {
      // openPopup can be refused (e.g. no focused window); flag the icon instead.
      await chrome.action.setBadgeText({ text: "1" });
    }
  })();
});

chrome.runtime.onMessage.addListener((message: BackgroundRequest, _sender, sendResponse) => {
  if (message?.type !== "generate") return false;

  generateReply(message.payload)
    .then((reply): GenerateResponse => ({ ok: true, reply }))
    .catch((error: unknown): GenerateResponse => ({
      ok: false,
      error: error instanceof Error ? error.message : "Something went sideways. Try again.",
    }))
    .then(sendResponse);

  return true; // Keep the channel open for the async response.
});
