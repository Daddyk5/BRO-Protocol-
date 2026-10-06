"use client";

import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

import { KEYS, readJson, writeJson } from "@/lib/storage";

export type ThemePref = "system" | "light" | "dark";
export type ResolvedTheme = "light" | "dark";

interface ThemeContextValue {
  pref: ThemePref;
  resolved: ResolvedTheme;
  setPref: (pref: ThemePref) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

/**
 * Runs in <head> before first paint so the page never flashes the wrong
 * theme. Keep it in sync with resolve() below.
 */
export const themeInitScript = `(function(){try{var p=JSON.parse(localStorage.getItem(${JSON.stringify(
  KEYS.theme,
)})||'"system"');var d=p==="dark"||(p!=="light"&&matchMedia("(prefers-color-scheme: dark)").matches);document.documentElement.dataset.theme=d?"dark":"light"}catch(e){document.documentElement.dataset.theme=matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"}})();`;

function systemTheme(): ResolvedTheme {
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function resolve(pref: ThemePref): ResolvedTheme {
  return pref === "system" ? systemTheme() : pref;
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  // The inline script has already set data-theme; start from "system" and
  // sync with storage after mount to keep server and client markup equal.
  const [pref, setPrefState] = useState<ThemePref>("system");
  const [resolved, setResolved] = useState<ResolvedTheme>("dark");

  useEffect(() => {
    const stored = readJson<ThemePref>(KEYS.theme, "system");
    setPrefState(stored);
    setResolved(resolve(stored));
  }, []);

  // Apply the theme, and follow OS changes while on "system".
  useEffect(() => {
    const apply = () => {
      const next = resolve(pref);
      document.documentElement.dataset.theme = next;
      setResolved(next);
    };
    apply();
    if (pref !== "system") return;
    const media = window.matchMedia("(prefers-color-scheme: dark)");
    media.addEventListener("change", apply);
    return () => media.removeEventListener("change", apply);
  }, [pref]);

  const setPref = useCallback((next: ThemePref) => {
    setPrefState(next);
    writeJson(KEYS.theme, next);
  }, []);

  return <ThemeContext.Provider value={{ pref, resolved, setPref }}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside <ThemeProvider>");
  return value;
}
