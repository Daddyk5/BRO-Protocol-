# BRO PROTOCOL

**Say less. Say it right.**

An AI wingman that writes one dating-chat reply at a time: confident, warm, witty, never needy. Nothing is ever sent for you. The app copies, the extension pastes, and you hit send.

| Part | Folder | Stack |
| --- | --- | --- |
| App (Android, iOS, web) | `lib/`, `android/`, `ios/`, `web/` | Flutter 3.47, Riverpod, go_router, dio, Hive |
| Backend (pick one) | `server/` or `functions/` | Docker (Node) or Firebase Cloud Functions v2. Both TypeScript and Claude API, sharing the same logic |
| Chrome extension | `extension/` | Manifest V3, TypeScript, Vite |

## Contents

- [Requirements](#requirements)
- [Quick start (Docker backend + Android)](#quick-start-docker-backend--android)
- [Run on iPhone without a Mac](#run-on-iphone-without-a-mac)
- [Firebase backend (alternative)](#firebase-backend-alternative)
- [Chrome extension](#chrome-extension)
- [Features](#features)
- [Backend API](#backend-api)
- [Project structure](#project-structure)
- [Notes](#notes)

## Requirements

- Flutter 3.47+ (Dart 3.13+)
- Android SDK platform 37: `sdkmanager "platforms;android-37.0"`
- Node.js 22
- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com)
- Docker Desktop (Docker backend) **or** the Firebase CLI plus a Blaze-plan project (Firebase backend)

## Quick start (Docker backend + Android)

**1. Start the backend**

```bash
cp server/.env.example server/.env    # set ANTHROPIC_API_KEY
docker compose up -d --build
curl http://localhost:8080/healthz          # {"ok":true}
curl "http://localhost:8080/healthz?deep=1"  # also checks the model is reachable
```

**Free local model (Ollama):** with [Ollama](https://ollama.com) running (`ollama pull llama3.2:3b`), set these in `server/.env`:

```bash
OLLAMA_URL=http://host.docker.internal:11434   # use http://localhost:11434 outside Docker
OLLAMA_MODEL=llama3.2:3b                       # any model from `ollama list`
```

| `server/.env` has | Replies come from |
| --- | --- |
| `ANTHROPIC_API_KEY` only | Claude |
| `OLLAMA_URL` only | Ollama |
| both | Ollama first; Claude takes over when Ollama is down or keeps breaking the rules |

Ollama only works with the Docker backend; the Firebase function always uses Claude. Small local models write noticeably weaker replies than Claude.

Rate-limit counters are saved to a Docker volume (`RATE_LIMIT_FILE`), so restarting the container doesn't reset them.

**2. Run the app**

```bash
flutter pub get

# Android emulator (10.0.2.2 is your PC's localhost)
flutter run --dart-define=BRO_BACKEND_URL=http://10.0.2.2:8080

# Physical phone on the same Wi-Fi: use your PC's LAN IP
flutter run --dart-define=BRO_BACKEND_URL=http://192.168.x.x:8080
```

If the server sets `CLIENT_TOKEN`, add `--dart-define=BRO_CLIENT_TOKEN=<token>`. When `BRO_BACKEND_URL` is set, the app skips Firebase entirely.

**Or run it in the browser** (no phone needed):

```bash
flutter run -d chrome --dart-define=BRO_BACKEND_URL=http://localhost:8080   # or -d edge
flutter build web --release --dart-define=BRO_BACKEND_URL=https://<your-backend>   # output: build/web
```

On web, screenshot scanning is hidden (ML Kit is mobile-only) and the share sheet isn't available. Everything else works the same. A deployed site served over HTTPS needs an HTTPS backend URL, because browsers block `http://` calls from `https://` pages.

To reach the backend from a phone, allow port 8080 through Windows Firewall:

```powershell
New-NetFirewallRule -DisplayName "Bro backend 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

## Run on iPhone without a Mac

Flutter can only build iOS apps on macOS. From Windows, build in the cloud with [Codemagic](https://codemagic.io), then sideload the app.

1. In Codemagic, add this repo. Create an environment variable group `bro_backend` with `BRO_BACKEND_URL` set to your backend, e.g. `http://192.168.x.x:8080`.
2. Run the **iOS unsigned IPA** workflow from [`codemagic.yaml`](codemagic.yaml) and download `bro_protocol.ipa`.
3. On Windows, install iTunes (from apple.com) and [Sideloadly](https://sideloadly.io). Connect the iPhone, drop in the `.ipa`, and sign in with your Apple ID.
4. On the iPhone, enable **Settings → Privacy & Security → Developer Mode**. Then trust your Apple ID under **Settings → General → VPN & Device Management**, and allow local network access when the app asks.

With a free Apple ID, the app expires after 7 days; re-sign it with Sideloadly. A paid Apple Developer account lets you ship through TestFlight instead.

**With a Mac:** `cd ios && pod install`, select your signing team in `ios/Runner.xcworkspace`, then `flutter run`.

## Firebase backend (alternative)

Use this instead of Docker if you want App Check, Firestore-backed rate limits and managed hosting.

**1. Firebase Console**
- Create a **Firestore** database (production mode).
- Turn on **Authentication → Anonymous**. Only the extension uses it.
- In **App Check**, register Android with Play Integrity (add your SHA-256) and iOS with App Attest.

**2. Connect the app**

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android,ios,web
```

This replaces the stand-in `lib/firebase_options.dart`.

**3. Deploy**

```bash
firebase use --add
firebase functions:secrets:set ANTHROPIC_API_KEY
cd functions && npm install && firebase deploy --only functions
firebase deploy --only firestore:rules
```

**4. Run** `flutter run`. Debug builds print an App Check debug token on first launch. Add it under App Check → Manage debug tokens, or calls fail with "This build isn't verified."

For a local emulator, run `firebase emulators:start --only functions,firestore`, then:

```bash
flutter run --dart-define=FUNCTIONS_BASE_URL=http://10.0.2.2:5001/<project-id>/us-central1
```

The model defaults to `claude-opus-5-5`. To change it, set `LLM_MODEL` (on Docker, `CLAUDE_MODEL`).

## Chrome extension

```bash
cd extension
cp .env.example .env    # Docker: VITE_BRO_BACKEND_URL=http://localhost:8080
                        # Firebase: VITE_FIREBASE_API_KEY + VITE_FIREBASE_PROJECT_ID
npm install
npm run build
```

Open `chrome://extensions`, turn on Developer mode, click **Load unpacked**, and select `extension/dist`.

## Features

**Mobile app**
- **Onboarding:** three intro screens, then an 18+ check and agreement to the Terms and Privacy Policy. Shown on first launch, and again whenever `AppConstants.termsVersion` is bumped
- **Modes:** Opener, Banter, Move it off-app, Revive, Late Night (smooth, slow-burn flirting), **Fix my draft** (paste what you were going to send, get it back sharper) and **Date ideas** (three date asks built from what she's mentioned: Low-key, Activity, Evening)
- **Composer:** paste a chat or scan a screenshot (on-device OCR with ML Kit), pick who it's **for**, then generate **3 options** (Chill, Balanced, Bold) or turn that off and pick one tone
- **Result:** tap the option you like, then Copy, Regenerate or Share. A **"Why it works"** tip explains each reply (turn it off in Settings)
- **Rework a reply:** one tap on **Shorter, Funnier, Bolder, Softer** or **+ Question** rewrites just the picked option. **Edit** lets you change it by hand before copying
- **Saved:** star any reply to keep it on the Saved screen, separate from History (which keeps the last 20)
- **Your stats:** replies left this hour (reported by the backend), replies this week and all time, active days and your top plays, all counted on the device
- **Matches:** save notes about each match (interests, plans, inside jokes). Pick her in the composer and replies can use one detail. Notes stay on the device and are only sent with that request
- **History:** the last 20 replies, stored only on the device
- **Settings:** default tone, language (English / Taglish), **your style** (how you text, allow emoji, short replies), tips on/off, haptic feedback, Help & FAQ, Privacy Policy, Terms of Use, replay the intro, clear history, and **Delete all my data** (history, match notes, settings and install ID)
- **Help & FAQ:** how it works, every mode, common questions, and a support contact
- **Polish:** content is centred at 640 px on tablets, desktop and the web; a friendly "can't connect" screen replaces a blank page when the backend isn't configured; unknown links show a "Nothing here" page
- **Android share:** in Messenger, Share a message to Bro Protocol and it opens in Banter

**Extension**
- A popup with the same modes and tone
- A floating button on messenger.com and Facebook Dating that reads recent messages, generates a reply and inserts it. It never presses Enter.
- Right-click selected text → "Bro Protocol: reply to this"

## Backend API

`POST /generateReply` (Docker) or the `generateReply` callable (Firebase), using the same wire format:

```
request  { data: { mode: "OPENER" | "BANTER" | "MOVE_OFF_APP" | "REVIVE" | "LATE_NIGHT"
                         | "IMPROVE_DRAFT" | "DATE_IDEAS",
                   context: string (≤ 5000 chars), tone: 0..1,
                   language: "english" | "taglish", deviceId: string,
                   count?: 1..3, tips?: boolean, notes?: string (≤ 1000 chars),
                   prefs?: { emoji?: boolean, short?: boolean, style?: string (≤ 300 chars) },
                   tweak?: "SHORTER" | "FUNNIER" | "BOLDER" | "SOFTER" | "ADD_QUESTION",
                   previous?: string (required with tweak, ≤ 600 chars) } }
response { result: { reply: string,
                     replies: [{ label: string, tone: number, reply: string, tip?: string }],
                     quota: { remaining: number, limit: number, resetAt: number /* epoch ms */ } } }
```

- **Options:** `count: 3` writes Chill, Balanced and Bold replies in parallel (ignoring `tone`); `reply` is the Balanced one. In `DATE_IDEAS` the three options are date types (Low-key, Activity, Evening) at the caller's `tone` instead. With `count: 1` (the default), you get one reply at `tone`.
- **Tips:** `tips: true` asks for a one-line "why this works" in the same model call, so it costs no extra request. Small local models sometimes skip it; the reply still comes back.
- **Notes:** `notes` is added to the prompt as "Notes about her", and the model is told to use at most one detail.
- **Preferences:** `prefs.style` is passed as the user's own texting style; `short` keeps one sentence; `emoji: false` tells the model to skip emoji and strips any that slip through.
- **Tweaks:** `tweak` + `previous` rewrites an existing reply instead of writing a new one (always one reply, one unit of quota).
- **Quota:** every successful response says how many replies are left in the current hour.
- **Rate limit:** 20 replies per hour per device, so a 3-option request uses 3. Docker saves the counts to a file; Firebase keeps them in Firestore.
- **Auth:** Docker uses an optional shared `CLIENT_TOKEN`. Firebase requires an App Check token (app) or an anonymous Firebase Auth token (extension).
- **Post-processing:** strips quotes, keeps at most 2 sentences, and regenerates once if a banned word appears (and fails if the retry still has one).
- **Privacy:** logs record the mode, language and character counts, never chat content.

Run the tests with `npm test` in `server/` or `functions/`, and with `flutter test` for the app.

## Project structure

```
lib/
  core/          constants, theme, shared widgets
  features/      splash, home, composer, history, settings
  services/      API, OCR, share intent
server/          Docker backend (reuses functions/src core logic)
functions/src/   Cloud Function + shared prompt, LLM, validation, post-processing
extension/src/   popup, content script, background worker
assets/logo/     SVG logo (source of truth)
tool/            renders all icons from the SVG: npm run icons
codemagic.yaml   cloud iOS build
```

## Before a public release

- **Support email:** build with `--dart-define=SUPPORT_EMAIL=you@yourdomain.com`. It appears in Help, the Privacy Policy and the Terms. The default is a placeholder (`support@example.com`).
- **Legal text:** the Privacy Policy and Terms in `lib/features/legal/legal_text.dart` are plain-language drafts that match what the app does today. Have them reviewed for the countries you launch in, and keep them in sync when data handling changes. App stores also want the privacy policy at a public URL.
- **Terms changes:** bump `AppConstants.termsVersion` so every user sees onboarding and accepts again.

## Notes

- **Release builds need HTTPS.** Put the Docker backend behind a TLS proxy (Caddy, Cloudflare Tunnel) or a host such as Cloud Run or Fly.io. The iOS `Info.plist` currently allows plain HTTP for local testing; tighten it before an App Store release.
- **Icons:** after editing `assets/logo/bro_logo.svg`, run `cd tool && npm run icons`, then `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
- **Windows:** `android/gradle.properties` sets `kotlin.incremental=false` so builds work when the pub cache and the project are on different drives.
- **iOS share sheet:** this needs a Share Extension target added in Xcode (see the `receive_sharing_intent` docs).
- **Messenger reading** is best-effort, so the extension lets you edit the captured text before generating.
