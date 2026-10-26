---
doc: spec
status: draft
---

This draft follows the Devpost Learn `4-spec` template. It describes the implementation that is already in the repository on 26 October 2026. It was not produced by running `4-spec` as an interview, and it is not evidence that the skills built Plateful. The full technical record is [../spec.md](../spec.md).

# Plateful — Technical Spec

## How This Works, In Plain Language

Two programs. The phone app is Flutter. It draws the screens and keeps the kitchen in a SQLite file named `plateful.db` on the device. The second program is a small Node server on the computer. The phone sends it photos, meal-plan requests, and occasional recipe or image requests. The server asks OpenAI when `OPENAI_API_KEY` is set, and it asks image sites when those keys are set.

The phone does the pantry maths itself: merging names, deducting a cooked meal, and adding up rescued kilograms. The server does not store the pantry.

This split keeps API keys off the phone. The cost is that plan generation needs the computer server to be reachable.

## The Core Journey Through the System

PRD ref: `prd.md > The Core Journey`.

1. `lib/main.dart` opens the database, loads preferences, and shows Welcome, Onboarding, or the shell.
2. A photo is compressed, copied under the app documents folder `pantry_photos/`, and posted as multipart field `image` to `POST /api/analyse-image`.
3. The server sends the bytes to OpenAI chat completions with an image. Zod checks the JSON. The phone shows a confirm screen. Nothing is inserted until the cook taps Add to pantry. `PantryService.mergeIngredient` writes `ingredients`.
4. Generate plan posts JSON to `POST /api/generate-meal-plan`. The server calls the model once per day, fills gaps with template dishes, then `allocatePlan` builds the shopping list. The phone saves the plan JSON in `user_settings` under `meal_plan` and asks `GET /api/recipe-image` for photos.
5. Create 5 recipes does not call the server. `ChefShowcaseRecipes.forPantry` returns five bundled recipes. The shortlist is saved as `shortlist_v1`.
6. Mark as eaten writes `cooking_events` and `ingredient_usage_events`, and lowers `quantity_remaining`. `ImpactService.compute` reads those rows when Impact opens.
7. Close the app and open it again: the same SQLite file reloads pantry, plan, saves, and history.

## Stack

Versions are the ones locked in the repo. The installed Flutter binary version is not stored. `pubspec.lock` records Dart `>=3.13.5 <4.0.0` and Flutter `>=3.44.0`. `pubspec.yaml` asks for Dart SDK `^3.13.5`.

| Piece | Version in repo | Role | Docs |
|---|---|---|---|
| Flutter / Dart | SDK constraint above | Phone UI | https://docs.flutter.dev/ |
| provider | 6.1.5+1 | `AppState` | https://pub.dev/packages/provider |
| sqflite | 2.4.4+1 | On-device database | https://pub.dev/packages/sqflite |
| google_fonts | 6.3.3 | Figtree and Bricolage Grotesque | https://pub.dev/packages/google_fonts |
| http | 1.6.0 | Server calls | https://pub.dev/packages/http |
| camera | 0.12.1 | Pantry camera | https://pub.dev/packages/camera |
| Node.js | `engines` `>=18` | Server runtime | https://nodejs.org/ |
| Express | 4.22.3 | HTTP API | https://expressjs.com/ |
| openai | 4.104.0 | Chat completions client | https://platform.openai.com/docs/api-reference/chat |
| zod | 3.25.76 | Request and model JSON checks | https://zod.dev/ |
| TypeScript | 5.9.3 | Server language | https://www.typescriptlang.org/ |
| tsx | 4.23.15 | `npm run dev` | https://tsx.is/ |

The Flutter, Express, and OpenAI choices are already in the tree. This document does not record a learner agreeing to them during a planning interview. No successful live OpenAI response is checked in. Treat the model name as unverified until someone calls `/api/health` and a generate route against the configured account.

## Where It Runs and How Someone Tries It

The phone app is the demo surface. The API is a local process on port 3001, bound to `0.0.0.0`. There is no hosted deployment in the repo. A demo video and a public git repository are the hackathon submission. Deployment is optional and is not set up here.

Prerequisites: Flutter SDK matching the lockfile constraint, Node.js 18 or newer, and an Android phone or emulator. iOS project files exist. `ios/Runner/Info.plist` has camera and photo-library strings and does not add a cleartext HTTP exception, so a physical iPhone reaching `http://127.0.0.1:3001` was not verified.

Keys, names only, in `server/.env` copied from `server/.env.example`:

- `OPENAI_API_KEY` — required for live analysis and planning
- `OPENAI_MODEL` — optional; code default `gpt-6-luna`
- `SERP_API_KEY` — optional image search; `SERPAPI_API_KEY` is also read and is not in the example file
- `PEXELS_API_KEY` — optional
- `PORT` — optional, default 3001

Never put those keys in the Flutter app.

```bash
flutter pub get
cd server
npm install
npm run dev
```

Health: `http://127.0.0.1:3001/api/health`.

Android phone, from the repo root, with USB debugging:

```powershell
.\start-plateful.ps1
```

That script reverse-forwards port 3001 and runs `flutter run -d SM` with no dart-define. The app default base URL is `http://127.0.0.1:3001`. Emulator override:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

`DEMO_MODE=true` makes analyse and recipe generation use local samples. Meal plans still require a live server that reports OpenAI as configured.

Checks that exist:

```bash
flutter analyze
flutter test
cd server
npm run typecheck
```

## Look and Feel

PRD ref: `prd.md > Look and Feel`. Scope ref: `scope.md > Inspiration & Identity`.

Flutter Material, colors and type from `lib/theme/app_theme.dart`. Forest green is the primary action color. The floating nav is custom, not a Material bottom bar. `google_fonts` can fail on a device with no network; the README already notes that. Phosphor supplies icons. The theme cannot honour a system font choice the user never gets to set.

## Components

### App shell

`lib/shell/app_shell.dart` is an `IndexedStack`: Plan, camera import, Pantry. `AppState` in `lib/state/app_state.dart` is the single `ChangeNotifier`.

PRD ref: `prd.md > Screens and Layout`.

### Pantry services

`PantryService` merges ingredients, proposes deductions, and writes usage rows. `FoodFacts` supplies piece weights and fallback GBP prices.

PRD ref: `prd.md > Features and Behavior > Pantry`.

### Planner

`planner_setup_screen.dart` and `planner_pantry_select_screen.dart` build `MealPlanRequest`. `generateMealPlan` posts it. After a swap or delete, `lib/utils/plan_allocation.dart` rebuilds shopping rows on the phone.

PRD ref: `prd.md > Features and Behavior > Meal plan`.

### Showcase deck

`ChefShowcaseRecipes` plus `lib/widgets/swipe_deck.dart`. Persistence key `shortlist_v1`.

PRD ref: `prd.md > Features and Behavior > Showcase recipes and cooking`.

### Impact

`ImpactService.compute` is entirely on the phone. `impact_dashboard.dart` draws it and can share a screenshot.

PRD ref: `prd.md > Features and Behavior > Impact and Eating`.

### API server

`server/src/index.ts` registers every route. `openai.ts` calls the model. `mealPlan.ts` and `allocate.ts` shape the week. `nutrition.ts` replaces recipe macros. `images.ts` searches photos. `demo.ts` is the no-key payload for analyse and recipes.

PRD ref: `prd.md > The Core Journey`.

### Notifications

`NotificationService` uses `flutter_local_notifications`, timezone `Europe/London`, and `AndroidScheduleMode.inexactAllowWhileIdle`. `sync` cancels all, then reschedules from preferences.

PRD ref: `prd.md > Features and Behavior > Preferences and reminders`.

## Data Model

SQLite file `plateful.db`, schema version 6, under the app database directory.

| Table | Holds | Updated when |
|---|---|---|
| `ingredients` | Name, quantity, unit, expiry, place, value, photo path | Confirm, edit, cook |
| `recipes` | Cached recipe JSON, macros, optional asset path | Deck, plan hydrate, cook |
| `recipe_ingredients` | Created in schema | Not the path the app writes; ingredients are JSON on `recipes` |
| `saved_recipes` | Saved ids | Heart |
| `scan_sessions` | Unused | Never |
| `cooking_events` | Eaten meal, macros, `plan_key` | Mark eaten |
| `ingredient_usage_events` | Amount used, `was_near_expiry` | Mark eaten |
| `cooked_recipe_guards` | Last cook time per recipe | Mark eaten |
| `user_settings` | JSON by key | See below |

`user_settings` keys: `user_preferences`, `welcome_v1`, `onboarding_v1`, `meal_plan`, `shortlist_v1`, `graphs_reset_v2`.

Leaving the app does not clear these tables. Reset all graphs deletes usage, cooking events, cook guards, and `demo-recipe-%` rows. Pantry stock remains. Load demo week inserts about 14 days of demo cooks.

Photos are files in `pantry_photos/`, not blobs.

## File Structure

```
plateful/
├── lib/                  # Flutter UI, state, SQLite services
│   ├── main.dart
│   ├── config.dart
│   ├── data/             # database, demo samples, showcase recipes
│   ├── models/
│   ├── screens/
│   ├── services/         # API, pantry, impact, notifications, settings
│   ├── shell/
│   ├── state/app_state.dart
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── server/src/           # Express API
│   ├── index.ts
│   ├── openai.ts
│   ├── mealPlan.ts
│   ├── allocate.ts
│   ├── nutrition.ts
│   ├── images.ts
│   ├── schemas.ts
│   └── demo.ts
├── server/.env.example   # key names only
├── test/                 # two Dart test files
├── assets/images/        # showcase and splash images
├── devpost/              # these planning drafts
├── .agents/skills/       # installed Learn skill pack; not the app
├── start-plateful.ps1
├── pubspec.yaml
├── FEATURES.md
├── IMPACT.md
├── APP_REFERENCE.md
└── README.md
```

Omitted: `build/`, `.dart_tool/`, `server/node_modules/`, `server/dist/`, and `server/.env`.

## External Services and Dependencies

No rate-card or dollar cost is stored in the repo. OpenAI billing depends on the account. Image keys are optional.

| Call | Method | Input | Output | Key |
|---|---|---|---|---|
| `/api/health` | GET | none | `ok`, booleans, `model` name | none |
| `/api/analyse-image` | POST | multipart `image`, max 8 MB | ingredients, up to 3 questions, `isDemo` | OpenAI for a live read |
| `/api/generate-recipes` | POST | pantry JSON, optional preferences, `recipeCount` 1–8 | recipes, `isDemo` | OpenAI |
| `/api/generate-meal-plan` | POST | days 3/5/7, meals, people, pantry, preferences | days, shopping, pantry usage, `allergyWarning` | OpenAI |
| `/api/recipe-image` | GET | `q`, optional `mealType`, optional `exclude` | `imageUrl` | Serp and/or Pexels, else TheMealDB or a fixed Unsplash URL |

Upstream from the server:

- OpenAI chat completions, JSON object mode, model `process.env.OPENAI_MODEL` or `gpt-6-luna`. Vision uses a data-URL image. Docs: https://platform.openai.com/docs/api-reference/chat
- SerpAPI Google Images when a key is set. HTTP 429 starts a 90 second cooldown in `images.ts`. https://serpapi.com/search-api
- Pexels search when `PEXELS_API_KEY` is set. https://www.pexels.com/api/documentation/
- TheMealDB search, no key. https://www.themealdb.com/api.php

The server allows any CORS origin. It has no authentication.

## Important Failure Modes

- **Server unreachable** → analyse, recipe swap, and meal plan throw a message that names `start-plateful.ps1`. The deck still shows the five bundled meals if the pantry has cookable food. An empty pantry may be seeded at startup.
- **OpenAI key missing** → health sets `openaiConfigured` false. The phone refuses analyse, recipe, and meal-plan calls. The server itself would return demo analyse and demo recipes, and a template meal plan, but the phone does not accept the demo analyse or demo recipe bodies.
- **Quota or billing** → HTTP 402. The phone surfaces the error text. Meal plan does not silently switch to the template on quota errors.
- **Model returns bad JSON** → analyse and recipe routes respond 502. Meal-plan generation can substitute template dishes and still return 200 with `isDemo` false when a key was configured.
- **Image search has no acceptable hit** → a keyword Unsplash URL is used.

## What Was Simplified and Why

- **Five bundled recipes** instead of a live five-recipe model call on every swipe session. The model path remains for swapping one planned meal. A full deck would spend a generation on every "discover 5 more".
- **One CO₂e range** instead of a factor per ingredient. WRAP does not publish a single per-kilogram avoided-waste factor in the sources the app cites.
- **Confirm-then-save** instead of writing the model's guess straight into the pantry. The cook can fix the name and the date.
- **On-device SQLite** instead of an account database. The proof works on one phone without a login service.

## Decisions and Open Issues

No learner uncertainty was captured, because the planning interview was not run. That absence is stated here rather than filled in.

Observed implementation choices:

- Keys stay in `server/.env`. The phone only receives a base URL.
- Schema version 6 adds `fibre` on recipes and cooking events.
- Staples (salt, pepper, oil, water, sugar, flour) are skipped when the plan allocates shopping.
- Nutrition uses a static per-100 g table, Atwater kilocalories `round(4P + 4C + 9F)`, and per-serving caps (protein 80 g, carbohydrates 180 g, fat 90 g, fibre 40 g, calories 1200).

Carried from `prd.md > Open Questions`:

- `gpt-6-luna` is the default model string. Nothing in the repo proves the account accepts it.
- Course select does not change the showcase list.
- Hackathon process eligibility is outside this spec.
