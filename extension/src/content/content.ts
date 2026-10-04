import tokensCss from "../shared/tokens.css?inline";
import { createFistBumpLoader } from "../shared/loader";
import { logoSvg } from "../shared/logo";
import { requestReply } from "../shared/messages";
import { MAX_CONTEXT_LENGTH, MODES, type Mode, toneLabel } from "../shared/modes";
import { getSettings, saveSettings } from "../shared/storage";
import contentCss from "./content.css?inline";

/*
 * Floating fist-bump button next to the Messenger / Facebook Dating message box.
 * Nothing runs until the user clicks it. On click it reads the last visible
 * messages, lets the user pick a mode and generate, and "Insert" pastes the
 * reply into the box. It never presses Enter and never sends anything.
 */

const host = document.createElement("div");
host.id = "bro-protocol-root";
const shadow = host.attachShadow({ mode: "open" });
shadow.innerHTML = `<style>${tokensCss}\n${contentCss}</style>`;

const fab = document.createElement("button");
fab.type = "button";
fab.className = "bro-fab";
fab.hidden = true;
fab.setAttribute("aria-label", "Bro Protocol: write a reply");
fab.title = "Bro Protocol: write a reply";
fab.innerHTML = logoSvg;

const panel = document.createElement("div");
panel.className = "bro-panel";
panel.hidden = true;
panel.setAttribute("role", "dialog");
panel.setAttribute("aria-label", "Bro Protocol");
panel.innerHTML = `
  <div class="bro-panel__header">
    ${logoSvg}
    <h2 class="bro-heading bro-panel__title">BRO PROTOCOL</h2>
    <button type="button" class="bro-btn bro-panel__close" aria-label="Close">×</button>
  </div>
  <div class="bro-modes" role="group" aria-label="Mode"></div>
  <p class="bro-panel__label">Last messages (edit if needed)</p>
  <textarea class="bro-textarea" rows="5" aria-label="Conversation context"
    placeholder="Paste her bio / her message / the chat here"></textarea>
  <div class="bro-tone">
    <span>Chill</span>
    <input class="bro-range" type="range" min="0" max="1" step="0.01" aria-label="Tone" />
    <span>Bold</span>
  </div>
  <button type="button" class="bro-btn bro-btn--primary bro-panel__generate">GENERATE</button>
  <div class="bro-panel__result" aria-live="polite"></div>
  <p class="bro-caption">Insert pastes the reply into the message box. You hit send.</p>`;

shadow.append(fab, panel);

const modesEl = panel.querySelector<HTMLElement>(".bro-modes")!;
const contextEl = panel.querySelector<HTMLTextAreaElement>("textarea")!;
const toneEl = panel.querySelector<HTMLInputElement>(".bro-range")!;
const generateEl = panel.querySelector<HTMLButtonElement>(".bro-panel__generate")!;
const resultEl = panel.querySelector<HTMLElement>(".bro-panel__result")!;
const closeEl = panel.querySelector<HTMLButtonElement>(".bro-panel__close")!;

let mode: Mode = "BANTER";
let busy = false;

// ---------------------------------------------------------------- page model

function isActivePage(): boolean {
  const { hostname, pathname } = location;
  if (hostname.endsWith("messenger.com")) return true;
  if (hostname.endsWith("facebook.com")) return pathname.startsWith("/dating") || pathname.startsWith("/messages");
  return false;
}

function isVisible(el: Element): boolean {
  const rect = el.getBoundingClientRect();
  return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.top < window.innerHeight;
}

/** The chat input: a visible contenteditable textbox, preferring one labelled as the message box. */
function findComposer(): HTMLElement | null {
  const candidates = Array.from(
    document.querySelectorAll<HTMLElement>('[contenteditable="true"][role="textbox"]'),
  ).filter(isVisible);
  if (candidates.length === 0) return null;
  const labelled = candidates.filter((el) =>
    /message|^aa$/i.test(`${el.getAttribute("aria-label") ?? ""}`.trim() || `${el.getAttribute("aria-placeholder") ?? ""}`.trim()),
  );
  const pool = labelled.length > 0 ? labelled : candidates;
  return pool.reduce((best, el) =>
    el.getBoundingClientRect().bottom > best.getBoundingClientRect().bottom ? el : best,
  );
}

function clean(text: string): string {
  return text.replace(/\s+/g, " ").trim().slice(0, 400);
}

/** Best-effort read of the last visible messages; the user can edit the result. */
function readRecentMessages(limit = 8): string {
  const root = document.querySelector('[role="main"]') ?? document.body;
  const composer = findComposer();
  const usable = (el: HTMLElement) => isVisible(el) && !(composer && (composer.contains(el) || el.contains(composer)));

  let lines = Array.from(root.querySelectorAll<HTMLElement>('[role="row"]'))
    .filter(usable)
    .map((row) => clean(row.innerText))
    .filter(Boolean);

  if (lines.length === 0) {
    lines = Array.from(root.querySelectorAll<HTMLElement>('div[dir="auto"], span[dir="auto"]'))
      .filter((el) => usable(el) && !el.querySelector('[dir="auto"]'))
      .map((el) => clean(el.innerText))
      .filter((text, i, all) => text.length > 0 && text !== all[i - 1]);
  }

  return lines.slice(-limit).join("\n").slice(-MAX_CONTEXT_LENGTH);
}

/** Pastes [text] into the message box at the end of any draft. Never sends. */
function insertIntoComposer(text: string): boolean {
  const box = findComposer();
  if (!box) return false;
  box.focus();
  const selection = window.getSelection();
  const range = document.createRange();
  range.selectNodeContents(box);
  range.collapse(false);
  selection?.removeAllRanges();
  selection?.addRange(range);

  if (document.execCommand("insertText", false, text)) return true;

  // Fallback for editors that ignore execCommand: a synthetic paste.
  const data = new DataTransfer();
  data.setData("text/plain", text);
  box.dispatchEvent(new ClipboardEvent("paste", { clipboardData: data, bubbles: true, cancelable: true }));
  return true;
}

// ---------------------------------------------------------------- layout

function position(): void {
  const composer = isActivePage() ? findComposer() : null;
  if (!composer) {
    fab.hidden = true;
    panel.hidden = true;
    return;
  }
  if (!host.isConnected) document.documentElement.append(host);

  const rect = composer.getBoundingClientRect();
  const size = 44;
  const left = Math.min(Math.max(8, rect.right - size), window.innerWidth - size - 8);
  const top = Math.max(8, rect.top - size - 10);
  fab.style.left = `${left}px`;
  fab.style.top = `${top}px`;
  fab.hidden = false;

  if (!panel.hidden) {
    panel.style.right = `${Math.max(8, window.innerWidth - (left + size))}px`;
    panel.style.bottom = `${Math.max(8, window.innerHeight - top + 8)}px`;
    panel.style.maxHeight = `${Math.max(240, top - 16)}px`;
  }
}

let frame = 0;
function schedulePosition(): void {
  if (frame) return;
  frame = requestAnimationFrame(() => {
    frame = 0;
    position();
  });
}

// ---------------------------------------------------------------- panel

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

function updateGenerateEnabled(): void {
  generateEl.disabled = busy || contextEl.value.trim().length === 0;
  toneEl.title = `Tone: ${toneLabel(Number(toneEl.value))}`;
}

function showError(message: string): void {
  const error = document.createElement("p");
  error.className = "bro-error";
  error.textContent = message;
  resultEl.replaceChildren(error);
}

function button(label: string, primary = false): HTMLButtonElement {
  const el = document.createElement("button");
  el.type = "button";
  el.className = primary ? "bro-btn bro-btn--primary" : "bro-btn";
  el.textContent = label;
  return el;
}

function showReply(reply: string): void {
  const bubble = document.createElement("div");
  bubble.className = "bro-bubble";
  bubble.textContent = reply;

  const regenerate = button("Regenerate");
  regenerate.addEventListener("click", () => void generate());

  const copy = button("Copy");
  copy.addEventListener("click", async () => {
    await navigator.clipboard.writeText(reply);
    copy.textContent = "Copied. Go.";
    setTimeout(() => (copy.textContent = "Copy"), 1800);
  });

  const insert = button("INSERT", true);
  insert.addEventListener("click", () => {
    if (insertIntoComposer(reply)) closePanel(false);
    else showError("Couldn't find the message box. Click into it, then use Copy.");
  });

  const actions = document.createElement("div");
  actions.className = "bro-panel__actions";
  actions.append(regenerate, copy, insert);
  resultEl.replaceChildren(bubble, actions);
  insert.focus();
}

async function generate(): Promise<void> {
  const context = contextEl.value.trim();
  if (!context || busy) return;
  busy = true;
  updateGenerateEnabled();
  resultEl.replaceChildren(createFistBumpLoader(80, "Reading the room…"));

  const { language } = await getSettings();
  const response = await requestReply({ mode, context, tone: Number(toneEl.value), language });

  busy = false;
  updateGenerateEnabled();
  if (response.ok) showReply(response.reply);
  else showError(response.error);
}

async function openPanel(): Promise<void> {
  const settings = await getSettings();
  toneEl.value = String(settings.tone);
  contextEl.value = readRecentMessages();
  resultEl.replaceChildren();
  renderModes();
  updateGenerateEnabled();
  panel.hidden = false;
  fab.setAttribute("aria-expanded", "true");
  position();
  contextEl.focus();
}

function closePanel(returnFocus = true): void {
  panel.hidden = true;
  fab.setAttribute("aria-expanded", "false");
  if (returnFocus) fab.focus();
}

fab.addEventListener("click", () => {
  if (panel.hidden) void openPanel();
  else closePanel();
});
closeEl.addEventListener("click", () => closePanel());
generateEl.addEventListener("click", () => void generate());
contextEl.addEventListener("input", updateGenerateEnabled);
toneEl.addEventListener("input", updateGenerateEnabled);
toneEl.addEventListener("change", () => void saveSettings({ tone: Number(toneEl.value) }));
panel.addEventListener("keydown", (event) => {
  event.stopPropagation(); // Keep Messenger's shortcuts from firing while typing here.
  if (event.key === "Escape") closePanel();
  if (event.key === "Enter" && (event.ctrlKey || event.metaKey) && event.target === contextEl) void generate();
});

// Messenger and Facebook are single-page apps: re-check the route and the
// composer position periodically and on layout changes.
window.addEventListener("resize", schedulePosition, { passive: true });
window.addEventListener("scroll", schedulePosition, { passive: true, capture: true });
setInterval(position, 800);
position();
