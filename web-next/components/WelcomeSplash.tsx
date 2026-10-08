"use client";

import { useCallback, useEffect, useState } from "react";

const SESSION_KEY = "bro.welcomed";
const FULL_MS = 2400;
const REDUCED_MS = 700;
const FADE_MS = 300;

/**
 * Runs in <head>: when the welcome already played this session, hide it
 * before first paint so returning to the app never flashes it.
 */
export const welcomeInitScript = `(function(){try{if(sessionStorage.getItem(${JSON.stringify(
  SESSION_KEY,
)}))document.documentElement.dataset.welcomed="1"}catch(e){}})();`;

/**
 * Fist-bump intro: the two fists slide in and bump, a spark and shockwave
 * pop, the wordmark rises, a bar fills, then the app shows. Once per
 * session; tap or Escape skips it; reduced motion gets a short static frame.
 */
export function WelcomeSplash() {
  const [phase, setPhase] = useState<"show" | "out" | "gone">("show");

  const finish = useCallback(() => {
    setPhase((p) => (p === "show" ? "out" : p));
  }, []);

  useEffect(() => {
    if (document.documentElement.dataset.welcomed) {
      setPhase("gone");
      return;
    }
    try {
      sessionStorage.setItem(SESSION_KEY, "1");
    } catch {
      /* private mode: it just plays again next time */
    }
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const timer = window.setTimeout(finish, reduced ? REDUCED_MS : FULL_MS);
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" || e.key === "Enter" || e.key === " ") finish();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("keydown", onKey);
    };
  }, [finish]);

  useEffect(() => {
    if (phase !== "out") return;
    const timer = window.setTimeout(() => {
      setPhase("gone");
      document.documentElement.dataset.welcomed = "1";
    }, FADE_MS);
    return () => window.clearTimeout(timer);
  }, [phase]);

  if (phase === "gone") return null;

  return (
    <div
      className={"welcome-splash" + (phase === "out" ? " welcome-out" : "")}
      role="status"
      aria-label="Loading Bro Protocol"
      onClick={finish}
    >
      <div className="welcome-mark" aria-hidden>
        <span className="welcome-ring" />
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/fist_red.svg" alt="" className="welcome-fist welcome-fist-left" width={128} height={256} />
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/fist_blue.svg" alt="" className="welcome-fist welcome-fist-right" width={128} height={256} />
        <svg className="welcome-spark" viewBox="186 186 140 140" width={56} height={56}>
          <polygon
            fill="#FFFFFF"
            points="256.0,186.0 264.4,235.7 292.8,219.2 276.3,247.6 326.0,256.0 276.3,264.4 292.8,292.8 264.4,276.3 256.0,326.0 247.6,276.3 219.2,292.8 235.7,264.4 186.0,256.0 235.7,247.6 219.2,219.2 247.6,235.7"
          />
        </svg>
      </div>
      <div className="welcome-words">
        <p className="font-display text-4xl tracking-[0.02em] text-white">BRO PROTOCOL</p>
        <p className="mt-2 text-sm text-[#A8B0BF]">Say less. Say it right.</p>
      </div>
      <div className="welcome-bar" aria-hidden>
        <span />
      </div>
      <p className="welcome-skip">Tap to skip</p>
    </div>
  );
}
