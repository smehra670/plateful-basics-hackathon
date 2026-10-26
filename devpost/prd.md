---
doc: prd
status: draft
---

This draft follows the Devpost Learn `3-prd` template. It was written from the existing repository on 26 October 2026, after the app already existed. `1-start` was not run. Product choices below are observations of the implementation, not answers from a learner interview. The detailed requirements are in [../prd.md](../prd.md). Scope source: [scope.md](scope.md).

# Plateful — Product Requirements

Plateful helps a home cook use food they already bought before it passes the expiry window they set. Source: `scope.md > Who It's For` and `scope.md > The Unique Kernel`.

## The Core Journey

Source: `scope.md > The Core Loop`.

1. First launch shows a welcome screen, then three onboarding pages: an optional display name, allergy chips, and diet chips. Later launches open the shell.
2. The shell has three surfaces: Plan, a centre camera button, and Pantry. Pantry has Food, Saved, Impact, and Eating.
3. The cook photographs one item or several, or types a name, then confirms quantity, unit, expiry, and storage place. Confirmed rows merge into the pantry by name.
4. On Plan they choose 3, 5, or 7 days, which meals, how many people, and whether to use the whole pantry, selected items, or no pantry. Generate asks the local server for a plan. The timetable lists named dishes.
5. From the pantry or the timetable they can open five fixed recipes, swipe to shortlist, and save with the heart.
6. They open a recipe, optionally step through cook mode, and mark it eaten. If "ask before deducting" is on, they confirm the amounts. Pantry quantities drop.
7. Impact shows rescued kilograms for uses that were inside the reminder window at cook time. Eating shows calories and macros from meals marked eaten.
8. Success for the proof is a pantry that persists, a plan or a showcase meal that can be marked eaten, and an Impact total that moves when near-expiry food is used.

## Screens and Layout

There are no named routes. `lib/main.dart` chooses the first screen. Everything else is pushed.

| Surface | How it is reached | What is on it |
|---|---|---|
| Welcome | First launch, until `welcome_v1` is set | Logo, "Make more. Waste less.", Get started |
| Onboarding | After welcome, until `onboarding_v1` is set | Name, allergies, diet, Start cooking |
| Plan | Default tab | Empty landing, or the week timetable |
| Plan setup | Create a meal plan | Duration, meals, people, goals, spice, cuisines, dislikes, cook time, optional budget |
| Pantry picker | From setup | Entire pantry, selected items, or no pantry |
| Camera | Centre nav button | Live camera, flash, gallery, one-or-several toggle, type-a-name |
| Confirm | After a photo or typed add | Editable drafts, then Add to pantry |
| Pantry | Pantry tab | Food, Saved, Impact, Eating |
| Ingredient | Tap a pantry row | Photo, quantity, expiry, place, usage history |
| Course select | Cook from pantry or timetable | Starter, main, drink, dessert, then Create 5 recipes |
| Chef | After course select | Loading, swipe deck, then shortlist |
| Recipe | From the deck, saved list, or plan | Photo, macros, ingredients, steps, cook, mark eaten |
| Cook mode | Start cooking | Paged steps, screen stays awake, optional countdown |
| Food preferences | Profile avatar | Allergies, diet, kitchen, reminders, demo data |

## Look and Feel

Recorded from the theme that is already in the app, not from a design interview.

- Ground `#F7F8F4`, ink `#1B2A22`, forest `#2E6B4E`, sage washes for selected chips, peach and rose for warnings.
- Display type is Bricolage Grotesque. Interface type is Figtree. Both load through `google_fonts`, which needs a network the first time.
- Layout is spacious, with a floating nav and pill chips. Copy is short and kitchen-specific.
- [FEATURES.md](../FEATURES.md) calls this Sage & Linen. No external mood-board URL is stored in the repo.

## Features and Behavior

### Pantry

The cook adds food by camera, gallery, or typing, confirms it, and sees quantity, place, and expiry. Swipe and edit change amounts. Empty rows move to Previously used. Expired available items stay visible and cannot be cooked.

- As a home cook, I want to confirm what the photo detected, so that the pantry matches the kitchen.
  - [ ] A photo is not written into the pantry until Add to pantry is pressed.
  - [ ] Saving the same name again adds quantity and keeps an existing expiry date.
  - [ ] After a restart the confirmed rows are still listed.

### Meal plan

The cook builds a Monday-aware timetable of specific dish names from preferences and pantry. They can swap, remove, replace with a saved recipe, refresh a photo, and tick shopping rows.

- As a home cook, I want a week of meals drawn from what I have, so that I cook the food that is already paid for.
  - [ ] Duration is only 3, 5, or 7 days, and meals are breakfast, lunch, dinner, or snack.
  - [ ] Generate shows an error if the server is down or health reports OpenAI is not configured.
  - [ ] A new plan id starts that plan's eaten nutrition from zero. Older Impact history remains.

### Showcase recipes and cooking

Course select always leads to the same five dishes: Cheesy Spinach Scrambled Eggs on Toast; Spinach, Egg & Cheese Toastie; Cheesy Egg-in-a-Hole; Spinach & Cheese Omelette with Toast; Savoury Cheesy French Toast. Swipe right shortlists, swipe left skips, the heart saves. Mark as eaten deducts matched pantry amounts. Cook mode does not itself mark the meal eaten.

- As a home cook, I want to cook from a short list and have the pantry shrink, so that the list stays true.
  - [ ] The five titles above appear even when the pantry is a different set of foods, as long as something cookable remains.
  - [ ] Changing starter, main, drink, or dessert does not change those five titles.
  - [ ] A recipe that uses an expired pantry item cannot be marked eaten.
  - [ ] With ask-before-deduct on, the cook can edit the proposed amounts before they are applied.

### Impact and Eating

Impact is rescued kilograms, a CO₂e range, a weekly aim, and history. Eating is calories, protein, carbohydrates, fat, and fibre from meals marked eaten. Source: `scope.md > The Unique Kernel`.

- As a home cook, I want the kilogram total to mean food used in time, so that I can trust the number.
  - [ ] A use counts as rescued only when it was inside the reminder window at cook time.
  - [ ] A meal whose matched items have no expiry date is excluded from rescued kilograms and named on the page.
  - [ ] The CO₂e line is rescued kilograms times 2.5 and times 2.9, not a single invented factor.

### Preferences and reminders

Allergies, one diet style plus optional Halal or Kosher, cuisines, spice, skill, household size, cook time, meal goal, equipment, units, reminder window, weekly aim, and four notification switches are stored on the phone. Expiry reminders default on. The other three default off.

- As a home cook, I want the plan to know what I cannot eat, so that I do not have to retype it.
  - [ ] Allergy and diet chips chosen in onboarding are still selected in Food preferences after a restart.
  - [ ] With expiry reminders on, a future expiry schedules a local notification for 09:00 the day before.
  - [ ] Turning a reminder off and saving removes that scheduled notification on the next sync.

## States and Boundaries

- **First launch** — Welcome, then onboarding, then the shell. Flags live in `user_settings`.
- **Returning launch** — Shell opens on Plan. Pantry, plan, shortlist, and preferences reload from SQLite.
- **Empty pantry** — Plan offers a path to the camera. If the health check fails or OpenAI is not configured and the pantry is empty, startup seeds eggs, tomatoes, spinach, cheese, and bread.
- **Empty Impact** — Bars stay at rest with copy that cooking from the pantry starts the record.
- **Photo failure** — The confirm screen does not open. The cook sees the server or configuration error.
- **Plan failure** — The Plan tab shows the error. No on-device stand-in plan is created.
- **Expired food** — Still listed. It is excluded from cookable stock and blocks a recipe that depends on it.
- **Persistence** — Ingredients, recipes, saves, cooks, usage, preferences, welcome, onboarding, the current plan, and the shortlist survive process death. `scan_sessions` is created and never written.
- **Who can see it** — There is no login. Anyone with the phone can open the app. Anyone who can reach the PC server can call its API.

## Product Decisions

These are observations of the code. They were not collected in an interview. Assumptions are labelled.

- Pantry data stays on the phone. Observed in `lib/data/database.dart`. The tradeoff is no multi-device sync.
- The cook confirms a scan before it is saved. Observed in `lib/screens/pantry_confirm_screen.dart`.
- The swipe deck uses five bundled recipes. Observed in `AppState.generateRecipesFromPantry`. Assumption in older docs that this deck calls the model is contradicted by that method.
- Meal plans and single-slot swaps call the server. Observed in `ApiClient.generateMealPlan` and `ApiClient.generateRecipes`.
- Rescued kilograms use the reminder window stored at cook time. Observed in `PantryService` and `ImpactService`.
- The phone rejects analyse and recipe payloads marked `isDemo` unless `DEMO_MODE=true`. Observed in `lib/services/api_client.dart`. Assumption in README that any unreachable API silently fills those screens is contradicted.

## What We're Building

The proof already in the tree: welcome and onboarding, a confirmed pantry, OpenAI photo analysis and meal plans when a key is configured, a fixed five-recipe deck, cook and deduct, Impact and Eating, saved recipes, preferences, local notifications, and a demo-week seed for the charts.

## Deferred From the POC

- Live generation for the five-card deck. The server route exists. The deck does not call it. Wiring it would make course and focus ingredients matter.
- Clarification questions. The server can return up to three. The question screen is deleted and the app discards them.
- Showing `allergyWarning`, applying `units`, and honouring `weeklyBudgetGbp`. The fields are stored or accepted and then unused.
- Adding a missing recipe ingredient onto the plan shopping list. The button only shows a snackbar.
- A cook-mode timer that notifies when it hits zero. The countdown is on-screen only.

## Possible Later Enhancements

Accounts would let the same pantry follow a cook to another phone. A hosted API would remove the USB or LAN setup. Per-food carbon factors would replace the single WRAP range if a source is chosen. Grocery ordering would leave the current boundary on purpose.

## Non-Goals

- Login, social posting, delivery checkout, and subscriptions. They are outside `scope.md > Explicitly Cut`.
- Treating undated food as rescued.
- Publishing a single precise CO₂e number for each ingredient.
- Claiming the five showcase dishes were invented for the current pantry.

## Open Questions

- Whether the configured `OPENAI_MODEL` (default string `gpt-6-luna` when unset) is accepted by the API account. Unverified in this repository. It does not block this spec. It blocks a live demo if the provider rejects the name. Can wait for a manual health-and-generate check.
- Whether course select should change the five dishes. The control is on screen and the generator ignores it. Product gap, already visible in code. Can wait.
- Whether this repository meets the hackathon rule that the project was started empty and built by running the skills. Not verifiable from source. Out of scope for the technical spec. Must be answered by the submitter, not by these files.
