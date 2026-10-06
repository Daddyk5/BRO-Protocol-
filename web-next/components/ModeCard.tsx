import Link from "next/link";

import type { ModeInfo } from "@/lib/modes";

interface ModeCardProps {
  mode: ModeInfo;
  /** Position on the grid; drives the stagger and the 1–6 shortcut hint. */
  index: number;
  primary?: boolean;
}

/**
 * Horizontal card: 44px tinted icon circle, title and subtitle. Hover lifts
 * 2px and the border takes the mode's accent; the primary card gets the
 * brand gradient border.
 */
export function ModeCard({ mode, index, primary = false }: ModeCardProps) {
  const Icon = mode.icon;
  const style = {
    ["--accent" as string]: mode.accent,
    animationDelay: `${index * 40}ms`,
  };

  const body = (
    <span className="flex h-full min-h-[88px] items-center gap-2 rounded-[15px] bg-surface p-4 sm:gap-4">
      <span
        aria-hidden
        className="flex size-11 shrink-0 items-center justify-center rounded-full"
        style={{ backgroundColor: `color-mix(in srgb, ${mode.accent} 15%, transparent)`, color: mode.accent }}
      >
        <Icon className="size-5" />
      </span>
      <span className="flex min-w-0 flex-col break-words">
        <span className="font-display text-xl leading-tight tracking-[0.02em] text-text">{mode.title}</span>
        <span className="text-sm text-muted">{mode.subtitle}</span>
      </span>
      <kbd
        aria-hidden
        className="ml-auto hidden self-start rounded-md border border-border px-2 text-xs text-muted lg:inline-block"
      >
        {index + 1}
      </kbd>
    </span>
  );

  return (
    <Link
      href={`/compose?mode=${mode.id}`}
      aria-label={`${mode.title}: ${mode.subtitle}`}
      aria-keyshortcuts={String(index + 1)}
      style={style}
      className={
        "motion-card animate-fade-up theme-fade block min-w-0 rounded-2xl card-shadow transition-[transform,border-color,background-color] duration-200 hover:-translate-y-0.5 active:scale-[0.98] " +
        (primary
          ? "bg-brand-gradient col-span-2 p-[2px] md:col-span-1"
          : "border border-border hover:border-[var(--accent)] [&>span]:rounded-[15px]")
      }
    >
      {body}
    </Link>
  );
}
