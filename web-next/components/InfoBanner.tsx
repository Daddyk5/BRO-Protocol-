"use client";

import type { ReactNode } from "react";
import { Info, X } from "lucide-react";

import { useStoredState } from "@/lib/storage";

interface InfoBannerProps {
  /** localStorage key that remembers the dismissal. */
  storageKey: string;
  title: string;
  children: ReactNode;
}

/** Shown until the user closes it once. */
export function InfoBanner({ storageKey, title, children }: InfoBannerProps) {
  const [dismissed, setDismissed, ready] = useStoredState<boolean>(storageKey, false);
  if (!ready || dismissed) return null;

  return (
    <aside
      aria-label={title}
      className="theme-fade flex items-start gap-4 rounded-2xl border border-border bg-surface p-4 card-shadow"
    >
      <Info aria-hidden className="mt-0.5 size-5 shrink-0 text-brand-blue" />
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-text">{title}</p>
        <p className="mt-1 text-sm text-muted">{children}</p>
      </div>
      <button
        type="button"
        onClick={() => setDismissed(true)}
        aria-label="Dismiss tip"
        className="-m-2 inline-flex size-11 shrink-0 items-center justify-center rounded-full text-muted hover:text-text"
      >
        <X aria-hidden className="size-5" />
      </button>
    </aside>
  );
}
