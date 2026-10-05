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
- **Modes:** Opener, Banter, Move it off-app, Revive, Late Night (smooth, slow-burn flirting)
- **Composer:** paste a chat or scan a screenshot (on-device OCR with ML Kit), then generate **3 options** (Chill, Balanced, Bold) or turn that off and pick one tone
- **Result:** tap the option you like, then Copy, Regenerate or Share
- **History:** the last 20 replies, stored only on the device
- **Settings:** default tone, language (English / Taglish), clear history
- **Android share:** in Messenger, Share a message to Bro Protocol and it opens in Banter

**Extension**
- A popup with the same modes and tone
- A floating button on messenger.com and Facebook Dating that reads recent messages, generates a reply and inserts it. It never presses Enter.
- Right-click selected text → "Bro Protocol: reply to this"

## Backend API

`POST /generateReply` (Docker) or the `generateReply` callable (Firebase), using the same wire format:

```
request  { data: { mode: "OPENER" | "BANTER" | "MOVE_OFF_APP" | "REVIVE" | "LATE_NIGHT",
                   context: string (≤ 5000 chars), tone: 0..1,
                   language: "english" | "taglish", deviceId: string,
                   count?: 1..3 } }
response { result: { reply: string,
                     replies: [{ label: "Chill" | "Balanced" | "Bold", tone: number, reply: string }] } }
```

- **Options:** `count: 3` writes Chill, Balanced and Bold replies in parallel (ignoring `tone`); `reply` is the Balanced one. With `count: 1` (the default), you get one reply at `tone`.
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

## Notes

- **Release builds need HTTPS.** Put the Docker backend behind a TLS proxy (Caddy, Cloudflare Tunnel) or a host such as Cloud Run or Fly.io. The iOS `Info.plist` currently allows plain HTTP for local testing; tighten it before an App Store release.
- **Icons:** after editing `assets/logo/bro_logo.svg`, run `cd tool && npm run icons`, then `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
- **Windows:** `android/gradle.properties` sets `kotlin.incremental=false` so builds work when the pub cache and the project are on different drives.
- **iOS share sheet:** this needs a Share Extension target added in Xcode (see the `receive_sharing_intent` docs).
- **Messenger reading** is best-effort, so the extension lets you edit the captured text before generating.
