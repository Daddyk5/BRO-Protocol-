import "./popup.css";

import { createFistBumpLoader } from "../shared/loader";
import { logoSvg } from "../shared/logo";
import { requestReply } from "../shared/messages";
import { MODES, type Language, type Mode, toneLabel } from "../shared/modes";
import { getSettings, saveSettings, takePendingSelection } from "../shared/storage";

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

const modesEl = $<HTMLElement>("modes");
const contextEl = $<HTMLTextAreaElement>("context");
const toneEl = $<HTMLInputElement>("tone");
const toneLabelEl = $<HTMLElement>("tone-label");
const languageEl = $<HTMLSelectElement>("language");
const generateEl = $<HTMLButtonElement>("generate");
const resultEl = $<HTMLElement>("result");

let mode: Mode = "BANTER";
let busy = false;

$<HTMLElement>("logo").innerHTML = logoSvg;

function renderModes(): void {
  modesEl.replaceChildren(
    ...MODES.map((info) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "bro-mode";
      button.setAttribute("aria-pressed", String(info.id === mode));
      button.innerHTML = `<span class="bro-mode__title"></span><span class="bro-mode__desc"></span>`;
      button.querySelector(".bro-mode__title")!.textContent = info.title;
      button.querySelector(".bro-mode__desc")!.textContent = info.description;
      button.addEventListener("click", () => {
        mode = info.id;
        renderModes();
      });
      return button;
    }),
  );
}

function updateTone(): void {
  toneLabelEl.textContent = `Tone: ${toneLabel(Number(toneEl.value))}`;
}

function updateGenerateEnabled(): void {
  generateEl.disabled = busy || contextEl.value.trim().length === 0;
}

function showLoading(): void {
  resultEl.replaceChildren(createFistBumpLoader(96, "Reading the room…"));
}

function showError(message: string): void {
  const error = document.createElement("p");
  error.className = "bro-error";
  error.textContent = message;
  resultEl.replaceChildren(error);
}

function showReply(reply: string): void {
  const bubble = document.createElement("div");
  bubble.className = "bro-bubble";
  bubble.textContent = reply;

  const note = document.createElement("p");
  note.className = "bro-caption";
  note.style.textAlign = "right";
  note.textContent = "Not sent. Paste it and hit send yourself.";

  const copy = document.createElement("button");
  copy.type = "button";
  copy.className = "bro-btn";
  copy.textContent = "Copy";
  copy.addEventListener("click", async () => {
    await navigator.clipboard.writeText(reply);
    copy.textContent = "Copied. Go.";
    setTimeout(() => (copy.textContent = "Copy"), 1800);
  });

  const regenerate = document.createElement("button");
  regenerate.type = "button";
  regenerate.className = "bro-btn";
  regenerate.textContent = "Regenerate";
  regenerate.addEventListener("click", () => void generate());

  const actions = document.createElement("div");
  actions.className = "popup__actions";
  actions.append(regenerate, copy);

  resultEl.replaceChildren(bubble, note, actions);
  copy.focus();
}

async function generate(): Promise<void> {
  const context = contextEl.value.trim();
  if (!context || busy) return;
  busy = true;
  updateGenerateEnabled();
  showLoading();

  const response = await requestReply({
    mode,
    context,
    tone: Number(toneEl.value),
    language: languageEl.value as Language,
  });

  busy = false;
  updateGenerateEnabled();
  if (response.ok) showReply(response.reply);
  else showError(response.error);
}

async function init(): Promise<void> {
  const settings = await getSettings();
  toneEl.value = String(settings.tone);
  languageEl.value = settings.language;
  updateTone();

  toneEl.addEventListener("input", updateTone);
  toneEl.addEventListener("change", () => void saveSettings({ tone: Number(toneEl.value) }));
  languageEl.addEventListener("change", () => void saveSettings({ language: languageEl.value as Language }));
  contextEl.addEventListener("input", updateGenerateEnabled);
  generateEl.addEventListener("click", () => void generate());
  contextEl.addEventListener("keydown", (event) => {
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) void generate();
  });

  // Context menu: "Bro Protocol: reply to this" → BANTER with the selection.
  const pending = await takePendingSelection();
  await chrome.action.setBadgeText({ text: "" });
  if (pending) {
    mode = pending.mode;
    contextEl.value = pending.text;
  }
  renderModes();
  updateGenerateEnabled();

  if (pending) void generate();
  else contextEl.focus();
}

void init();
