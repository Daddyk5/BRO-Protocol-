"use client";

import { forwardRef, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Sparkles } from "lucide-react";

import { KEYS, writeJson } from "@/lib/storage";

/**
 * "Paste her message…" + Generate. Hands the text to the composer (in
 * BANTER) through storage, so long chats don't end up in the URL.
 */
export const QuickPaste = forwardRef<HTMLTextAreaElement>(function QuickPaste(_, ref) {
  const router = useRouter();
  const [text, setText] = useState("");
  const ready = text.trim().length > 0;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (!ready) return;
    writeJson(KEYS.draft, { mode: "BANTER", text: text.trim(), autoGenerate: true });
    router.push("/compose?mode=BANTER");
  };

  return (
    <form
      onSubmit={submit}
      className="theme-fade flex flex-col gap-2 rounded-2xl border border-border bg-surface p-2 card-shadow sm:flex-row sm:items-stretch"
    >
      <label htmlFor="quick-paste" className="sr-only">
        Paste her message
      </label>
      <textarea
        id="quick-paste"
        ref={ref}
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) submit(e);
        }}
        rows={2}
        maxLength={5000}
        placeholder="Paste her message…"
        aria-describedby="quick-paste-hint"
        className="min-h-12 w-full flex-1 resize-none rounded-xl bg-transparent px-2 py-2 text-base text-text placeholder:text-muted focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2"
      />
      <span id="quick-paste-hint" className="sr-only">
        Press Control or Command plus K to focus this box from anywhere on the page.
      </span>
      <button
        type="submit"
        disabled={!ready}
        className="bg-brand-gradient inline-flex min-h-12 shrink-0 items-center justify-center gap-2 rounded-xl px-6 font-display text-2xl tracking-[0.02em] text-white transition-opacity duration-200 disabled:opacity-50"
      >
        <Sparkles aria-hidden className="size-5" />
        Generate
      </button>
    </form>
  );
});
