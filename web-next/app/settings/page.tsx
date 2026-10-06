"use client";

import { ThemeSegmented } from "@/components/ThemeToggle";

export default function SettingsPage() {
  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-3xl tracking-[0.02em] text-text">Settings</h1>
      <section aria-labelledby="appearance-heading" className="flex flex-col gap-2">
        <h2 id="appearance-heading" className="text-xs font-semibold tracking-wide text-muted uppercase">
          Appearance
        </h2>
        <ThemeSegmented />
        <p className="text-xs text-muted">System follows your device’s light or dark setting.</p>
      </section>
    </div>
  );
}
