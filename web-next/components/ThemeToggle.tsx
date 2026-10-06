"use client";

import { Monitor, Moon, Sun } from "lucide-react";

import { IconButton } from "./IconButton";
import { useTheme, type ThemePref } from "./ThemeProvider";

/** Header sun/moon button: flips between light and dark. */
export function ThemeToggle() {
  const { resolved, setPref } = useTheme();
  const toDark = resolved === "light";
  return (
    <IconButton
      icon={toDark ? Moon : Sun}
      label={toDark ? "Switch to dark mode" : "Switch to light mode"}
      onClick={() => setPref(toDark ? "dark" : "light")}
    />
  );
}

const OPTIONS: { value: ThemePref; label: string; icon: typeof Sun }[] = [
  { value: "system", label: "System", icon: Monitor },
  { value: "light", label: "Light", icon: Sun },
  { value: "dark", label: "Dark", icon: Moon },
];

/** Settings: System / Light / Dark segmented control. */
export function ThemeSegmented() {
  const { pref, setPref } = useTheme();
  return (
    <div role="radiogroup" aria-label="Theme" className="theme-fade grid grid-cols-3 gap-2 rounded-2xl border border-border bg-surface p-2 card-shadow">
      {OPTIONS.map(({ value, label, icon: Icon }) => {
        const selected = pref === value;
        return (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => setPref(value)}
            className={
              "theme-fade inline-flex min-h-11 items-center justify-center gap-2 rounded-xl text-sm font-semibold " +
              (selected ? "bg-text text-bg" : "text-muted hover:text-text")
            }
          >
            <Icon aria-hidden className="size-4" />
            {label}
          </button>
        );
      })}
    </div>
  );
}
