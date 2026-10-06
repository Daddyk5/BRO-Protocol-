"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { History, Settings, Users } from "lucide-react";

import { IconButton } from "./IconButton";
import { ThemeToggle } from "./ThemeToggle";

export const NAV_LINKS = [
  { href: "/profiles", label: "Profiles", icon: Users },
  { href: "/history", label: "History", icon: History },
  { href: "/settings", label: "Settings", icon: Settings },
] as const;

/**
 * Logo + wordmark on the left; theme toggle and (from 640px up) Profiles,
 * History and Settings on the right. On phones those three live in BottomNav.
 */
export function Header() {
  const pathname = usePathname();
  return (
    <header className="theme-fade sticky top-0 z-30 border-b border-border bg-bg/90 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-[1100px] items-center justify-between gap-4 px-4 sm:px-8">
        <Link href="/" aria-label="Bro Protocol home" className="flex min-h-11 items-center gap-2 rounded-lg">
          <Image src="/logo.svg" alt="" width={32} height={32} priority />
          <span className="font-display text-xl tracking-[0.02em] text-text">BRO PROTOCOL</span>
        </Link>
        <nav aria-label="Main" className="flex items-center gap-2">
          <ThemeToggle />
          <div className="hidden items-center gap-2 sm:flex">
            {NAV_LINKS.map((link) => (
              <IconButton key={link.href} {...link} active={pathname.startsWith(link.href)} />
            ))}
          </div>
        </nav>
      </div>
    </header>
  );
}
