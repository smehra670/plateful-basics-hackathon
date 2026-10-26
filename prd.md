# Plateful — Product Requirements Document

This document says what Plateful does for a person using it. It matches the implementation described in [scope.md](scope.md) and [spec.md](spec.md). Requirement identifiers (`FR-###`) are used again in the spec where they help.

The Devpost template draft is [devpost/prd.md](devpost/prd.md). It was written from the repository, not from a `1-start` interview. Personas below are illustrative. They are not research participants.

## 1. Product Summary

Plateful is a mobile proof of concept for people who cook from food they already have. It stores a pantry on the phone, asks a local server to read photos and to build a multi-day meal plan, offers five fixed recipes for a quick cook, and separates two results: food used inside an expiry window (Impact) and the nutrition of meals marked eaten (Eating). There is no login.

## 2. Product Vision

**Long-term goal:** The pantry, the plan, and the rescue record stay trustworthy enough that a cook relies on them instead of a separate notes app and a generic recipe site.

**Immediate MVP objective:** Show the loop in [scope.md](scope.md) section 6 on one Android phone: confirm food, generate a plan when OpenAI is configured, mark a meal eaten, and see Impact move only when the food was inside the reminder window.

## 3. User Problems

1. **Stock is invisible.** Ingredients expire because nobody wrote down the amount or the date.
2. **Recipes ignore the fridge.** A search starts from a dish name, so the food already bought is easy to skip.
3. **Cooking does not update the list.** A meal can be made and the pantry note still shows the old quantity.
4. **Waste and intake get mixed together.** A single "healthy" number hides whether food was used in time.
5. **Rules are retyped.** Allergies and diet have to be remembered at every recipe site.

Plateful answers 1, 3, and 4 on the phone today. It answers 2 for the weekly plan when the server is live. The five-card deck does not answer 2: those dishes are fixed. It answers 5 for plan and swap requests. The showcase deck does not receive the allergy list.

## 4. User Personas

### Avery, the weeknight cook

Illustrative. Avery shops once or twice a week, cooks for one or two people, and finds soft herbs and opened dairy at the back of the fridge. Avery is comfortable with a phone camera and does not want an account. Plateful helps by keeping quantities, flagging the reminder window, and building a short plan from what is already there.

**Goals:** Use food before it is wasted. Decide dinner without a long search.

**Frustrations:** Recipe apps that assume an empty kitchen. Lists that lie after cooking.

**Technical experience:** Everyday smartphone user. Will grant camera permission. Will not edit a `.env` file unless someone is demonstrating the server.

### Reza, the cook with hard rules

Illustrative. Reza avoids specific allergens and keeps a diet style, sometimes with Halal or Kosher as well. Reza will use Plateful if those chips stick and if planned meals respect them.

**Goals:** One place for rules. Meals that do not break them.

**Frustrations:** Re-entering allergies. Hidden dairy or nuts.

**Technical experience:** Comfortable changing settings. Will notice if a recipe ignores the chips.

**How the product helps today:** Onboarding and Food preferences store the chips and send them on plan and swap requests. The showcase deck does not. The server's allergy warning string is not shown. Reza still has to read the dish.

### Sam, the person recording the demo

Illustrative. Sam needs the Impact charts to show a story in a one-to-three minute video. Sam can run the server and can load the demo week from settings.

**Goals:** A visible rescue count-up and a plan on screen.

**Frustrations:** Empty charts. A demo that depends on a flaky key with no explanation.

**How the product helps:** Load demo week seeds history. Errors name the startup script when the server or key is missing.

## 5. User Stories

- As Avery, I want the app to remember that I have already passed the intro, so that I land in the kitchen next time.
- As Avery, I want to photograph several ingredients and fix the names before they are saved, so that the pantry is mine and not the model's guess.
- As Avery, I want items that are close to expiry to stand out, so that I cook those first.
- As Avery, I want a week of named meals from the pantry, so that I am not inventing dinner every evening.
- As Avery, I want to swap one planned meal when plans change, so that the rest of the week stays.
- As Avery, I want to mark a meal eaten and see the quantity fall, so that I do not cook the same spinach twice on paper.
- As Avery, I want a step-by-step cook view that keeps the screen awake, so that I can follow the method with messy hands.
- As Avery, I want to save a recipe, so that I can cook it again without regenerating a plan.
- As Reza, I want allergies and diet stored once, so that plan generation receives them.
- As Avery, I want Impact to count only food I used inside my own reminder window, so that the kilogram number has a meaning I can check.
- As Avery, I want calories and macros on a different page from waste, so that the two stories stay separate.
- As Avery, I want a reminder the day before something expires, so that I still have a chance to cook it.
- As Sam, I want to load a demo week, so that Impact is populated for a recording.
- As Sam, I want a clear error when the server or the key is missing, so that a failed demo is explainable.

## 6. Functional Requirements

| ID | Feature | Requirement | Priority | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| FR-001 | Welcome | First launch shows welcome until the cook continues | P1 | Implemented | Get started sets `welcome_v1`. The next cold start does not show welcome |
| FR-002 | Onboarding | Name, allergies, and diet can be set before the shell | P1 | Implemented | Start cooking sets `onboarding_v1`. Chosen chips match Food preferences after restart |
| FR-003 | Preferences | Food preferences edit the fields in `UserPreferences` and persist them | P1 | Implemented | A saved toast appears. Killing the app keeps the new reminder window and aim |
| FR-004 | Units | The units control is visible | P3 | Partial | Switching metric/imperial survives restart and does not change any quantity label elsewhere |
| FR-005 | Capture | Camera, gallery, and typed name can start an add | P1 | Implemented | Shutter, gallery multi-select, and the type-a-name bar each reach confirm or an error |
| FR-006 | Confirm | Drafts are editable and are saved only on Add to pantry | P1 | Implemented | Changing a name or date before save stores the edited values. Backing out stores nothing |
| FR-007 | Analyse | A photo is sent to the server when OpenAI is configured | P1 | Implemented | A non-demo 200 response opens confirm with one row per returned ingredient |
| FR-008 | Analyse failure | Missing server or key does not invent a scan, except `DEMO_MODE` | P1 | Implemented | Server down shows the unreachable message. Key missing names `OPENAI_API_KEY`. `DEMO_MODE=true` returns the sample eggs, tomatoes, spinach, cheese, and bread after a short delay |
| FR-009 | Questions | Clarification questions are not asked | P2 | Partial | A response that includes questions still opens confirm with no question screen |
| FR-010 | Pantry | Food segment groups stock by expiry and place | P1 | Implemented | Available items with quantity above zero appear under Expiring soon, Expired, or Later. Quantity zero appears under Previously used |
| FR-011 | Merge | The same name adds quantity | P1 | Implemented | A second save of the same name increases quantity and keeps an expiry that was already set |
| FR-012 | Expiry rule | Badges and the rescue flag use the cook's window | P1 | Implemented | Changing the window among 3, 5, 7, and 14 days changes which available items are "soon" and which future cooks are flagged |
| FR-013 | Ingredient edit | A row can be changed or deleted | P1 | Implemented | Detail screen updates quantity and place. Delete removes the row |
| FR-014 | Plan setup | Duration, slots, people, and pantry mode are collected | P1 | Implemented | Only 3, 5, and 7 days can be chosen. People stay in 1–8. Expired items are not selectable as cookable |
| FR-015 | Plan generate | Generate calls the meal-plan API and shows the timetable | P1 | Partial | With health `openaiConfigured: true`, a 200 response replaces the empty Plan landing with days of meals. If health fails or OpenAI is false, the UI shows the startup-script error and no plan is saved |
| FR-016 | Plan budget | Optional weekly budget can be entered | P3 | Partial | The value is on the request. No meal or shopping row changes because of it |
| FR-017 | Timetable | Meals can be opened, completed, swapped, replaced, removed, and re-photographed | P1 | Implemented | Each of those actions updates the visible week. Swap waits on `POST /api/generate-recipes` with one recipe |
| FR-018 | Shopping checks | Shopping rows can be ticked | P2 | Implemented | A tick survives leaving the timetable and coming back, until a new plan replaces the list |
| FR-019 | Allergy note | The plan's allergy warning is visible | P2 | Not implemented | The string may be in saved plan JSON and is absent from the timetable UI |
| FR-020 | Showcase deck | Create 5 recipes shows the five bundled titles | P1 | Implemented | The titles match `ChefShowcaseRecipes` regardless of course and regardless of which pantry names were selected, provided something cookable remains |
| FR-021 | Shortlist | Swipe right keeps a recipe, swipe left skips, heart saves | P1 | Implemented | After the last card, the shortlist is listed. A heart makes the recipe appear under Pantry → Saved after restart |
| FR-022 | Add to plan from deck | A shortlisted dish can be placed on the current plan | P2 | Partial | Add to plan replaces one existing slot using the first shortlisted recipe only |
| FR-023 | Recipe detail | The cook sees ingredients, steps, macros, and pantry match | P1 | Implemented | In-pantry and missing lines are both visible. Start cooking opens cook mode when no expired item blocks it |
| FR-024 | Cook mode | Steps are paged and the screen stays on | P2 | Partial | Wakelock is held on the cook screen. A step containing "N min" can start a countdown. At zero there is no notification. Leaving cook mode does not mark the meal eaten |
| FR-025 | Mark eaten | Deduction is confirmed when the preference says so | P1 | Implemented | With ask-before-deduct on, a sheet lists proposed amounts and Apply changes `quantity_remaining`. With it off, the deduction happens immediately |
| FR-026 | Expired block | Expired stock cannot be cooked | P1 | Implemented | A recipe whose matched pantry item is expired shows the block reason and does not write a cooking event |
| FR-027 | Double cook | The same plan slot is not deducted twice | P1 | Implemented | Completing a planned meal once marks it complete. A second attempt does not deduct again. A five-second guard also blocks a rapid repeat of the same recipe id |
| FR-028 | Impact | Rescued kilograms follow the stored near-expiry flag | P1 | Implemented | Only usage rows with `was_near_expiry` contribute. The hero uses the sum of `FoodFacts.toKg`. Undated-only meals increment the excluded count |
| FR-029 | CO₂e | The range is 2.5–2.9 times rescued kilograms | P1 | Implemented | The hero shows both ends. The how-we-calculate sheet names the WRAP basis used in code comments |
| FR-030 | Eating | Macros come from meals marked eaten | P1 | Implemented | Calories, protein, carbohydrates, fat, and fibre for the last seven days can be selected. Lifetime totals include those meals |
| FR-031 | Notifications | Local reminders follow the four switches | P2 | Implemented | Expiry on: a future item schedules 09:00 the day before. The other three default off. Turning one off and syncing cancels it. Times use `Europe/London` |
| FR-032 | Demo week | Settings can seed and clear chart history | P2 | Implemented | Load demo week creates roughly 14 days of cooks. Reset all graphs clears cooking and usage rows and leaves pantry quantities |
| FR-033 | Share | The Impact hero can be shared as an image | P3 | Implemented | Share produces an image hand-off through the platform share sheet |
| FR-034 | Missing-to-list | A missing ingredient can be added to the shopping list from a recipe | P3 | Not implemented | The control shows a snackbar that the shopping list is created with the meal plan, and the plan list is unchanged |
| FR-035 | Health fallback hosts | The phone tries more than one base URL | P2 | Implemented | Preferred URL is `API_BASE_URL` or `http://127.0.0.1:3001`, then `http://192.168.1.24:3001`, `http://10.0.2.2:3001`, and `http://localhost:3001` |

Priority: P1 is required for the MVP journey. P2 supports it. P3 is visible and not required to prove the kernel.

## 7. Feature Specifications

### Welcome and onboarding

**Purpose:** Set a display name and food rules before the first plan. FR-001, FR-002.

**User interaction:** Automatic on first launch. Get started, then three pages, then Start cooking. Name can be skipped.

**Expected behaviour:** Flags `welcome_v1` and `onboarding_v1` are stored. Later launches open the shell on Plan.

**Inputs:** Optional display name. Allergy chips from Peanuts, Tree nuts, Dairy, Eggs, Gluten, Soy, Shellfish, Fish, Sesame. Diet chips from Omnivore, Vegetarian, Vegan, Pescatarian, plus Halal and Kosher alongside one style.

**Processing:** `AppState.markWelcomeSeen` and `markOnboardingSeen` write settings and the preference JSON.

**Outputs:** Greeting and avatar use the display name when it is present.

**Error handling:** If the database fails to open, startup stays on the opening loading view. There is no separate retry screen for that failure in `main.dart`.

**Acceptance criteria:** A second cold start skips both screens. Chips match Food preferences.

**Current status:** Implemented.

### Food preferences

**Purpose:** Edit the same rules later, plus kitchen and reminder settings. FR-003, FR-004, FR-031, FR-032.

**User interaction:** Profile avatar on Plan, Pantry, and the timetable. Title is Food preferences.

**Expected behaviour:** Changes persist. Notification sync runs after save. Load demo week and Reset all graphs are on this screen.

**Inputs:** The option lists in `UserPreferences`, reminder days 3/5/7/14, aims 0.25/0.5/1 kg, units metric or imperial, equipment, and four notify switches.

**Processing:** `SettingsService` writes `user_preferences`. `NotificationService.sync` cancels and reschedules.

**Outputs:** Saved toast. Updated Impact aim and expiry badges.

**Error handling:** A failed save would surface through the normal Flutter error path. No custom offline banner exists on this screen.

**Acceptance criteria:** FR-003 and FR-004.

**Current status:** Implemented. Units are stored only.

### Pantry capture and confirm

**Purpose:** Get food into the database without trusting an unread photo. FR-005, FR-006, FR-007, FR-008, FR-009.

**User interaction:** Centre camera tab, or the pantry plus button. Take a photo, pick from the gallery, or type a name. One-item versus several is a toggle. Confirm screen edits each draft.

**Expected behaviour:** Photos are compressed and copied locally, then analysed. Typed names still go through confirm. Add to pantry merges each draft and switches to the Pantry tab.

**Inputs:** JPEG, PNG, or WEBP file. Typed name string. Draft fields: name, quantity, unit, expiry, storage place.

**Processing:** `AppState.analyseImageFile` → `ApiClient.analyseImage`. Names containing "and" or "&" are split unless the server already kept a phrase such as fish and chips. Shelf life and price fill from the response or from `FoodFacts`. Questions are truncated to three and then unused.

**Outputs:** Ingredient rows and local photo files under `pantry_photos/`.

**Error handling:** No file or a failed call leaves the cook on the camera with an error. Empty detections throw. `isDemo: true` throws unless `DEMO_MODE` was set, in which case the sample five foods are returned and the photo is ignored. A manual add snackbar can say "Added" before confirm; the row is not saved yet.

**Acceptance criteria:** FR-006, FR-007, FR-008.

**Current status:** Implemented. Question step is not implemented. The one-versus-several toggle does not change the analyse request; gallery selection can already include multiple photos.

### Pantry management

**Purpose:** Show what is left, where it is, and what has been used up. FR-010, FR-011, FR-012, FR-013, FR-026.

**User interaction:** Pantry → Food. Filters All, Fridge, Freezer, Pantry. Tap to edit. Swipe right to cook that item. Swipe left to zero an available item or delete a used one. The bottom pill cooks selected items, or soon-to-expire items if none are selected.

**Expected behaviour:** Expired available items stay listed and are excluded from cookable stock. Previously used means quantity remaining at or below zero.

**Inputs:** Edits from the detail screen. Cook deductions from a recipe.

**Processing:** `ExpiryInfo` in `lib/utils/expiry.dart`. Merge in `PantryService`.

**Outputs:** Grouped lists, expiry badges, an estimated value for food that is expiring soon.

**Error handling:** Cooking with nothing edible shows an error on the chef flow. Delete asks through the detail screen's remove action.

**Acceptance criteria:** FR-010, FR-011, FR-012.

**Current status:** Implemented.

### Meal planner

**Purpose:** Produce a timetable from the pantry and the stored preferences. FR-014, FR-015, FR-016, FR-017, FR-018, FR-019.

**User interaction:** Plan → Create a meal plan → Choose pantry ingredients → Generate plan. On a plan: open a meal, mark eaten, swap, use a saved recipe, refresh the photo, remove, tick shopping, or cook with the pantry items that meal uses.

**Expected behaviour:** Dates start at the chosen start date or today. Slots follow breakfast, lunch, dinner, snack for the selected subset. Dish titles are specific. A new plan id means that plan's eaten nutrition starts clean. Impact history is not deleted by a new plan.

**Inputs:** `MealPlanRequest`: duration, meals, people, goals, spice, cuisines, avoid list, max minutes, optional budget, pantry mode, pantry rows, focus ingredients, preferences.

**Processing:** Server builds one model call per day when a key exists, replaces empty or repeated titles, then allocates shopping. The phone hydrates images and, after local edits, reallocates with `plan_allocation.dart`. Staples are not shopped. `weeklyBudgetGbp` is ignored. `pantryMode: none` clears the pantry sent into generation. `all` and `selected` both use the array the phone already filtered.

**Outputs:** Days, meals, shopping list, pantry usage, allergy warning string.

**Error handling:** Unreachable server or OpenAI not configured throws a message that tells the cook to run `start-plateful.ps1` and tap Retry. HTTP 402 and 502 surface as meal-plan errors. A configured generation that fails inside the planner can return template meals with `isDemo` false; the phone will show them.

**Acceptance criteria:** FR-014, FR-015, FR-016.

**Current status:** Partial, as in the table.

### Showcase deck and saved recipes

**Purpose:** A fast cook path and a way to keep a meal. FR-020, FR-021, FR-022, FR-034.

**User interaction:** Course select → Create 5 recipes. Swipe the deck. Heart. After five cards, open a shortlisted recipe, remove it, add the first one onto the plan, or discover five more.

**Expected behaviour:** The five titles are always Cheesy Spinach Scrambled Eggs on Toast; Spinach, Egg & Cheese Toastie; Cheesy Egg-in-a-Hole; Spinach & Cheese Omelette with Toast; Savoury Cheesy French Toast. Photos are bundled assets. `inPantry` reflects the current cookable pantry. Allergies do not filter the list. Discover 5 more loads the same five again.

**Inputs:** Cookable pantry. The course id and focus names are not used to choose recipes.

**Processing:** `generateRecipesFromPantry` writes the five recipes into the local recipe cache and sets the chef phase to swiping. Shortlist JSON is stored as `shortlist_v1`.

**Outputs:** Deck, shortlist, Saved grid.

**Error handling:** An empty cookable pantry throws and the chef screen shows the message. There is no model timeout on this path.

**Acceptance criteria:** FR-020, FR-021.

**Current status:** Implemented as a fixed deck. Course selection and add-to-list are partial or absent.

### Recipe detail, cook mode, and mark eaten

**Purpose:** Cook the meal and update stock. FR-023, FR-024, FR-025, FR-026, FR-027.

**User interaction:** Open a recipe from the deck, Saved, or the timetable. Start cooking, or Mark as eaten. Planned meals pass the date and slot.

**Expected behaviour:** Cook mode pages the instructions and holds a wakelock. Mark as eaten proposes deductions by name and unit conversion, writes a cooking event and usage events, and lowers quantities. Tiny remainders are zeroed. A planned meal shows as completed.

**Inputs:** Recipe ingredients, current pantry, `askBeforeDeducting`, optional plan key, reminder window.

**Processing:** `proposedCookDeductions` and `confirmCook`. Near-expiry is `isExpiringSoon(expiryReminderDays)` at that moment.

**Outputs:** Updated quantities, usage history, Impact flash when something was rescued ("You just kept X kg of Y out of the bin").

**Error handling:** Expired matches block the cook. A second completion of the same plan key does not deduct again. Network is not required.

**Acceptance criteria:** FR-025, FR-026, FR-027.

**Current status:** Implemented. Cook-mode alert is partial.

### Impact

**Purpose:** Show food kept out of the bin, with the rule visible. FR-028, FR-029, FR-033.

**User interaction:** Pantry → Impact. Tap a day, tap a top food to filter, open history, share the hero, read How we calculate.

**Expected behaviour:** Rescued kilograms are the sum of near-expiry uses converted with `FoodFacts.toKg`. The weekly aim is a bar against `weeklyRescueAimKg` (default 0.5). Caught-in-time compares uses inside the window with uses that still had longer. Meals whose matched items all lack an expiry date are counted and excluded from the kilograms. CO₂e is `rescuedKg * 2.5` through `rescuedKg * 2.9`.

**Inputs:** `cooking_events`, `ingredient_usage_events`, preferences.

**Processing:** Entirely on the phone in `ImpactService.compute`.

**Outputs:** Hero, bars, top foods, milestones, month grid, cumulative line, share image.

**Error handling:** Empty data shows the rest state: cook something from the pantry to start. No server call to fail.

**Acceptance criteria:** FR-028, FR-029.

**Current status:** Implemented. The conversion of count units depends on piece weights and falls back to 0.08 kg per unit when the food is unknown. That is an estimate.

### Eating

**Purpose:** Show what was eaten, separate from rescue. FR-030.

**User interaction:** Pantry → Eating. Pick a nutrient. Tap a day.

**Expected behaviour:** The week shows calories, protein, carbohydrates, fat, and fibre. An energy split uses 4, 4, and 9 kcal per gram for protein, carbohydrate, and fat. Fibre stays in grams. Lifetime totals sum meals marked eaten. The timetable also has a per-day card that compares eaten log entries for that plan date with planned recipe macros. Goals that mention protein, gain, or loss only change a caption (`tracksIntake`). Every goal still shows the same nutrients.

**Inputs:** The same cook log as Impact.

**Processing:** Client-side sums.

**Outputs:** Interactive week and lifetime figures.

**Error handling:** No cooks means empty totals, not an error banner.

**Acceptance criteria:** FR-030.

**Current status:** Implemented. Numbers are only as good as the recipe macros stored at cook time.

### Notifications

**Purpose:** Local reminders. FR-031.

**User interaction:** Switches in Food preferences. No inbox inside the app.

**Expected behaviour:** On boot, after onboarding, on preference save, and on refresh, all scheduled notifications are cancelled and rebuilt. Expiry reminders default on. Plan (Sunday 10:00), shopping (tomorrow 09:00 if unchecked items exist), and prep (today 19:00 if tomorrow has a meal) default off. Android scheduling is inexact. The timezone database is loaded as `Europe/London`. Web returns immediately and does not schedule.

**Inputs:** Preferences, ingredient expiries, current plan.

**Processing:** `flutter_local_notifications`.

**Outputs:** System notifications.

**Error handling:** If notification permission is denied, schedules do not appear. The app does not show a custom explanation screen for that denial beyond the platform prompt.

**Acceptance criteria:** FR-031.

**Current status:** Implemented. [FEATURES.md](FEATURES.md) still calls scheduling future work. That sentence is stale.

### Demo week and demo mode

**Purpose:** Let a demonstration show charts, and let a developer skip the model for scans. FR-008, FR-032.

**User interaction:** Settings → Load demo week, or Reset all graphs. Developers pass `--dart-define=DEMO_MODE=true`.

**Expected behaviour:** Load demo week inserts demo foods, recipes, and near-expiry usage across about 14 days. Reset clears graph tables and demo recipe rows. `DEMO_MODE` makes analyse and `generateRecipes` return local samples. Meal plan generation still requires a live configured server. Startup also seeds the five sample ingredients when the pantry is empty and the health check failed or OpenAI is not configured.

**Inputs:** None from the cook besides the settings button or the dart-define.

**Processing:** `PantryService.seedDemoImpactWeek`. `DemoData` for the dart-define path.

**Outputs:** Non-empty Impact, or sample detections.

**Error handling:** Demo week does not call the network. `DEMO_MODE` does not create a plan.

**Acceptance criteria:** FR-032 and the `DEMO_MODE` clause of FR-008.

**Current status:** Implemented for those paths. README's claim that any API outage falls back to demo recipes on the chef screen is false; the chef screen does not use `DemoData`.

## 8. End-to-End User Journeys

### A. First pantry item from a photo

1. **Starting condition:** App installed, server running, `OPENAI_API_KEY` set, health reports `openaiConfigured: true`. Onboarding already completed.
2. **User action:** Open the camera tab and take a photo of ingredients.
3. **Application response:** The photo uploads. Confirm opens with detected drafts.
4. **Next user action:** Fix a name and an expiry date. Tap Add to pantry.
5. **Final result:** Pantry → Food lists the items. They remain after restart.
6. **Failure cases:** Server down or key missing: error text, no confirm screen. Empty detection: error. User backs out of confirm: nothing saved.

### B. Generate a week and cook one slot

1. **Starting condition:** Cookable pantry items exist. Server and key are available.
2. **User action:** Plan → Create a meal plan → choose 5 days, lunch and dinner → choose pantry items → Generate.
3. **Application response:** A loading state, then a timetable. Images fill in as recipe-image requests return.
4. **Next user action:** Open Monday lunch, mark as eaten, accept the deduction sheet.
5. **Final result:** The slot shows completed. Quantities drop. If any deducted item was inside the window, Impact's rescued total increases.
6. **Failure cases:** Health check fails: error, plan unchanged. Quota: billing message. A template dish can appear if the model call fails after the key was accepted. Expired items were not offered in the picker.

### C. Showcase cook without a new model call

1. **Starting condition:** At least one non-expired pantry item.
2. **User action:** From Pantry, open the cook pill. Leave the course on Main. Create 5 recipes.
3. **Application response:** The five fixed dishes appear. No generate-recipes request is required for this list.
4. **Next user action:** Swipe right on one, open it, mark eaten.
5. **Final result:** The recipe is on the shortlist and, if hearted, under Saved. Pantry quantities change for matching names such as eggs or spinach when those rows exist.
6. **Failure cases:** Nothing cookable: error, no deck. Course change: the same five titles.

### D. Demo the Impact charts

1. **Starting condition:** Any onboarded app.
2. **User action:** Food preferences → Load demo week → Pantry → Impact.
3. **Application response:** History, bars, and rescued foods render from the seeded rows.
4. **Next user action:** Optionally Reset all graphs.
5. **Final result:** After reset, cook history is gone and pantry stock from before the reset remains.
6. **Failure cases:** None that depend on the network. Seeded data can be confused with real cooks if the audience is not told it was loaded.

## 9. User Interface and Experience

### Main screens

Listed in [scope.md](scope.md) section 7 and in [devpost/prd.md](devpost/prd.md). The shell is Plan, camera, and Pantry. Impact and Eating are segments of Pantry, not separate tabs. The chef deck is a pushed screen.

### Navigation

`IndexedStack` keeps the three tabs alive. The floating bar switches `shellTabIndex`. Profile opens preferences. There is no URL router and no deep link.

### Important components

- Floating nav and primary buttons.
- Pantry chips, expiry badges, ingredient cards.
- Swipe deck (`flutter_card_swiper`).
- Recipe photos that accept a network URL or a bundled asset.
- Impact hero and Eating nutrient explorer.
- Loading view (`RecipeLoadingView`) used while the app opens and while a plan or deck is loading.

### Interactions

Swipe on pantry rows and on recipe cards. Chips toggle multi-select or single-select depending on the setting. Date chips on confirm offer +2, +5, and +7 days plus a date picker. Plan days are a strip plus a week overview.

### Loading states

Opening the app shows "Opening". Plan generation shows the loading view while `plannerLoading` is true and no plan exists yet. The deck shows a loading phase before the cards. Image URLs can arrive after the meal title.

### Feedback messages

Preferences show Saved. A rescue can show a dialog or snackbar plus a count-up on the Impact hero. Manual add shows an "Added" snackbar before confirm, which overstates the save. The missing-ingredient action shows a snackbar and does not change data.

### Error states

Camera and plan errors use the thrown message: unreachable script hint, missing key, billing text, or the server's `error` field. Chef idle state shows the pantry error when nothing is cookable. Empty Impact is a rest state, not an error.

### Accessibility

**Implemented:** `Semantics` wrappers exist on the primary button, pressable control, loading skeleton, part of the camera screen, and part of the timetable. Buttons use text labels. Expiry uses colour and words (badges), not colour alone.

**Not verified:** A TalkBack or VoiceOver pass, contrast ratios, dynamic type at the largest sizes, and switch access. Those are recommendations, not results. The cook-mode countdown has no non-visual completion alert.

### Visual system

Implemented in `lib/theme/app_theme.dart`: ground `#F7F8F4`, ink `#1B2A22`, forest `#2E6B4E`, Figtree UI, Bricolage Grotesque display. [FEATURES.md](FEATURES.md) calls this Sage & Linen. No further visual redesign is specified here.

## 10. AI Functionality

AI is used for three tasks. A fourth task looks like AI and is not.

| Task | Used? | Input | Expected output | How it is used | If the output is invalid |
|---|---|---|---|---|---|
| Read a pantry photo | Yes, when a key is set | Image bytes plus a kitchen-vision prompt | JSON ingredients, optional questions | Drafts on the confirm screen. The cook must save them | Phone shows an error on HTTP 502, empty lists, or `isDemo`. Confidence under 0.4 is dropped on the server |
| Build a meal plan | Yes, when a key is set | Pantry, slots, preferences, dishes to avoid | One day's meals per call, assembled into a week | Timetable after shopping allocation and macro replacement | Non-quota failures can be replaced with template dishes and returned as 200 |
| Replace one planned meal | Yes | Pantry and preferences, `recipeCount` 1 | One recipe | That slot, then local reallocation | HTTP error shown. The phone also rejects a body marked demo |
| Five-card deck | No | Cookable pantry, used only to flag `inPantry` | Five constants | Swipe deck | If nothing is cookable, the deck does not open |

**Model:** `OPENAI_MODEL`, or the string `gpt-6-luna` when unset. Temperature is not set. Calls use JSON object mode, then Zod. Names that look like gpt-5, gpt-6, luna, or nano also send `max_completion_tokens` and `reasoning_effort: low`, with a retry without that field if the API rejects it. No measurement of accuracy is in the repo. Human confirmation is the control for scans: nothing is pantried until Add to pantry. Plan dishes are shown as titles the cook can swap or delete; they are not nutritionally certified. Allergies are in the plan prompt and are not a guarantee. The warning string is not displayed.

**Image search** is not a generative model. It queries SerpAPI, Pexels, and TheMealDB, then uses a fixed Unsplash URL.

## 11. Non-Functional Requirements

### Verified from the code

- **Persistence:** SQLite schema 6 on device. See [spec.md](spec.md).
- **Key handling:** Flutter dart-defines are only `API_BASE_URL` and `DEMO_MODE`.
- **Timeouts:** Analyse 90 s, recipes 70 s, meal plan 120 s, recipe image 12 s, each health probe 3 s.
- **Upload limit:** 8 MB image, 1 MB JSON body.
- **Plan shape:** 3, 5, or 7 days; 1–8 people; recipe count 1–8 on the recipe route.
- **Notification mode:** inexact while idle, timezone Europe/London.
- **Tests that exist:** `flutter test` and `npm run typecheck`, with the coverage in section 12.

### Goals, not measured results

- **Performance:** The plan should return inside the 120 s client timeout. No latency benchmark is checked in.
- **Reliability:** Local pantry edits should work with the server off. This is true of the code paths that do not call `ApiClient`. It has not been recorded as a test run in this repo.
- **Security:** A production build would need authentication, HTTPS, and a tighter CORS policy. The proof has none of those.
- **Privacy:** A production build would explain that photos are sent to OpenAI before the upload. The proof asks for the platform camera permission and then uploads.
- **Accessibility:** Interactive controls should have names. Some do, via `Semantics`. A full audit is a goal.
- **Usability:** A cook who already finished onboarding can add food and mark a meal eaten without reading source. That is the aim of the journeys in section 8. It is not a usability-study result.
- **Maintainability:** Server routes live in one file and request bodies go through Zod. That is the current structure, not a scored quality gate.
- **Scalability:** One phone and one local Node process. No horizontal scale is designed.

## 12. Acceptance Testing

Verification status uses three labels.

- **Automated:** an assertion in `test/` covers this behaviour.
- **Not run:** the procedure is specified and no result is stored in the repo.
- **Code review:** the behaviour is visible in source and was not executed as a test while writing this document.

| Test ID | Requirement | Test Procedure | Expected Result | Verification Status |
|---|---|---|---|---|
| AT-001 | FR-035 | Run `flutter test` `test/widget_test.dart` | Default base URL is `http://127.0.0.1:3001`. Fallbacks include `192.168.1.24` and `10.0.2.2`. `expirySoonDays` is 7 and `expiryUrgentDays` is 1 | Automated |
| AT-002 | FR-011 | Run `flutter test` `test/recipe_constraints_test.dart` | Merge adds 2 and 3 to 5 and keeps the existing expiry. A spaced name matches the existing id. Deduction clamps to the available amount and to zero | Automated |
| AT-003 | FR-009 | Same file, question limit and demo analyse | Five questions become three. Demo analyse has ingredients and at most three questions | Automated |
| AT-004 | FR-020 | Same file, demo pantry recipes | The demo-data recipe helper returns 5 recipes that pass the missing-ingredient limit. This does not load `ChefShowcaseRecipes` | Automated |
| AT-005 | FR-028 | Same file, empty impact | `ImpactStats` with zero meals reports `hasData == false` | Automated |
| AT-006 | — | `cd server && npm run typecheck` | `tsc --noEmit` exits 0 | Not run for this document. The script exists |
| AT-007 | FR-001, FR-002 | Cold start twice on a device | Second start skips welcome and onboarding | Not run |
| AT-008 | FR-006, FR-007 | Photo with server and key, edit a name, save, kill app | Edited name is in the pantry | Not run |
| AT-009 | FR-008 | Stop the server, take a photo without `DEMO_MODE` | Error mentions the startup script. No sample ingredients are saved from that photo | Not run |
| AT-010 | FR-008 | Run with `DEMO_MODE=true`, take any photo | Confirm shows eggs, tomatoes, spinach, cheese, and bread | Not run |
| AT-011 | FR-015 | Generate a 5-day plan with two meal slots | Timetable has those slots filled with titles | Not run |
| AT-012 | FR-015 | Generate with a missing key | Error, no new plan | Not run |
| AT-013 | FR-020 | Create 5 recipes, then change course and create again | Both decks show the same five titles | Code review |
| AT-014 | FR-025, FR-028 | Set an item to expire tomorrow, cook a showcase meal that uses it, open Impact | Quantity falls. Rescued kilograms increase | Not run |
| AT-015 | FR-028 | Cook a meal whose items have no expiry | `mealsMissingExpiry` can increase. Rescued kilograms do not, for that meal | Code review of `ImpactService` |
| AT-016 | FR-026 | Mark eaten on a recipe tied to an expired item | Cook is blocked | Code review of `cookBlockReason` |
| AT-017 | FR-031 | Enable expiry notify, set an expiry two days out, allow notifications | A notification is scheduled for 09:00 the day before | Not run |
| AT-018 | FR-032 | Load demo week, open Impact, then reset graphs | Charts fill, then cook history clears | Not run |
| AT-019 | FR-034 | Open missing ingredients and tap Add to list | Snackbar only. Shopping list length unchanged | Code review |
| AT-020 | FR-016 | Generate two plans that differ only by weekly budget | No assertion exists. Server source does not read the field | Code review |

`server/scripts/test-recipes.mjs` prints a live `POST /api/generate-recipes` and does not assert. It is not a row in the automated column. `ios/RunnerTests/RunnerTests.swift` has an empty example test.

## 13. Product Limitations

- The five-card deck does not generate recipes from the pantry or the selected course.
- Clarification questions are unused.
- Units, weekly budget, and the allergy warning do not affect what the cook sees.
- Meal-plan dishes can be templates after a model failure without `isDemo` being true.
- Nutrition and GBP prices are estimates. CO₂e is a range, not a measurement.
- There is no account, no sync, and no hosted API.
- iOS against the cleartext local server is unverified.
- README, FEATURES, and APP_REFERENCE disagree with this PRD in the places named in [scope.md](scope.md) section 8.
- Hackathon eligibility that depends on having built the app by running the Learn skills is not established by this document.

## 14. Roadmap

### Immediate improvements

- Drive FR-020 from `POST /api/generate-recipes` and honour the course.
- Show FR-019 or stop returning the unused string.
- Resolve FR-004 and FR-016 by using the fields or removing the controls.
- Align README with FR-008 and FR-020.

### Short-term enhancements

- Ask or delete clarification questions (FR-009).
- Implement FR-034.
- Notify at the end of the cook-mode timer (FR-024).
- Add server tests for health, a 400 body, and the no-key response.
- An accessibility pass on camera, deck, and cook mode.

### Long-term possibilities

- Optional account sync.
- HTTPS and authenticated hosting.
- A documented nutrition dataset with a stated error bound.
- Grocery purchase, only if the product boundary in [scope.md](scope.md) section 8 is explicitly reopened.

These later items are not implemented.
