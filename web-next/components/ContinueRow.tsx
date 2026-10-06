"use client";

import Link from "next/link";
import { MessageCircle } from "lucide-react";

import { snippet, type Conversation } from "@/lib/data";
import { modeById } from "@/lib/modes";
import { KEYS, useStoredState } from "@/lib/storage";

/** The 3 most recent conversations as horizontally scrollable chips. */
export function ContinueRow() {
  const [recent, , ready] = useStoredState<Conversation[]>(KEYS.recent, []);
  const items = recent.slice(0, 3);

  return (
    <section aria-labelledby="continue-heading" className="flex flex-col gap-2">
      <h2 id="continue-heading" className="text-xs font-semibold tracking-wide text-muted uppercase">
        Continue
      </h2>
      {!ready ? (
        <div aria-hidden className="h-11 w-48 rounded-full border border-border bg-surface" />
      ) : items.length === 0 ? (
        <p className="theme-fade flex min-h-11 items-center gap-2 rounded-xl border border-dashed border-border px-4 text-sm text-muted">
          <MessageCircle aria-hidden className="size-4 shrink-0" />
          Your recent chats show up here after your first reply.
        </p>
      ) : (
        <ul className="no-scrollbar -mx-4 flex snap-x gap-2 overflow-x-auto px-4 pb-2 sm:mx-0 sm:px-0">
          {items.map((c) => {
            const mode = modeById(c.mode);
            return (
              <li key={c.id} className="snap-start">
                <Link
                  href={`/compose?id=${encodeURIComponent(c.id)}`}
                  className="theme-fade flex min-h-11 max-w-[260px] items-center gap-2 rounded-full border border-border bg-surface px-4 text-sm text-text card-shadow hover:border-[var(--accent)]"
                  style={{ ["--accent" as string]: mode.accent }}
                >
                  <span aria-hidden className="size-2 shrink-0 rounded-full" style={{ background: mode.accent }} />
                  <span className="truncate">
                    <span className="sr-only">{mode.title}: </span>
                    {snippet(c.context, 36)}
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
