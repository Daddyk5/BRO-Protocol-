import type { Metadata, Viewport } from "next";
import { Bebas_Neue, Inter } from "next/font/google";

import { BottomNav } from "@/components/BottomNav";
import { Header } from "@/components/Header";
import { ThemeProvider, themeInitScript } from "@/components/ThemeProvider";

import "./globals.css";

const bebas = Bebas_Neue({ weight: "400", subsets: ["latin"], variable: "--font-bebas", display: "swap" });
const inter = Inter({ subsets: ["latin"], variable: "--font-inter", display: "swap" });

export const metadata: Metadata = {
  title: "Bro Protocol",
  description: "An AI wingman that writes dating-chat replies. Say less. Say it right.",
  icons: { icon: "/logo.svg" },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#F6F7FA" },
    { media: "(prefers-color-scheme: dark)", color: "#0B0D12" },
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // data-theme is set by the inline script before React hydrates.
    <html lang="en" className={`${bebas.variable} ${inter.variable}`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="min-h-dvh">
        <ThemeProvider>
          <a
            href="#main"
            className="sr-only z-50 rounded-lg bg-surface px-4 py-2 text-text focus:not-sr-only focus:fixed focus:top-2 focus:left-2"
          >
            Skip to content
          </a>
          <Header />
          <main id="main" className="mx-auto w-full max-w-[1100px] px-4 pt-6 pb-24 sm:px-8 sm:pb-12">
            {children}
          </main>
          <BottomNav />
        </ThemeProvider>
      </body>
    </html>
  );
}
