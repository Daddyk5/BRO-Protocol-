"use client";

import Link from "next/link";
import type { LucideIcon } from "lucide-react";

interface IconButtonProps {
  icon: LucideIcon;
  label: string;
  href?: string;
  onClick?: () => void;
  active?: boolean;
}

/** A 44px icon button (or link) with an aria-label and a hover/focus tooltip. */
export function IconButton({ icon: Icon, label, href, onClick, active = false }: IconButtonProps) {
  const className =
    "theme-fade group relative inline-flex size-11 items-center justify-center rounded-full border " +
    (active ? "border-border bg-surface text-text" : "border-transparent text-muted hover:bg-surface hover:text-text");

  const content = (
    <>
      <Icon aria-hidden className="size-5" />
      <span
        role="tooltip"
        className="pointer-events-none absolute top-full right-0 z-20 mt-2 rounded-lg border border-border bg-surface px-2 py-1 text-xs whitespace-nowrap text-text opacity-0 card-shadow transition-opacity duration-200 group-hover:opacity-100 group-focus-visible:opacity-100"
      >
        {label}
      </span>
    </>
  );

  return href ? (
    <Link href={href} aria-label={label} aria-current={active ? "page" : undefined} className={className}>
      {content}
    </Link>
  ) : (
    <button type="button" aria-label={label} onClick={onClick} className={className}>
      {content}
    </button>
  );
}
