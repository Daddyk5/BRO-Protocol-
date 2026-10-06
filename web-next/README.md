# Bro Protocol — web (Next.js)

A React/Next.js + Tailwind front end for Bro Protocol. It talks to the same backend as the Flutter app (`../server`, Docker) and keeps everything else (history, saved replies, profiles, theme) in the browser's localStorage.

## Run

```bash
cp .env.example .env.local   # NEXT_PUBLIC_BRO_BACKEND_URL=http://localhost:8080
npm install
npm run dev                  # http://localhost:3000
```

The backend must be running (`docker compose up -d` in the repo root). Its CORS policy already allows browser calls.

`npm run build` makes a production build; `npm run typecheck` runs TypeScript.

## Structure

```
app/
  layout.tsx        fonts, <head> theme script (no flash), Header + BottomNav
  page.tsx          Home: quick paste, Continue row, mode grid, stats strip, tip banner, shortcuts
  compose/          pick a mode, paste, generate 1 or 3 options, copy / save
  history/          recent conversations and saved replies
  profiles/         match names + notes, used as context when composing
  settings/         System / Light / Dark
components/
  ThemeProvider     theme state, persists to localStorage, follows the OS on "System"
  ThemeToggle       header sun/moon button + ThemeSegmented for Settings
  Header, BottomNav header icons from 640px up; bottom tab bar below that
  QuickPaste, ContinueRow, ModeCard, ModeGrid, StatsStrip, InfoBanner, IconButton
lib/
  modes.ts          the six Home modes (+ Opener in the composer) with accent colors
  api.ts            POST /generateReply
  data.ts, storage.ts  localStorage helpers (guarded: the app works if storage is blocked)
```

## Design notes

- Colors are CSS variables on `:root` (light) and `[data-theme="dark"]`, exposed to Tailwind as `bg-bg`, `bg-surface`, `border-border`, `text-text`, `text-muted`.
- An inline script in `<head>` sets `data-theme` before first paint, so there's no flash of the wrong theme.
- Keyboard: `1`–`6` open the modes (when you're not typing), `Ctrl`/`⌘`+`K` focuses quick paste, `Ctrl`/`⌘`+`Enter` submits it.
- `prefers-reduced-motion` turns off the entrance stagger, hover lift and press scale.
- White text on the brand gradient is about 4.1:1 at the pink end, so gradient buttons use large text (24px display or 20px bold) to meet WCAG AA.
- At 360px the mode cards' text wraps, so cards grow taller than 88px; nothing scrolls horizontally.
