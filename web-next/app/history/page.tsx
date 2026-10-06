"use client";

import Link from "next/link";
import { Star, Trash2 } from "lucide-react";

import { snippet, type Conversation, type SavedReply } from "@/lib/data";
import { modeById } from "@/lib/modes";
import { KEYS, useStoredState } from "@/lib/storage";

export default function HistoryPage() {
  const [recent, setRecent, recentReady] = useStoredState<Conversation[]>(KEYS.recent, []);
  const [saved, setSaved, savedReady] = useStoredState<SavedReply[]>(KEYS.saved, []);

  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-display text-3xl tracking-[0.02em] text-text">History</h1>

      <section aria-labelledby="recent-heading" className="flex flex-col gap-2">
        <h2 id="recent-heading" className="text-xs font-semibold tracking-wide text-muted uppercase">
          Recent
        </h2>
        {recentReady && recent.length === 0 && <p className="text-sm text-muted">No conversations yet.</p>}
        <ul className="flex flex-col gap-2">
          {recent.map((c) => {
            const mode = modeById(c.mode);
            return (
              <li key={c.id} className="theme-fade flex items-center gap-2 rounded-2xl border border-border bg-surface card-shadow">
                <Link href={`/compose?id=${encodeURIComponent(c.id)}`} className="flex min-h-14 min-w-0 flex-1 flex-col justify-center rounded-2xl px-4 py-2">
                  <span className="text-xs text-muted">
                    {mode.title} · {new Date(c.at).toLocaleString()}
                  </span>
                  <span className="truncate text-sm text-text">{snippet(c.context, 80)}</span>
                </Link>
                <button
                  type="button"
                  aria-label="Delete conversation"
                  onClick={() => setRecent(recent.filter((r) => r.id !== c.id))}
                  className="mr-2 inline-flex size-11 shrink-0 items-center justify-center rounded-full text-muted hover:text-text"
                >
                  <Trash2 aria-hidden className="size-4" />
                </button>
              </li>
            );
          })}
        </ul>
      </section>

      <section id="saved" aria-labelledby="saved-heading" className="flex flex-col gap-2">
        <h2 id="saved-heading" className="text-xs font-semibold tracking-wide text-muted uppercase">
          Saved
        </h2>
        {savedReady && saved.length === 0 && <p className="text-sm text-muted">Star a reply to save it here.</p>}
        <ul className="flex flex-col gap-2">
          {saved.map((s) => (
            <li key={s.id} className="theme-fade flex items-start gap-2 rounded-2xl border border-border bg-surface p-4 card-shadow">
              <div className="min-w-0 flex-1">
                <p className="text-xs text-muted">{modeById(s.mode).title}</p>
                <p className="text-base text-text">{s.text}</p>
              </div>
              <button
                type="button"
                aria-label="Remove from saved"
                onClick={() => setSaved(saved.filter((x) => x.id !== s.id))}
                className="-m-2 inline-flex size-11 shrink-0 items-center justify-center rounded-full text-muted hover:text-text"
              >
                <Star aria-hidden className="size-4 fill-current" />
              </button>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
