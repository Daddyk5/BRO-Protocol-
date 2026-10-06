"use client";

import { useCallback, useEffect, useState } from "react";

/**
 * localStorage can be missing or throw (private windows, blocked storage), so
 * every read and write is guarded and the app keeps working without it.
 */
export function readJson<T>(key: string, fallback: T): T {
  try {
    const raw = window.localStorage.getItem(key);
    return raw == null ? fallback : (JSON.parse(raw) as T);
  } catch {
    return fallback;
  }
}

export function writeJson(key: string, value: unknown): void {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
    // Other components using the same key re-read on this event.
    window.dispatchEvent(new CustomEvent("bro-storage", { detail: key }));
  } catch {
    /* storage unavailable: keep the in-memory value only */
  }
}

/**
 * State backed by localStorage. `ready` is false during server render and the
 * first client render, so callers can avoid flashing an empty state.
 */
export function useStoredState<T>(key: string, fallback: T): [T, (value: T) => void, boolean] {
  const [value, setValue] = useState<T>(fallback);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setValue(readJson(key, fallback));
    setReady(true);
    const onChange = (e: Event) => {
      if (e instanceof StorageEvent ? e.key === key : (e as CustomEvent).detail === key) {
        setValue(readJson(key, fallback));
      }
    };
    window.addEventListener("storage", onChange);
    window.addEventListener("bro-storage", onChange);
    return () => {
      window.removeEventListener("storage", onChange);
      window.removeEventListener("bro-storage", onChange);
    };
    // `fallback` is a default, not a dependency: callers pass literals.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  const update = useCallback(
    (next: T) => {
      setValue(next);
      writeJson(key, next);
    },
    [key],
  );

  return [value, update, ready];
}

export const KEYS = {
  theme: "bro.theme",
  recent: "bro.recent",
  saved: "bro.saved",
  events: "bro.events",
  profiles: "bro.profiles",
  shareTipDismissed: "bro.shareTipDismissed",
  draft: "bro.draft",
  deviceId: "bro.deviceId",
} as const;
