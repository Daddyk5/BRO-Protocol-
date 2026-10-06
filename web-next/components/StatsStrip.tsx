"use client";

import Link from "next/link";
import { Star, TrendingUp } from "lucide-react";

import { repliesThisWeek, type SavedReply, type UsageEvent } from "@/lib/data";
import { KEYS, useStoredState } from "@/lib/storage";

/** One slim line under the grid: saved count and replies this week. */
export function StatsStrip() {
  const [saved, , savedReady] = useStoredState<SavedReply[]>(KEYS.saved, []);
  const [events, , eventsReady] = useStoredState<UsageEvent[]>(KEYS.events, []);
  if (!savedReady || !eventsReady) return <div aria-hidden className="h-11" />;

  const week = repliesThisWeek(events);

  return (
    <div className="theme-fade flex min-h-11 flex-wrap items-center gap-x-4 gap-y-2 border-y border-border py-2 text-sm text-muted">
      <Link href="/history#saved" className="inline-flex min-h-11 items-center gap-2 rounded-lg hover:text-text">
        <Star aria-hidden className="size-4" />
        {saved.length === 0 ? "Star a reply to save it here" : `Saved: ${saved.length}`}
      </Link>
      <span aria-hidden className="hidden h-4 w-px bg-border sm:block" />
      <span className="inline-flex min-h-11 items-center gap-2">
        <TrendingUp aria-hidden className="size-4" />
        {week === 0 ? "No replies yet this week" : `This week: ${week}`}
      </span>
    </div>
  );
}
