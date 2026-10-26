# Plateful — Project Scope

This document says what the current proof of concept includes and what it leaves out. Behaviour is taken from the repository as of 26 October 2026. Where [README.md](README.md), [FEATURES.md](FEATURES.md), or [APP_REFERENCE.md](APP_REFERENCE.md) disagree with the code, the code is the source of truth and the disagreement is named.

Companion drafts that follow the Devpost Learn templates live in [devpost/scope.md](devpost/scope.md), [devpost/prd.md](devpost/prd.md), and [devpost/spec.md](devpost/spec.md). Those drafts were filled from this repository. The `1-start` interview was not run, and these files are not evidence that the skill pack built the app. Requirement detail is in [prd.md](prd.md). Implementation detail is in [spec.md](spec.md).

## 1. Project Overview

**Name:** Plateful

**One sentence:** Plateful is a Flutter phone app and a local Node server that turn a photographed pantry into a meal plan, a short cooking list, and a record of food used before it expires.

**Vision:** A home cook should be able to see what they already bought, cook from it, and tell the difference between food used in time and food that merely got eaten.

**Intended outcome:** A working proof that pantry rows persist on the phone, a week of named meals can be generated when OpenAI is configured, cooking reduces quantities, and Impact counts only the uses that were inside the cook's expiry window.

**What this proof demonstrates:**

- Welcome, onboarding, and food preferences stored on the device.
- Camera, gallery, and typed pantry entry, with a confirm step before save.
- Image analysis and multi-day meal plans through `server/` when `OPENAI_API_KEY` is set.
- A five-card cooking deck of fixed dishes, saved recipes, cook mode, and pantry deduction.
- Impact (rescued kilograms and a CO₂e range) and Eating (macros), calculated on the phone.
- Local expiry, plan, shopping, and prep notifications.

It does not demonstrate accounts, grocery checkout, or a swipe deck that invents new recipes from the current pantry.

## 2. Problem Statement

Food bought for home cooking often sits until it is no longer worth using. A usual recipe app starts from a dish the cook feels like making, not from the half-used bag in the fridge, and it does not write down that the bag was finished. A notes app can list ingredients, but it does not turn that list into a week of meals or a deduction when dinner is cooked.

Plateful addresses that practical gap: keep the stock, attach meals to it, and record whether the food was used while the cook still considered it close to expiry. The app does not claim to measure national food waste, and it does not cite a statistic beyond the WRAP ratios already used for its carbon range in [IMPACT.md](IMPACT.md).

## 3. Target Audience

### Home cook with a real fridge

They shop, they mean to use the spinach, and they forget. They would use Plateful because the pantry is the starting point for the plan and because marking a meal eaten changes the quantities.

### Cook with hard food rules

They need allergies, a diet style, and optional Halal or Kosher recorded once. They would use Plateful because those choices are sent with the meal-plan request. The five showcase recipes do not apply those rules. That limit is described in [prd.md](prd.md).

### Someone showing the proof

They need charts that are not empty. Settings can load about two weeks of demo cooks without pretending those cooks were a live scan.

These groups are inferred from the screens that exist. They are not interview transcripts.

## 4. Proposed Solution

The cook opens Plateful on the Plan tab. The first time, they pass a welcome screen and a short onboarding for name, allergies, and diet. They photograph ingredients, or type a name, and correct the draft: quantity, unit, expiry, and fridge, freezer, cupboard, or counter. Only then is the row saved. The same name adds to the existing quantity.

From Plan they choose how many days and which meals, then the whole pantry, selected items, or none. The phone asks the local server for a timetable of specific dishes and a shopping list for what the plan still needs. From the pantry they can also open five fixed recipes, shortlist them, and save the ones they want again.

Cooking is either a paged cook mode or an immediate "mark as eaten". The app proposes how much of each matching pantry item to remove. If the item was inside the reminder window, that use is stored as near-expiry. Impact adds those quantities up in kilograms and shows a carbon range. Eating adds the calories and macros of every meal marked eaten, whether or not the food was near expiry.

The phone keeps working for pantry edits, the showcase deck, and Impact when the server is down, as long as cookable food is already stored. Creating a new plan, reading a new photo, and swapping one planned dish for a generated recipe need the server and a configured OpenAI key.

## 5. Project Objectives

Each objective can be checked against the build.

1. **Persist a pantry without an account.** Confirmed ingredients, preferences, the current plan, and cook history remain in on-device SQLite after the process is killed. Evidence: `lib/data/database.dart`.
2. **Let the cook correct a scan before it counts.** Detected items are drafts until Add to pantry. Evidence: `lib/screens/pantry_confirm_screen.dart`.
3. **Generate a multi-day plan from stock when AI is configured.** `POST /api/generate-meal-plan` returns days of named meals. Evidence: `server/src/mealPlan.ts`, `lib/services/api_client.dart`.
4. **Reduce stock when a meal is marked eaten.** Matching quantities fall and a usage row is written. Evidence: `lib/services/pantry_service.dart`.
5. **Count rescued food with one rule.** Only uses flagged near-expiry at cook time, using the cook's 3-, 5-, 7-, or 14-day window, enter the kilogram total. Evidence: `lib/services/impact_service.dart`, [IMPACT.md](IMPACT.md).
6. **Keep waste and nutrition apart.** Impact and Eating are separate pantry segments. Evidence: `lib/screens/pantry_screen.dart`.
7. **Run the API without putting keys in the app.** The Flutter project reads `API_BASE_URL` and `DEMO_MODE` only. Evidence: `lib/config.dart`.

## 6. Minimum Viable Product (MVP)

The smallest version that delivers the kernel is the build that is already here, with these pieces treated as essential:

**Essential features**

- On-device pantry with confirm-before-save.
- Photo analysis when the server and OpenAI key are available.
- A 3-, 5-, or 7-day plan from that pantry.
- Mark eaten, with deduction and a near-expiry flag.
- Impact kilograms and the Eating totals.
- A way to show Impact without a week of real cooking (Load demo week).

**Primary user journey**

Welcome → onboarding → add and confirm food → generate a plan → open a meal → mark eaten → Impact updates if the food was inside the window.

**Required integrations**

- Local Express server.
- OpenAI chat completions for live analyse and plan generation.
- SQLite on the phone.
- Image search is helpful and not required: the plan still returns if photos fall back to fixed Unsplash URLs.

**Expected outputs**

- Pantry rows with quantity, unit, place, and optional expiry.
- A timetable of named dishes plus a shopping list.
- A rescued-kilogram total and a CO₂e range after a qualifying cook.
- Macro totals on Eating.

**MVP completion criteria**

- A confirmed ingredient is still present after restart.
- With a configured key, a photo produces an editable draft and a plan request returns days of meals.
- Marking a near-expiry meal eaten lowers quantity and increases rescued kilograms.
- With no key, the phone explains that OpenAI is not configured instead of silently presenting server demo detections as a real scan.
- The five showcase recipes can be cooked from an existing pantry. They are part of the product the user can open. They are not the AI plan.

## 7. In-Scope Features

| Feature | Description | User Benefit | Implementation Status | Evidence |
|---|---|---|---|---|
| Welcome | First-launch splash with Get started | A clear entry before the shell | Implemented | `lib/screens/welcome_screen.dart` |
| Onboarding | Optional name, allergy chips, diet chips | Rules exist before the first plan | Implemented | `lib/screens/onboarding_screen.dart` |
| Food preferences | Allergies, diet, cuisines, spice, skill, goal, equipment, household, cook time, reminder window, weekly aim, notification switches, ask-before-deduct | Plans and reminders follow the kitchen | Implemented, with unused fields | `lib/screens/account_settings_screen.dart`, `lib/models/user_preferences.dart` |
| Units toggle | Metric or imperial saved in preferences | Intended unit choice | Partial — value is saved and never read | `user_preferences.dart` `units` |
| Camera, gallery, typed add | Centre tab captures or picks photos, or accepts a typed name | Stock can be logged quickly | Implemented | `lib/screens/pantry_import_screen.dart` |
| Scan confirm | Edit name, quantity, unit, expiry, place; remove a draft | The model does not write the pantry alone | Implemented | `lib/screens/pantry_confirm_screen.dart` |
| AI photo analysis | Server vision call, UK shelf-life and GBP hints | Less typing | Partial — live only with a key; questions are discarded; phone rejects `isDemo` | `server/src/openai.ts`, `lib/services/api_client.dart` |
| Pantry list | Food segment, place filters, expiring, expired, later, previously used | The cook sees what is left | Implemented | `lib/screens/pantry_screen.dart` |
| Ingredient detail | Edit, history, recipes that used it, delete | One item can be corrected | Implemented | `lib/screens/ingredient_detail_screen.dart` |
| Merge by name | Same normalised name adds quantity and keeps an existing expiry | Repeat scans do not fork the item | Implemented | `lib/services/pantry_service.dart` |
| Meal plan setup | 3/5/7 days, meal slots, people 1–8, goals, spice, cuisines, avoid list, max minutes, optional budget | The week matches the household | Implemented; budget is unused on the server | `lib/screens/planner_setup_screen.dart`, `server/src/schemas.ts` |
| Pantry selection for a plan | All, selected, or none; expired items excluded | The plan can prefer food that is still edible | Implemented | `lib/screens/planner_pantry_select_screen.dart` |
| Plan generation | Named dishes, shopping list, pantry usage | A week comes from stock | Partial — requires reachable server with OpenAI configured; failed model days can be replaced by templates | `server/src/mealPlan.ts` |
| Timetable edits | Open, mark eaten, swap, use a saved recipe, refresh image, remove, tick shopping | The week can change | Implemented for those actions | `lib/screens/planner_timetable_screen.dart` |
| Allergy warning text | Server returns `allergyWarning` | Intended safety note | Partial — stored, not shown | `lib/models/meal_plan.dart` |
| Course select | Starter, main, drink, or dessert | Intended control of the five recipes | Partial — choice is stored and not used to pick recipes | `lib/screens/course_select_screen.dart` |
| Showcase deck | Five fixed plated meals, swipe to shortlist | A cook path that does not wait on the model | Implemented as a fixed list | `lib/data/chef_showcase_recipes.dart` |
| Saved recipes | Heart and the Saved segment | A good meal can be reopened | Implemented | `lib/screens/pantry_screen.dart` |
| Recipe detail | Macros, pantry versus missing, steps, waste tip | The cook can judge the dish | Implemented | `lib/screens/recipe_detail_screen.dart` |
| Add missing ingredient to the shopping list | Button on the missing-ingredient sheet | Intended list update | Not implemented — snackbar only | `lib/widgets/recipe_card.dart` |
| Cook mode | Paged steps, wakelock, countdown if a step mentions minutes | Hands-free steps | Partial — timer does not notify at zero; does not mark eaten | `lib/screens/cook_mode_screen.dart` |
| Mark eaten and deduct | Optional confirm sheet; blocks expired items and double cooks | Stock and history stay aligned | Implemented | `lib/services/pantry_service.dart` |
| Impact | Rescued kg, aim, week bars, caught-in-time, top foods, milestones, history, share card | A number with a stated rule | Implemented | `lib/widgets/impact_dashboard.dart`, `lib/services/impact_service.dart` |
| Eating | Week explorer for calories and macros, lifetime totals | Intake stays separate from waste | Implemented | `lib/widgets/eating_dashboard.dart` |
| Load demo week / reset graphs | Settings actions for chart data | A demo can show Impact immediately | Implemented | `lib/state/app_state.dart` |
| Local notifications | Expiry at 09:00 the day before; optional Sunday plan, shopping, and prep | A reminder without a server push | Implemented | `lib/services/notification_service.dart` |
| Dish photos | Search, then a fixed image URL | Meals are recognisable | Partial — depends on optional keys and fallbacks | `server/src/images.ts` |
| `DEMO_MODE` | Dart define for offline analyse and recipe samples | A UI pass without a key | Partial — meal plans still throw | `lib/config.dart`, `lib/services/api_client.dart` |

## 8. Out-of-Scope Features

**Left out on purpose**

- User accounts, passwords, and cloud sync. The product in [FEATURES.md](FEATURES.md) is local-first.
- Social feed, comments, and following other cooks.
- Grocery delivery, checkout, and payment.
- Subscriptions or a paid tier.
- Treating food with no expiry date as rescued.
- A measured carbon audit of each ingredient. The range is a display calculation.

**Present in the interface or the API, and not finished**

These are gaps, not deliberate cuts documented as product decisions by a planning interview.

- Clarification questions. The server schema allows up to three. `lib/screens/clarification_screen.dart` is deleted. The client keeps at most three and no screen asks them.
- The swipe deck calling `POST /api/generate-recipes`. The route works for a one-slot swap. The deck ignores it.
- Weekly budget. The client can send `weeklyBudgetGbp`. The server validates it and never reads it.
- Metric and imperial conversion.
- Rendering `MealPlan.allergyWarning`.
- Putting a missing recipe ingredient onto the plan shopping list.
- A notification when the cook-mode timer ends.
- `scan_sessions` rows. The table exists and has no writer.

**Documentation that is stale**

- [README.md](README.md) still lists onboarding, notifications, and profile settings as out of scope, says the app opens on an AI Chef tab, and says an unreachable API falls back to demo analysis. The shell opens on Plan. Onboarding and local notifications exist. The phone throws if the API is down, unless `DEMO_MODE=true`.
- [README.md](README.md) says the default model is `gpt-4o-mini` and the default API base is `http://10.0.2.2:3001`. The code default model string is `gpt-6-luna`. The code default base is `http://127.0.0.1:3001`.
- [FEATURES.md](FEATURES.md) describes the five recipes as generated and says reminder scheduling is future work. The deck is fixed. Notifications are scheduled.
- [APP_REFERENCE.md](APP_REFERENCE.md) still describes deleted screens (`ScanScreen`, `ClarificationScreen`) and schema version 5. The database is version 6.

Those older files were not rewritten by this documentation pass.

## 9. Assumptions and Constraints

- **Time and budget.** No budget figure is in the repo. OpenAI, SerpAPI, and Pexels costs depend on the account and are not recorded.
- **Hosting.** The server is a local process. Nothing in the repo deploys it.
- **API limits.** Recipe and plan calls retry a small number of times. SerpAPI HTTP 429 sets a 90-second cooldown in `server/src/images.ts`. Provider quotas are otherwise whatever the key allows. Billing failures return HTTP 402.
- **External dependencies.** Live scan and plan need OpenAI. Dish photos degrade to TheMealDB and hardcoded Unsplash URLs without image keys. Fonts need a network on first fetch.
- **Platform.** The supported demo path is Android. `start-plateful.ps1` targets device id `SM` and uses `adb reverse`. The Android manifest allows cleartext HTTP. iOS has camera and photo-library purpose strings and no App Transport Security exception for cleartext. An iOS run against the local HTTP server was not verified.
- **Data.** Pantry prices and shelf life are estimates. Vision is prompted for UK GBP. Piece weights live in `lib/utils/food_facts.dart`. Nutrition is a static table in `server/src/nutrition.ts`.
- **Privacy.** Photos leave the phone when analysis runs: the server holds them in memory and sends them to OpenAI. There is no account, and there is also no login protecting the API.
- **Model name.** If `OPENAI_MODEL` is unset, the server sends `gpt-6-luna`. The repository does not contain a recorded successful response from that model.

## 10. Risks and Limitations

| Risk | Potential impact | Existing mitigation | Remaining limitation |
|---|---|---|---|
| OpenAI key missing, rejected, or out of quota | Photos and new plans fail | Phone shows a configuration, reachability, or billing error; it rejects demo analyse payloads | No on-device meal-plan substitute. A configured call that fails for a non-quota reason can still come back as template dishes with `isDemo: false` |
| Model string not accepted | Every live call fails | Retries drop `reasoning_effort` if the API rejects that parameter | Default name `gpt-6-luna` is unverified |
| Showcase deck ignores the pantry variety | Cooks see egg and spinach meals beside an unrelated fridge | `inPantry` flags are updated from current stock | Course and focus ingredients do not change the five titles |
| Nutrition table is approximate | Macros can be capped or replaced | Atwater check and per-serving caps in `nutrition.ts`; Eating copy is tied to meals the user marked | No lab verification of the numbers |
| CO₂e read as a precise footprint | Over-trust | UI and IMPACT.md present a range and name the WRAP sources | It is not a measurement of the cook's meal |
| Open API on the LAN | Anyone on the network can spend the key or send images | Keys are not in the app; the server binds for local use | No authentication, no rate limit, CORS allows any origin |
| Photos sent to OpenAI | Pantry images leave the device | Confirm step is local; the server uses memory storage and does not write the upload to disk in the route | The cook is not shown a separate consent screen beyond the platform camera permission |
| Cleartext HTTP | Traffic on the LAN is readable | Acceptable for a local proof; Android debug and main manifests allow it | Not a production transport |
| Stale README | A judge or developer follows the wrong journey | This scope, the PRD, and the spec name the conflicts | The older docs are still in the repo |
| Hackathon process | Eligibility asks for a project started empty and built with the skills | The skill pack is installed under `.agents/skills/` and these docs exist | Installing the pack and writing the docs does not establish that the skills were used to build the app |
| Automated tests are narrow | Regressions in screens and API routes can ship | `flutter test` covers config constants and a few pure helpers; `npm run typecheck` checks the server types | No widget test of the shell, no server test runner |

## 11. Success Criteria

The proof works when all of the following can be shown:

1. A new install can pass welcome and onboarding and land on Plan.
2. A confirmed pantry item survives leaving and reopening the app.
3. With the server up and OpenAI configured, a photo yields an editable ingredient list, and Generate plan yields a timetable of named dishes for 3, 5, or 7 days.
4. Marking a meal eaten reduces the matching pantry quantity.
5. If that item's expiry was inside the reminder window, Impact's rescued kilograms increase and the page can explain the rule.
6. A meal with only undated ingredients does not increase rescued kilograms.
7. Eating shows calories and macros for meals marked eaten.
8. Load demo week fills Impact without a live scan.
9. With the server stopped, the app explains that the plan and the photo need the server, and it does not present a failed scan as a successful detection.
10. `flutter test` and `npm run typecheck` succeed. They do not, by themselves, prove items 1–9. Those items are manual.

## 12. Future Development

These are not in the current behaviour.

**Immediate**

- Send the showcase deck through `POST /api/generate-recipes`, and pass the selected course.
- Show `allergyWarning` on the timetable.
- Either apply `units` or remove the control.
- Either use `weeklyBudgetGbp` or stop sending it.

**Short term**

- Ask the clarification questions the server already returns, or stop requesting them.
- Append missing recipe ingredients to the plan shopping list.
- Fire a notification when a cook-mode timer completes.
- Add a server test that asserts health, a schema rejection, and the no-key demo payload.
- Correct README, FEATURES, and APP_REFERENCE so they match this scope.

**Longer term**

- Optional accounts and sync.
- A hosted API with authentication and HTTPS.
- A reviewed nutrition source, if the estimates need to be more than a table.
- Image generation or a licensed photo library, if hotlinked fallbacks are not acceptable.

None of the longer-term items are started in this repository.
