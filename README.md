# Plateful

AI-powered food waste reduction app — photograph your ingredients, get five distinct recipes, swipe to shortlist, cook, and watch your pantry + impact update.

Built with **Flutter** (mobile) and a **Node.js + Express + TypeScript** backend using **OpenAI**.

## Requirements

- Flutter 3.24+ (Dart SDK ^3.13)
- Node.js **18+**
- Android emulator or device
- (Optional) OpenAI API key for live AI
- (Optional) Pexels API key for dish photography

## Project structure

```
plateful/
├── lib/                 # Flutter app
├── server/              # Express AI backend
├── assets/images/       # Bundled images
├── test/                # Unit tests
└── README.md
```

## Environment variables

### Backend — `server/.env`

Copy from the example:

```bash
cd server
copy .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `OPENAI_API_KEY` | For live AI | OpenAI API key (vision + chat) |
| `OPENAI_MODEL` | No | Default `gpt-4o-mini` |
| `PEXELS_API_KEY` | No | Recipe photo search |
| `PORT` | No | Default `3001` |

Without `OPENAI_API_KEY`, the server returns realistic **demo** analyse + recipe payloads.

You can copy `OPENAI_API_KEY` from the project root `.env` into `server/.env` (keys must live on the backend only).

**Never put API keys in the Flutter app.** Keys stay on the backend only.

### Flutter dart-defines

| Define | Default | Description |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:3001` | Backend URL (Android emulator → host) |
| `DEMO_MODE` | `false` | Force offline demo pipeline in the app |

Physical device: use your machine’s LAN IP, e.g. `http://192.168.1.20:3001`.

## Install

```bash
# Flutter deps
flutter pub get

# Backend deps
cd server
npm install
cd ..
```

## Start the backend

```bash
cd server
npm run dev
```

Health check: [http://localhost:3001/api/health](http://localhost:3001/api/health)

## Launch on Android emulator

1. Start an Android Virtual Device from Android Studio.
2. Start the backend (`npm run dev` in `server/`).
3. From the project root:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

### Force demo mode (no backend / no keys)

```bash
flutter run --dart-define=DEMO_MODE=true
```

The app also falls back to demo data automatically if the API is unreachable.

> Android emulators cannot reach the host via `localhost`. Use `10.0.2.2`.

After adding native plugins, prefer a **full restart** (not only hot reload):

```bash
flutter stop
flutter clean
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

## Demo mode vs live AI

| Mode | When | Behaviour |
|---|---|---|
| **Demo** | `DEMO_MODE=true`, no OpenAI key, or API down | Sample Eggs/Tomatoes/Spinach/Cheese/Bread · 0–1 clarification · 5 recipes · full Cooked It → pantry → impact |
| **Live** | OpenAI configured + API reachable | Real image analysis + recipe generation; Pexels images when configured |

Demo data is lightly labelled in the UI.

## Primary user journey

1. App opens on **AI Chef**
2. Tap the central **Scan** camera tab
3. Take / pick one photo of ingredients
4. AI analyses (demo or OpenAI) → 0–3 clarification questions
5. Ingredients merge into **My Pantry**
6. Five recipe cards appear on AI Chef — swipe right to shortlist, left to skip
7. Heart saves permanently to **Saved Recipes**
8. After five cards → **Your picks.**
9. Open a recipe → **Cooked It!** → confirm deductions
10. Pantry quantities, usage history, and **My Impact** update

Also: **My Pantry → Cook with my pantry** regenerates five recipes from current stock.

## Tests & checks

```bash
flutter analyze
flutter test

cd server
npm run typecheck
```

## Troubleshooting

| Issue | Fix |
|---|---|
| `MissingPluginException` / path_provider | Full stop app, `flutter clean`, rebuild (hot restart is not enough for new plugins) |
| Emulator cannot reach API | Use `10.0.2.2`, ensure server listens on `0.0.0.0:3001` |
| Cleartext HTTP blocked | Debug manifest sets `usesCleartextTraffic=true` |
| Camera permission denied | Grant camera in emulator Settings |
| OpenAI errors / empty JSON | App/server fall back to demo responses |
| google_fonts network errors | Emulator needs internet on first font fetch |

## Out of scope (MVP)

Authentication, onboarding, social features, grocery delivery, notifications, subscriptions, full profile settings.
