"use client";

import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";

import { ContinueRow } from "@/components/ContinueRow";
import { InfoBanner } from "@/components/InfoBanner";
import { ModeGrid } from "@/components/ModeGrid";
import { QuickPaste } from "@/components/QuickPaste";
import { StatsStrip } from "@/components/StatsStrip";
import { HOME_MODES } from "@/lib/modes";
import { KEYS } from "@/lib/storage";

function isTyping(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;
  return target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);
}

export default function HomePage() {
  const router = useRouter();
  const pasteRef = useRef<HTMLTextAreaElement>(null);

  // Desktop shortcuts: 1–6 open a mode, Ctrl/Cmd+K focuses quick paste.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        pasteRef.current?.focus();
        return;
      }
      if (e.metaKey || e.ctrlKey || e.altKey || isTyping(e.target)) return;
      const n = Number(e.key);
      if (Number.isInteger(n) && n >= 1 && n <= HOME_MODES.length) {
        router.push(`/compose?mode=${HOME_MODES[n - 1].id}`);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [router]);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <h1 className="font-display text-3xl tracking-[0.02em] text-text sm:text-5xl">
          Say less. <span className="bg-brand-gradient bg-clip-text text-transparent">Say it right.</span>
        </h1>
        <p className="text-sm text-muted">
          Paste her message, pick a play, copy the reply. Nothing is ever sent for you.
        </p>
      </div>

      <QuickPaste ref={pasteRef} />
      <ContinueRow />
      <ModeGrid />
      <StatsStrip />

      <InfoBanner storageKey={KEYS.shareTipDismissed} title="Faster from Messenger">
        On Android, long-press her message → Share → Bro Protocol. It opens Banter with her message ready.
      </InfoBanner>

      <p className="hidden text-xs text-muted lg:block">
        Shortcuts: <kbd className="rounded border border-border px-1">1</kbd>–
        <kbd className="rounded border border-border px-1">6</kbd> open a play ·{" "}
        <kbd className="rounded border border-border px-1">Ctrl</kbd>/<kbd className="rounded border border-border px-1">⌘</kbd>+
        <kbd className="rounded border border-border px-1">K</kbd> paste
      </p>
    </div>
  );
}
