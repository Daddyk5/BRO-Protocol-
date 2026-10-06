"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { House } from "lucide-react";

import { NAV_LINKS } from "./Header";

const TABS = [{ href: "/", label: "Home", icon: House }, ...NAV_LINKS];

/** Phones only (<640px): fixed tab bar with labels. */
export function BottomNav() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="Main"
      className="theme-fade fixed inset-x-0 bottom-0 z-30 border-t border-border bg-surface pb-[env(safe-area-inset-bottom)] sm:hidden"
    >
      <ul className="mx-auto grid max-w-[640px] grid-cols-4">
        {TABS.map(({ href, label, icon: Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <li key={href}>
              <Link
                href={href}
                aria-current={active ? "page" : undefined}
                className={
                  "theme-fade flex min-h-14 flex-col items-center justify-center gap-1 text-xs font-medium " +
                  (active ? "text-text" : "text-muted")
                }
              >
                <Icon aria-hidden className="size-5" />
                {label}
                <span
                  aria-hidden
                  className={"h-0.5 w-6 rounded-full " + (active ? "bg-brand-gradient" : "bg-transparent")}
                />
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
