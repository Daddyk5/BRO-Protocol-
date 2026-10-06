"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Check, Copy, LoaderCircle, Sparkles, Star } from "lucide-react";

import { generateReplies, type ReplyOption } from "@/lib/api";
import {
  deviceId,
  newId,
  recordUsage,
  saveConversation,
  type Conversation,
  type Profile,
  type SavedReply,
} from "@/lib/data";
import { ALL_MODES, modeById, type ModeId } from "@/lib/modes";
import { KEYS, readJson, useStoredState, writeJson } from "@/lib/storage";

export default function ComposePage() {
  return (
    <Suspense>
      <Composer />
    </Suspense>
  );
}

function Composer() {
  const params = useSearchParams();
  const [mode, setMode] = useState<ModeId>(modeById(params.get("mode")).id);
  const [text, setText] = useState("");
  const [threeOptions, setThreeOptions] = useState(true);
  const [profileId, setProfileId] = useState("");
  const [options, setOptions] = useState<ReplyOption[]>([]);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [profiles] = useStoredState<Profile[]>(KEYS.profiles, []);
  const [saved, setSaved] = useStoredState<SavedReply[]>(KEYS.saved, []);

  const generate = useCallback(
    async (input: { mode: ModeId; text: string; profileId: string; three: boolean }) => {
      if (!input.text.trim()) return;
      setLoading(true);
      setError("");
      try {
        const profile = readJson<Profile[]>(KEYS.profiles, []).find((p) => p.id === input.profileId);
        const replies = await generateReplies({
          mode: input.mode,
          context: input.text.trim(),
          deviceId: deviceId(),
          count: input.three ? 3 : 1,
          notes: profile ? `Name: ${profile.name}. ${profile.notes}`.trim() : undefined,
        });
        const conversation: Conversation = {
          id: newId(),
          mode: input.mode,
          context: input.text.trim(),
          options: replies,
          profileId: input.profileId || undefined,
          at: Date.now(),
        };
        saveConversation(conversation);
        recordUsage(replies.length);
        setConversationId(conversation.id);
        setOptions(replies);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Something went sideways. Try again.");
      } finally {
        setLoading(false);
      }
    },
    [],
  );

  // Arrive from quick paste (draft in storage) or a Continue chip (?id=).
  useEffect(() => {
    const id = params.get("id");
    if (id) {
      const found = readJson<Conversation[]>(KEYS.recent, []).find((c) => c.id === id);
      if (found) {
        setMode(found.mode);
        setText(found.context);
        setOptions(found.options);
        setConversationId(found.id);
        setProfileId(found.profileId ?? "");
      }
      return;
    }
    const draft = readJson<{ mode: ModeId; text: string; autoGenerate?: boolean } | null>(KEYS.draft, null);
    if (draft) {
      writeJson(KEYS.draft, null);
      setMode(draft.mode);
      setText(draft.text);
      if (draft.autoGenerate) void generate({ mode: draft.mode, text: draft.text, profileId: "", three: true });
    }
  }, [params, generate]);

  const current = modeById(mode);

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-3xl tracking-[0.02em] text-text">{current.title}</h1>

      <form
        className="flex flex-col gap-4"
        onSubmit={(e) => {
          e.preventDefault();
          void generate({ mode, text, profileId, three: threeOptions });
        }}
      >
        <fieldset className="flex flex-wrap gap-2">
          <legend className="sr-only">Mode</legend>
          {ALL_MODES.map((m) => {
            const selected = m.id === mode;
            return (
              <button
                key={m.id}
                type="button"
                aria-pressed={selected}
                onClick={() => setMode(m.id)}
                style={{ ["--accent" as string]: m.accent }}
                className={
                  "theme-fade inline-flex min-h-11 items-center gap-2 rounded-full border px-4 text-sm font-medium " +
                  (selected ? "border-[var(--accent)] bg-surface text-text" : "border-border text-muted hover:text-text")
                }
              >
                <m.icon aria-hidden className="size-4" style={{ color: m.accent }} />
                {m.title}
              </button>
            );
          })}
        </fieldset>

        <label className="flex flex-col gap-2 text-sm font-semibold text-text">
          For
          <select
            value={profileId}
            onChange={(e) => setProfileId(e.target.value)}
            className="theme-fade min-h-11 rounded-xl border border-border bg-surface px-4 text-base font-normal text-text"
          >
            <option value="">No one specific</option>
            {profiles.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>

        <label className="flex flex-col gap-2 text-sm font-semibold text-text">
          The chat
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={6}
            maxLength={5000}
            placeholder={current.inputHint}
            className="theme-fade rounded-2xl border border-border bg-surface p-4 text-base font-normal text-text placeholder:text-muted card-shadow"
          />
        </label>

        <label className="flex min-h-11 items-center gap-2 text-sm text-text">
          <input
            type="checkbox"
            checked={threeOptions}
            onChange={(e) => setThreeOptions(e.target.checked)}
            className="size-5 accent-[#3B5BFD]"
          />
          3 options (Chill, Balanced, Bold)
        </label>

        <button
          type="submit"
          disabled={loading || !text.trim()}
          className="bg-brand-gradient inline-flex min-h-12 items-center justify-center gap-2 rounded-xl px-6 font-display text-2xl tracking-[0.02em] text-white disabled:opacity-50"
        >
          {loading ? <LoaderCircle aria-hidden className="size-5 animate-spin" /> : <Sparkles aria-hidden className="size-5" />}
          {loading ? "Writing…" : "Generate"}
        </button>
      </form>

      <div aria-live="polite" className="flex flex-col gap-4">
        {error && (
          <p role="alert" className="rounded-xl border border-border bg-surface p-4 text-sm text-text">
            {error}
          </p>
        )}
        {options.map((option, i) => (
          <OptionCard
            key={`${conversationId}-${i}`}
            option={option}
            saved={saved.some((s) => s.text === option.reply)}
            onToggleSave={() => {
              const exists = saved.some((s) => s.text === option.reply);
              setSaved(
                exists
                  ? saved.filter((s) => s.text !== option.reply)
                  : [{ id: newId(), text: option.reply, mode, at: Date.now() }, ...saved],
              );
            }}
          />
        ))}
        {options.length > 0 && <p className="text-xs text-muted">Nothing is sent for you. Copy one and send it yourself.</p>}
      </div>
    </div>
  );
}

function OptionCard({ option, saved, onToggleSave }: { option: ReplyOption; saved: boolean; onToggleSave: () => void }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(option.reply);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* clipboard blocked: the text is selectable */
    }
  };

  return (
    <article className="theme-fade flex flex-col gap-2 rounded-2xl border border-border bg-surface p-4 card-shadow">
      <p className="text-xs font-semibold tracking-wide text-muted uppercase">{option.label}</p>
      <p className="text-base text-text select-text">{option.reply}</p>
      {option.tip && <p className="text-sm text-muted">Why it works: {option.tip}</p>}
      <div className="flex gap-2">
        <button
          type="button"
          onClick={copy}
          className="bg-brand-gradient inline-flex min-h-11 items-center gap-2 rounded-xl px-4 text-xl font-bold text-white"
        >
          {copied ? <Check aria-hidden className="size-4" /> : <Copy aria-hidden className="size-4" />}
          {copied ? "Copied" : "Copy"}
        </button>
        <button
          type="button"
          onClick={onToggleSave}
          aria-pressed={saved}
          className="theme-fade inline-flex min-h-11 items-center gap-2 rounded-xl border border-border px-4 text-sm font-medium text-text"
        >
          <Star aria-hidden className={"size-4 " + (saved ? "fill-current" : "")} />
          {saved ? "Saved" : "Save"}
        </button>
      </div>
    </article>
  );
}
