# Plateful — complete app reference

This document describes every user-facing feature, design decision, data rule, and backend behaviour in the current codebase. File paths are relative to the project root. Line numbers point at the implementation so the description can be checked against the code.

The shorter `README.md` is a setup guide. A few lines in it are older than the app (it still says the app opens on AI Chef, and that the default API URL is the Android emulator address). This file follows the code.

---

## 1. What the app is

Plateful is a mobile app that reduces food waste. You photograph what is in the kitchen, the app keeps a pantry with expiry dates, it writes recipes around that stock, and it builds a multi-day meal plan. When you mark a meal as eaten, quantities come out of the pantry and an impact screen records calories, money kept, and food used before it expired.

There is no login, no social feed, no grocery checkout, and no push notifications. Reminder switches exist in settings, but they only save preferences. They do not schedule notifications.

| Layer | Technology | Where |
|---|---|---|
| App | Flutter, Dart SDK `^3.13.5`, Material 3 | `pubspec.yaml`, `lib/` |
| State | `provider` `ChangeNotifier` | `lib/state/app_state.dart` |
| Local data | SQLite via `sqflite`, database `plateful.db`, schema version 5 | `lib/data/database.dart` |
| Photos | `camera`, `image_picker`, `flutter_image_compress`, `permission_handler` | `lib/screens/pantry_import_screen.dart` |
| Backend | Node.js 18+, Express, TypeScript, Zod | `server/` |
| AI | OpenAI chat + vision. Default model `gpt-6-luna` | `server/src/openai.ts`, `server/.env.example` |
| Dish photos | SerpAPI, Pexels, TheMealDB, then keyword fallbacks | `server/src/images.ts` |

App version in `pubspec.yaml`: `1.0.0+1`. Package name: `plateful`. Description: “Plateful — cut food waste with AI, scanning, and saved lists.”

---

## 2. How the app starts

`lib/main.dart`

1. Flutter binds, then the status bar is transparent with dark icons and the system navigation bar is cream (`AppColors.cream`, which is the same token as `ground`).
2. `PlatefulBoot` creates one `AppState` and calls `init()`.
3. While the database and health check are running, the screen is a loading view with the message **Opening**.
4. If the user has never tapped **Get started**, `WelcomeScreen` is shown. Continuing writes `{seen: true}` under the settings key `welcome_v1`.
5. After that, the home is `AppShell`.

`AppState.init()` (`lib/state/app_state.dart`, lines 78–103) does this in order:

1. Probe the API (`/api/health`) across the preferred URL and fallbacks.
2. Set `usingDemoPipeline` when demo mode is forced or OpenAI is not configured on the server.
3. Load food preferences from SQLite.
4. Load a previously generated meal plan from the settings key `meal_plan`, if the JSON still parses.
5. Load pantry, saved recipes, impact stats, and the eaten log.
6. If a plan exists, start filling missing dish photos in the background.
7. If the pantry is empty **and** the app is on the demo pipeline, seed Eggs, Tomatoes, Spinach, Cheese, and Bread.

Live mode with an empty pantry does not seed demo food.

---

## 3. Navigation

The shell is a stack of three tabs that stay alive (`IndexedStack`), plus a floating pill bar. `lib/shell/app_shell.dart`.

| Index | Tab | Screen | Icon |
|---|---|---|---|
| 0 | **Plan** | `PlannerTabScreen` | Phosphor calendar |
| 1 | **Add to pantry** (centre camera) | `PantryImportScreen(asTab: true)` | Phosphor camera in a forest circle |
| 2 | **Pantry** | `PantryScreen` | Phosphor jar |

The bar floats 24px above the home indicator, inset 24px from each side, 64px tall, white at 92% opacity, radius 32, shadow `AppShadows.floating`. Selected side tabs get a sage pill. The camera button grows from 52px to 60px when that tab is active and otherwise has a forest glow. Scrollable screens pad the bottom by `kFloatingNavClearance` (110). `lib/widgets/floating_nav_bar.dart`.

Pushed screens (they cover the shell, they are not tabs):

| Screen | Opened from |
|---|---|
| `AccountSettingsScreen` | Profile circle “P” (`ProfileAvatarButton`) |
| `PlannerSetupScreen` | **Create a meal plan** or the plus on an existing plan |
| `PlannerPantrySelectScreen` | **Choose pantry ingredients** |
| `CourseSelectScreen` | **Find recipes**, **Use N soon**, **Cook N selected**, or **Cook with these** |
| `ChefScreen` | After **Create 5 recipes** |
| `RecipeDetailScreen` | A swipe card result, a saved recipe, or a planned meal |
| `IngredientDetailScreen` | Long-press or edit on a pantry row |
| `PantryConfirmScreen` | After a one-item photo, gallery photos, or typed ingredient |
| `PantryImportScreen` (not as a tab) | **Add from photos** inside the pantry add sheet |

Page transitions on every platform are a fade plus a 12px rise, finishing at 250ms of the 300ms route. `lib/theme/app_theme.dart`, `_FadeSlideUpTransitionsBuilder`.

`Pressable` (`lib/widgets/pressable.dart`) is the shared tap target: it scales slightly and fires a light haptic.

---

## 4. Design system — Sage & Linen

All colour, type, radius, shadow, and component defaults live in `lib/theme/app_theme.dart`. `lib/theme/app_colors.dart` and `lib/theme/app_typography.dart` only re-export `AppColors` and `AppText`. Screens are meant to use these tokens rather than raw hex values.

### 4.1 Palette

| Token | Hex | Role |
|---|---|---|
| `ground` (alias `cream`) | `#F7F8F4` | Scaffold, welcome, system nav |
| `surface` | `#FFFFFF` | Cards, sheets, nav pill |
| `ink` (`textPrimary`) | `#1B2A22` | Headings and body ink |
| `muted` (`textSecondary`) | `#64716A` | Secondary copy |
| `chipText` | `#3A4740` | Chip labels |
| `line` (`border`, `creamDark`) | `#E3E6DE` | Hairlines, segment track |
| `ringBorder` | `#CFD5CC` | Neutral price dots |
| `forest` (`green`, `primary`) | `#2E6B4E` | Buttons, selected day, camera |
| `sageSoft` | `#E5EFE8` | Selected chips, profile circle |
| `sageTrack` | `#D7E5DB` | Progress tracks |
| `sageBorder` | `#8DB59B` | Outlined buttons |
| `peachSoft` / `peachText` | `#FBEDE3` / `#9C4F22` | Protein, allergy callouts |
| `skySoft` / `skyText` | `#E7EEF5` / `#35597A` | Fat / carbs on the plan, drinks |
| `roseSoft` / `roseText` | `#FBE8E6` / `#A3352B` | Errors, hearts, expired, skip |
| `roseBorder` | `#D9776C` | Rose outline |
| `butterSoft` / `butterText` | `#FBF3D6` / `#7A5B0E` | Value-kept accent |
| `imageBg` | `#EFE9DE` | Photo placeholder wash |
| `modeTrack` | `#E6E9E2` | One item / Several toggle |
| `cameraPlaceholder` | `#EEF4EF` | Camera before permission |
| `deckPeek` | `#E8EBE4` | Card under the swipe deck |
| `subtitle` | `#5A655F` | Quiet subtitles |
| `proteinText` | `#7E3E19` | Recipe card protein |
| `carbsText` | `#245840` | Recipe card carbs |
| `fatText` | `#2B4B66` | Recipe card fat |

Shadows are ink-tinted (`#1B2A22` at low alpha), not pure black: `card`, `chip`, `floating`, `primaryGlow` (forest at 30%), `heroCard`, `selectedDay`.

### 4.2 Radii

`AppRadii`: 12, 14, 16, 18, 20, 24, 26, 28, 32, and `pill` (999). Buttons in the theme are stadium-shaped. Recipe swipe cards use 32. Sheets use a 24px top radius.

### 4.3 Type

| Role | Family | Sizes |
|---|---|---|
| Display / headings | **Bricolage Grotesque** (Google Fonts), weight 600, tight negative tracking | h1 32, h1Small 28, card title 24, stat 36, section 18, course title 20 |
| UI / body | **Figtree** | body 15, item title 16, label 14, caption 12, overline 13 with +0.52 tracking, button 17 |
| Recipe detail hero | **Fraunces** for the title and section names; **Plus Jakarta Sans** for the overline “TONIGHT’S PLATE” | `lib/screens/recipe_detail_screen.dart` |

Material text theme is Figtree. Inputs are filled white, 16×14 padding, 16px radius, forest focus border at 1.4px. Snackbars are floating, ink background, white Figtree.

### 4.4 Brand assets

| Asset | Use |
|---|---|
| `assets/images/plateful_logo.png` | Wordmark. `PlatefulLogo` tints it forest with `BlendMode.srcIn`. Welcome uses height 56; planner landing uses 40. |
| `assets/images/plateful_splash.jpg` | Splash image bundled with the app |

Icons are Phosphor (`phosphor_icons`), regular weight, with fill variants for the saved heart and flash-on lightning.

### 4.5 Shared widgets

| Widget | File | What it does |
|---|---|---|
| `PrimaryButton` | `lib/widgets/primary_button.dart` | Full-width forest stadium button, optional loading state |
| `PillButton` | `lib/widgets/pill_button.dart` | Smaller pill action |
| `CircleIconButton` | `lib/widgets/circle_icon_button.dart` |  back, week toggle, new plan |
| `SectionCard` | `lib/widgets/section_card.dart` | Settings groups |
| `ToggleChip` | `lib/widgets/toggle_chip.dart` | Soft, solid, and danger chip variants |
| `RulePill` / `AccountRulePills` | `lib/widgets/rule_pill.dart` | “Never included” (rose) and “Always followed” (sage), drawn from the saved diet and allergies |
| `RecipeCard` | `lib/widgets/recipe_card.dart` | Swipe card: photo, time pill, `+£` cost pill, title, description, kcal/protein/carbs/fat tiles, “You have everything” or “Missing N ingredients” |
| `RecipeGridCard` | same file | Two-column saved grid |
| `RecipePhoto` | `lib/widgets/recipe_photo.dart` | Network image with cache, or a local/asset fallback |
| `PantryPhoto` | `lib/widgets/pantry_photo.dart` | Local cropped photo or placeholder |
| `IngredientCard` | `lib/widgets/ingredient_card.dart` | 56px photo, name, quantity, expiry line, sage fill when selected |
| `ExpiryBadge` | `lib/widgets/expiry_badge.dart` | Coloured expiry chip |
| `PantryChip` | `lib/widgets/pantry_chip.dart` | Horizontal chips under the plan |
| `QuantityLabel` / `formatQuantity` | `lib/widgets/quantity_label.dart` | Drops trailing `.0` |
| `NutritionInfo` / `SegmentedCalorieBar` | `lib/widgets/nutrition_info.dart`, `segmented_calorie_bar.dart` | Macro display helpers |
| `ImpactDashboard` / `ImpactSnapshot` | `lib/widgets/impact_dashboard.dart` | Full impact tab and a compact three-stat strip |
| `SwipeDeck` | `lib/widgets/swipe_deck.dart` | Card swiper |
| `SkeletonBox` / `RecipeLoadingView` | `lib/widgets/skeleton.dart` | Pulsing placeholders and staged loading copy |
| `StaggeredEntrance` | `lib/widgets/staggered_entrance.dart` | Meal rows fade/rise in order |
| `OrganicBackground` | `lib/widgets/organic_background.dart` | Soft blob background (not the main shell) |
| `ClarificationQuestion` | `lib/widgets/clarification_question.dart` | Question UI for the older scan flow |
| `PlannerIcon` | `lib/widgets/planner_icon.dart` | Planner glyph |
| `FloatingNavBar` / `PlatefulBottomNav` | both nav files | Current floating bar, and an older bottom nav that the shell no longer uses |

Loading copy cycles every 2.2 seconds (`lib/widgets/skeleton.dart`):

- Recipes: “Tasting your ingredients” → “Drafting the dishes” → “Finishing the recipes”
- Planner: “Reading your pantry” → “Balancing the week” → “Writing each meal” → “Almost plated”
- Pantry photos: “Looking at your photo” → “Finding each food” → “Adding them to the pantry”
- Boot: “Opening”

---

## 5. Welcome

`lib/screens/welcome_screen.dart`

Cream background, logo, headline **Make more. Waste less.**, subtitle **Photograph your kitchen, plan the week, and use food before it expires.**, button **Get started**. The button fires a light haptic. It is shown once. The flag is `welcome_v1` in `user_settings`.

---

## 6. Plan tab

### 6.1 Empty landing

`lib/screens/planner_tab_screen.dart`, `_PlannerLanding`

Shown when `mealPlan` is null and the planner is not loading.

- Profile button, top right.
- Logo, then **Plan a week around your kitchen.**
- **We’ll use what’s already in your pantry and flag food that should be eaten first.**
- **Create a meal plan** opens setup.
- **Add food to the pantry first** switches to the camera tab.

While `plannerLoading` is true and there is no plan yet, the tab is the planner loading view.

### 6.2 Setup

`lib/screens/planner_setup_screen.dart`. Title **Meal planner** (or **New meal plan** if embedded). Intro: **Choose how you eat this week. Then pick pantry stock and we build the plan.**

If the account has allergies, a peach banner lists them and says they stay excluded.

| Control | Options | Default |
|---|---|---|
| Duration | 3, 5, or 7 days | 7 |
| Meals | breakfast, lunch, dinner, snack. At least one must stay on | breakfast, lunch, dinner |
| People | stepper 1–8 | household size from preferences (default 2) |
| Goals | High protein, Weight gain, Weight loss, Balanced, Budget-friendly, Quick and easy, plus **Low calorie** and **Quick meals** | the saved meal goal, else Balanced |
| Spice | Mild, Medium, Spicy | saved spice, else Medium |
| Cuisines | Italian, Indian, Japanese, Mexican, British, Chinese, Mediterranean, Thai | saved favourites |
| Disliked ingredients | free text chips, removable | saved avoid list |
| Max cooking time | 15, 30, 45, 60 min | saved max, else 30 |
| Weekly budget | optional pounds, hint `e.g. 60` | empty |

**Choose pantry ingredients** continues. If a plan already exists, the app bar also has **Open plan**.

### 6.3 Which pantry stock the plan may use

`lib/screens/planner_pantry_select_screen.dart`. Title **Pantry for this plan**.

Copy: **Choose exactly which ingredients the AI may use. Unselected items stay out of this plan.**

| Mode | Meaning |
|---|---|
| **Entire pantry** (`all`) | Every still-edible item is stock. Expired items are already filtered out by `cookableIngredients`. |
| **Select specific** (`selected`) | Tap cards. **Select all** / **Clear**. Switch **Prioritise these ingredients** (on by default) sends their names as `focusIngredients`. |
| **No pantry** (`none`) | Plan assumes a shop. Copy: **Recipes will assume a shop, with no pantry stock allocated.** |

Generate pops back to the Plan tab (it also closes setup) and calls `AppState.generateMealPlan`. The request includes duration, meals, people, goals, spice, cuisines, dislikes, max minutes, budget, pantry mode, the chosen items (name, quantity, unit, expiry), focus names, start date = now, and the full preference payload.

### 6.4 The timetable

`lib/screens/planner_timetable_screen.dart`. This is the Plan tab once a plan exists (`embedded: true`, so there is no back button and the list clears the floating nav).

**Header.** Overline is the weekday and date in capitals, for example `SATURDAY · 17 OCT`, via `DateFormat('EEEE · d MMM')`. Title **Your plan**. Profile button on the right.

**Tools.** Calendar icon toggles week view (icon becomes a list). Plus starts a new plan via setup. Replacing the plan overwrites the saved JSON.

**Day strip.** One column per plan day. Letter of the weekday, then the date in a 36px circle. The selected day is forest with a white number. Tapping a day in week view returns to the day view. If a plan ever has more than 7 days, the strip scrolls.

**Day nutrition card.** A white card you can swipe. Four slides:

1. Calories eaten, of the day’s planned kcal
2. Protein eaten, grams
3. Carbs eaten, grams
4. Fat eaten, grams

“Eaten” comes from cooking events whose `plan_key` starts with that date, or whose timestamp falls on that date if there is no plan key (`EatenLogEntry.countsOn`). A 6px bar shows eaten ÷ planned, clamped to 1. Dots under the pager mark the slide. Tapping a slide opens the meals that contributed. Under the pager, `AccountRulePills` shows the hard allergy and diet rules.

**Meal rows.** Each planned meal is a row: 64px rounded photo, slot and cook time (**Breakfast · 20 min**), title, calories. If it is marked eaten, the line becomes **320 kcal · eaten** in forest. A small toggle on the photo corner marks it eaten. Long-press opens a sheet:

| Action | Effect |
|---|---|
| Swap meal | Asks the API for one new recipe for that slot, replaces it, clears the eaten flag |
| Use a saved recipe | Picks from Saved. Empty state: **No saved recipes yet.** |
| Refresh image | New photo search: `"{title} {slot} plated food photography"` |
| Remove | Drops that slot from the day. Shopping list is not rebuilt |

Tap opens `RecipeDetailScreen` with `planDate` and `planSlot`, so **Mark as eaten** is tied to that cell.

**In your pantry.** Horizontal chips of `plan.pantryUsage`. **Cook with these** opens course select focused on those names (or the whole cookable pantry if usage is empty).

**Shopping list.** Section title **Shopping list**. Empty copy: **Nothing extra to buy.** Each row is a coloured dot, name, quantity and unit, and a pound cost summed from recipe ingredients that are not in the pantry and share that name.

Price colour (`_priceTone`):

| Cost | Colour |
|---|---|
| £0 | ring grey |
| under £0.75 | forest |
| £0.75 up to £2 | sky |
| £2 and over | peach |

**Week view.** The same meals listed under each date instead of one day.

**Errors.** `plannerError` prints in rose above the list. A thin forest progress bar shows while a swap or image refresh is running.

The plan is stored as JSON in `user_settings` under `meal_plan` and restored on the next launch.

---

## 7. Camera — add to pantry

`lib/screens/pantry_import_screen.dart`

Headline **Add to pantry**. Subtitle **Snap one item, or a whole shelf at once.**

### 7.1 Modes

A two-position control:

| Mode | After the shutter |
|---|---|
| **One item** | Analyse, then **Confirm details**. Hint under the preview: **Frame one food — then set its expiry** |
| **Several at once** | Analyse and add straight into the pantry, then jump to the Pantry tab. Hint: **Fit them all in — each gets added** |

### 7.2 Camera

- Requests camera permission. Uses the back camera, `ResolutionPreset.medium`, audio off.
- Preview sits in a white card (330px tall) inside a 210×190 rounded frame with corner brackets and a forest scan line that travels for 2 seconds and reverses.
- Before the camera is ready, a carrot icon sits on `cameraPlaceholder`.
- If the in-app camera fails, the shutter falls back to the system camera (`image_picker`, quality 85).
- **Flash** toggles torch. Failure copy: **Flash is not available on this camera.**
- **Choose from gallery** requests photos (or storage on older Android) and uses `pickMultiImage`. Gallery always goes to confirm, even in Several mode.
- Shutter is an 80px white ring around a 62px forest circle. It scales to 0.9 while pressed.
- Permission denied: **Camera permission is needed.**
- Camera open failure: **Could not open the camera. Try typing the item instead.**
- Gallery failure: **Could not open photos. Try typing the item instead.**

### 7.3 What happens to the photo

1. Compress to JPEG, quality 55, minimum 900×900, into the temp directory. `pantry_{timestamp}.jpg`.
2. Copy into app documents `pantry_photos/item_{timestamp}.jpg`.
3. `POST /api/analyse-image` (multipart field `image`, timeout 90s). PNG and WebP keep their types; everything else is sent as JPEG.
4. Each detected name is split on “and” or “&” unless it is a known pair: macaroni and cheese, fish and chips, salt and pepper, bangers and mash, peanut butter, sweet and sour.
5. If the photo has one food, that photo is the ingredient image. If the model returns a bounding box used by exactly one food, `cropIngredientPhoto` cuts that region out (3% padding, saved as PNG under `pantry_photos/`). Boxes smaller than 4% of width or height are ignored. Shared or missing boxes mean no crop, so that item has no photo.
6. Status lines while working: **Preparing photos…**, **Reading photo i of n…**, or **Splitting foods in the photo…**

Nothing recognised: **Nothing was recognised. Try a clearer photo or type the item.** Server errors are shown as returned (quota, unreachable, no ingredients, and so on).

### 7.4 Type it instead

Field hint **Or type it — e.g. Bananas**. Plus opens confirm with quantity 1 and unit `pcs`, no photo. Snackbar **Added {name}** appears before confirm.

### 7.5 Confirm details

`lib/screens/pantry_confirm_screen.dart`

**We split N item(s) from your photos. Add expiry so you get a warning before they go off.**

Each draft card has:

- Photo thumbnail
- Editable ingredient name
- Remove (×)
- Quantity and unit
- Expiry chips: **Tomorrow**, **3 days**, **1 week**, **2 weeks**, **Pick date** (today minus 1 day through two years)
- **Stored in**: Fridge, Freezer, Cupboard, Counter

**Add to pantry** merges each draft, switches to the Pantry tab, and shows **Added N item(s) to your pantry**.

Several-at-once skips this screen and uses the detected quantity and unit with no expiry. Snackbar: **Added {names} to your pantry**.

### 7.6 Manual add from the pantry

The Pantry **+** sheet (`lib/screens/pantry_screen.dart`, `_showAddSheet`) is a second way in:

- **Add from photos** pushes the import screen (not as a tab).
- **Or type one in**: Name, Quantity (default 1), Unit (default `pcs`), optional expiry via date picker (today through one year, initial date three days out). Button **Add**.

---

## 8. Pantry tab

`lib/screens/pantry_screen.dart`. Title **My Pantry**. Profile button. Three segments on a cream track: **Ingredients**, **Saved**, **My Impact**. Selected segment is a white chip with forest text. Animation 180ms.

### 8.1 Ingredients

Empty copy: **Your pantry is empty. Use the camera to add photos, or tap + to type one in.**

Sections, in this order, omitted when empty:

| Section | Rule |
|---|---|
| **Expired** | Still in stock, expiry date before today |
| **Use today / tomorrow** | 0 or 1 day left |
| **This week** | 2 days through the reminder window (default 7, set in preferences to 3, 5, 7, or 14) |
| **Later**, or **Available ingredients** if nothing is urgent | In date, or no expiry date |
| **Previously used** | Quantity is 0. Not selectable |

Within a section, items sort by soonest expiry, then name. “Later” with no expiry sorts by name only. `lib/utils/expiry.dart` and `AppState` getters `expiredIngredients`, `urgentIngredients`, `weekIngredients`, `stableIngredients`, `previouslyUsedIngredients`.

Expiry labels: **No expiry set**, **Expired**, **Use today**, **1 day left**, **N days left** (up to 7), **Expires in N days**.

Tap selects a card (sage fill). Long-press or the edit affordance opens the ingredient screen. Used-up rows are not selectable; tap opens detail.

Action on the left:

| Selection | Label |
|---|---|
| Nothing selected, nothing expiring soon | **Find recipes** |
| Nothing selected, some items inside the reminder window | **Use N soon** |
| Some cards selected | **Cook N selected** |

Expired-only selection: snackbar **Expired food cannot be cooked. Pick items that are still in date.**  
Nothing edible at all: **Nothing in the pantry is still edible. Add fresh items first.**

The action switches to the Plan tab index in state (the push covers it) and opens course select. Focus names are the selected cookable items, or the “use soon” names when nothing is selected.

### 8.2 Ingredient detail

`lib/screens/ingredient_detail_screen.dart`

- Photo, expiry badge, delete (trash, pops back).
- **Quantity remaining** with − and + (clamped 0–9999).
- Rows you can edit: name, expiry, storage place.
- Usage history from `ingredient_usage_events`.
- Recipes that used this ingredient, opened into recipe detail.
- Missing id: **Ingredient not found**.

### 8.3 Merge rules

`PantryService.mergeIngredient` and `RecipeConstraints.mergeInto`:

- Match is exact after trim and lowercasing (not the fuzzy matcher).
- New name is title-cased.
- Existing item: quantities add. Unit updates if the new unit is non-empty. Expiry is kept if one already exists; a new expiry only fills a blank. Photo and storage place fill blanks only. They are not overwritten.
- Default estimated unit value is **£0.30** per unit when the scan does not supply one.
- New ids are UUIDs.

### 8.4 Saved

Empty: **Tap the heart on a recipe to save it here.**

Otherwise a two-column grid (`childAspectRatio` 0.72). Heart unsaves. Tap opens recipe detail. Saves are rows in `saved_recipes` pointing at `recipes`.

### 8.5 My Impact

`lib/widgets/impact_dashboard.dart`, numbers from `ImpactService.compute`.

Empty (no cooking events): leaf icon, **Your impact starts here.**, **Mark a planned meal as eaten to track health, food you saved, and how much was still fresh.**

With data, intro **From meals you marked as eaten.**

**Health**

- If the meal goal contains “gain”, “protein”, or “loss”: **Totals on your {goal} plan.** Otherwise: **Totals from the meals you finished.**
- Four tiles: Calories (kcal), Protein (g), Carbs (g), Fat (g). Sums of every cooking event, not only this week.

**Food saved**

| Row | Meaning |
|---|---|
| Saved this week | Kilograms of near-expiry uses in the last 7 days |
| Used before expiry | All-time kilograms of uses flagged near expiry. Shows **0 kg** if there were none |
| Items rescued | Count of those near-expiry usage events |
| Value kept | `quantity used × estimated unit value (£)`, default £0.30 |

Footnote: **Weight and value count pantry items that were due within 7 days when you cooked.** That 7 days is `AppConfig.expirySoonDays`, not the preference window. The preference window only changes how the pantry groups “this week”.

Weight conversion (`ImpactService._qtyToKg`): kg as-is, g ÷ 1000, litres as kg, ml ÷ 1000, anything else (pieces, slices) × 0.08 kg.

**How you cooked**

- **Meals eaten** — count of cooking events.
- **Still fresh** — share of usage events that were *not* near expiry, as a percent. Caption: **Share of pantry items that still had more than a week left when you used them.** Before any pantry deduction: **Still fresh appears once a meal uses pantry items.**

`ImpactSnapshot` is the compact three-number strip (meals, kg saved this week, and either kcal or still-fresh percent). The pantry tab uses the full dashboard.

---

## 9. Recipes from the pantry

### 9.1 Course

`lib/screens/course_select_screen.dart`. Title **What are we making?** Subtitle **Recipes centre on what you picked.**

An ingredient bar shows the focus names (or every cookable item) as letter avatars. **Edit** pops back.

Four cards, default selection **Main course**:

| Id | Title | Subtitle | Colour |
|---|---|---|---|
| `starter` | Starter | Small plates & first courses | peach |
| `main` | Main course | A proper meal | sage |
| `drink` | Drink | Smoothies, juices & sips | sky |
| `dessert` | Dessert | Something sweet to finish | rose |

Under the grid, allergy and diet pills. Button **Create 5 recipes**.

That calls `finalizeScanAndGenerate(fromPantryOnly: true)`. It does not add new ingredients. It generates from cookable stock, optionally focused on the names passed in. Then it replaces the stack above the shell with `ChefScreen`.

### 9.2 Generation rules on the phone

`AppState.generateRecipesFromPantry`:

- Refuses if nothing is still edible: **Nothing in the pantry is still edible. Expired food cannot be cooked — add fresh items first.**
- Focus names that do not fuzzy-match a cookable item are dropped. If none remain, every cookable name is the focus.
- Asks for recipes (default keep **5**). Prefers recipes with at most **2** missing ingredients when at least five of those exist (`ApiClient.generateRecipes`).
- Stores them in SQLite.
- Phase becomes `swiping`, or `idle` if the list is empty.
- Photos refresh one title at a time in the background via `/api/recipe-image`.

### 9.3 Swipe deck

`lib/widgets/swipe_deck.dart`, `flutter_card_swiper`.

- Back, a progress bar, **N of 5 ideas** (the label uses `index + 1`).
- Heart is **Save forever**. Fill heart when saved. Rose icon.
- One card shown. A sage peek sits behind it when more cards remain.
- Swipe right: stamp **SHORTLIST**, added to the shortlist.
- Swipe left: stamp **SKIP**.
- Max tilt 8 degrees. No loop. Up/down swipes are off.
- Undo restores the last like or skip.
- The card itself shows time, extra cost, macros, and the missing-ingredient bar. **Add to list ›** opens a sheet of what you would still need to buy (`showMissingIngredientsSheet`).

Phases (`ChefPhase` in `app_state.dart`): `idle`, `loading`, `swiping`, `results`.

### 9.4 After the deck

`ChefScreen` `_ResultsView`:

- **Nothing shortlisted** or **N shortlisted**.
- Each shortlisted recipe opens detail. You can remove one from the shortlist (`removeFromShortlist`). The heart on the card during the swipe is the permanent save; the shortlist itself is only in memory for this session.

Idle / failure (`_IdleView`):

- **No recipes yet.** with **Pick a course from your pantry and we’ll write dishes around what you have.**
- or **Couldn’t create recipes.** plus the error string.
- **Try again** returns to course select.

If the server was unreachable when Chef opened, a rose banner says to run `.\start-plateful.ps1`, keep USB connected, and **Retry**. Retry calls `reconnectServer()`.

### 9.5 Recipe detail

`lib/screens/recipe_detail_screen.dart`

- Collapsing photo, 340px, pinned app bar in forest.
- Gradient over the photo. Overline **TONIGHT’S PLATE**. Title in Fraunces, 32, white.
- Heart toggles save. Saved heart is peach.
- If the recipe uses an expired pantry item: callout **Cannot cook this** and the reason **You cannot cook this while it uses expired {names}. Bin or replace those items first.**
- Service strip: time, difficulty, servings.
- Description in Fraunces 20.
- **Why this, tonight** — the model’s `rescueLine`, or a sentence naming use-soon ingredients in the dish, or **A waste-first plate: cook what you already bought, skip another supermarket run.**
- Macro pills: calories, protein, carbs, fat (sugar is stored but not in this row).
- **Mise en place.** If nothing is missing: **Everything is already in your kitchen.** Else **Buy N extra · £X.XX**. Each ingredient row shows quantity, whether it is in the pantry, and expired / soon styling when a pantry match exists.
- **The cook.** Subtitle **Follow the heat, the smell, and the colour — not the clock alone.** Numbered steps.
- **How it should look** — `plating`, or **Serve immediately. Give it height, a fresh garnish, and a contrasting colour on the plate.**
- **Don’t bin the rest** — `wasteTip`, or **Cool leftovers quickly, box them, and eat within two days — or fold them into tomorrow’s lunch.**
- Footnote: **Photo is an illustration of the finished dish, not your plate.**

Bottom button:

| State | Label |
|---|---|
| Normal | **Mark as eaten** |
| This plan cell already eaten | **Meal completed** (disabled) |
| Uses expired food | **Expired ingredients — cannot cook** (disabled, rose) |

If **Ask before deducting pantry after cooking** is on (the default), a sheet **Confirm pantry update** lists each deduction. You can change the quantity up to what is in stock. Confirm runs the cook. If the switch is off, it deducts immediately.

Success dialog: **Nice work!** / **Logged as eaten. Pantry and impact are updated.** Heavy haptic.

### 9.6 What “cooked” writes

`PantryService.cookRecipe`, one SQLite transaction:

1. If this plan cell (`date|slot`) already has a cooking event, throw **This planned meal is already marked as eaten.**
2. If the same recipe id was cooked less than 5 seconds ago, throw **This recipe was just marked as cooked.**
3. Insert a `cooking_events` row: servings, calories, protein, carbs, fat, title, optional `plan_key`. Sugar is not stored on the event; the eaten log reads sugar from the joined recipe.
4. For each deduction above zero: subtract from the pantry (anything under 0.05 remaining becomes 0), increment `times_used` and `total_quantity_used`, insert an `ingredient_usage_events` row. `was_near_expiry` is true when the item was inside 7 days (`AppConfig.expirySoonDays`) at the moment of cooking.
5. Upsert the recipe. Update `cooked_recipe_guards`.
6. If there was a plan key, that meal’s `completed` flag is set and the plan JSON is saved.

Name matching for deductions is fuzzy (`pantryNamesMatch`): lowercased, punctuation stripped, simple plural stripping (`ies`→`y`, `oes`/`ses`/`s`). Names under 3 characters only match exactly. Otherwise one name may contain the other. Units convert inside mass (g/kg) or volume (ml, l, tsp 5ml, tbsp 15ml, cup 240ml). Cross-family units are not converted; the number is used as-is. `lib/utils/pantry_match.dart`.

---

## 10. Food preferences

`lib/screens/account_settings_screen.dart`. Opened from the **P** avatar. There is no account name; the letter is the product initial (`lib/widgets/profile_avatar_button.dart`).

Title **Food preferences**. Intro **Allergies and diet are hard rules for every recipe.**

Changes save immediately. After 600ms a forest pill **Saved** fades in for 1.4s.

| Section | Controls | Rule label |
|---|---|---|
| Allergies | Peanuts, Tree nuts, Dairy, Eggs, Gluten, Soy, Shellfish, Fish, Sesame. Multi-select, danger chips | **Never included** |
| Diet | Omnivore, Vegetarian, Vegan, Pescatarian, Halal, Kosher. Single | **Always followed** |
| Ingredients to avoid | Free text, danger chips, removable | none |
| Favourite cuisines | The eight cuisines, multi-select, soft chips | **Nudges, not rules** |
| Cooking | Spice; household 1–8; default servings 1–8; max time 15/30/45/60; skill Beginner / Intermediate / Advanced; meal goal (the six main goals, not the extra planner-only “Low calorie” / “Quick meals”) | |
| Kitchen | Equipment: Oven, Hob, Microwave, Air fryer, Blender, Slow cooker. Default on: Oven, Hob, Microwave. Units: metric or imperial. Expiry flag window: 3, 5, 7, or 14 days. Switch **Ask before deducting pantry after cooking** (default on) | |
| Reminders | Four switches, stored only: Ingredients approaching expiry (default on), Weekly meal plan nudge, Shopping list reminder, Meal prep reminder (those three default off) | |

Defaults if nothing is saved: Omnivore, Medium spice, household 2, servings 2, 30 minutes, Beginner, Balanced, metric, 7-day expiry window. `lib/models/user_preferences.dart`.

`tracksIntake` is true when the goal text contains “gain”, “protein”, or “loss”. That only changes impact copy (kcal vs still-fresh in the snapshot, and the health subtitle).

These preferences are sent to the API as `preferences` on recipe and meal-plan requests (`toRecipePayload`).

---

## 11. Data model

`lib/models/models.dart`, `lib/models/meal_plan.dart`, `lib/models/user_preferences.dart`.

### 11.1 Pantry ingredient

`id`, `name`, `quantityRemaining`, `unit`, optional `expiryDate`, `timesUsed`, `totalQuantityUsed`, optional `imageUrl` (local file path), `estimatedUnitValueGbp` (default 0.3), optional `storagePlace`, `createdAt`, `updatedAt`.

`isAvailable` means quantity &gt; 0. `daysUntilExpiry` is calendar days from today, not 24-hour periods.

### 11.2 Recipe

`id`, `title` (JSON field `name` or `title`), `description`, `imageUrl`, `cookingTimeMinutes`, `difficulty`, `calories`, `protein`, `carbohydrates`, `fat`, `sugar`, `servings`, `ingredients[]`, `instructions[]`, `estimatedAdditionalCostGbp`, `rescueLine`, `plating`, `wasteTip`, `isDemo`, optional `assetImage`, optional `mealSlot`.

Each ingredient: `name`, `quantity`, `unit`, `inPantry`, `estimatedCostGbp`.

Availability badge:

- 0 missing → **Ready to cook** (the card says **You have everything**)
- 1 missing → **Missing 1 ingredient**
- else → **Missing N ingredients**

The phone keeps recipes with more than 2 missing ingredients only when there are not enough stricter ones to fill the deck.

### 11.3 Detection

`DetectedIngredient`: name, optional quantity, unit default `pcs`, confidence default 1, `needsClarification`, optional `box` (`x`, `y`, `w`, `h` as fractions of the image).

`AnalyseImageResult`: ingredients, at most 3 questions, `isDemo`.

`ClarificationQuestion`: id, prompt, 1–6 options, `allowOther` default true. The live camera flow does not show these questions. They belong to the older scan screens (section 16). `AppState.finalizeScanAndGenerate` can still rename a detected item from an answer when that path runs.

### 11.4 Cooking and impact

`CookingEvent`, `EatenLogEntry`, `IngredientUsageEvent`, `CookDeduction`, `ImpactStats`. See sections 8.5 and 9.6.

### 11.5 Meal plan

`MealPlan`: `days[]`, `shoppingList[]`, `pantryUsage[]`, `allergyWarning`.

`PlanDay`: ISO date `YYYY-MM-DD`, meals.

`PlannedMeal`: `slot`, `date`, `recipe`, `completed`. `planKey` is `date|slot`.

`ShoppingItem`: name, quantity, unit, `unconfirmed` (stock quantity was unknown, so the allocator could not be sure it was covered).

`MealPlanRequest`: see section 6.3. `pantryMode` is `all`, `selected`, or `none`. `durationDays` must be 3, 5, or 7. People 1–8.

---

## 12. SQLite

`lib/data/database.dart`. File `plateful.db` in the sqflite databases directory. Version 5.

| Table | Purpose |
|---|---|
| `ingredients` | Pantry |
| `recipes` | Generated and cooked recipes. Ingredients and steps are JSON columns. Sugar added in v2 |
| `recipe_ingredients` | Normalised ingredient rows (schema exists; the service mainly uses the JSON column) |
| `saved_recipes` | `recipe_id`, `saved_at` |
| `scan_sessions` | Optional scan log (id, time, ingredients JSON, answers JSON, demo flag) |
| `cooking_events` | Eaten meals. Nutrition columns and `plan_key` added in v5 |
| `ingredient_usage_events` | One row per deducted ingredient |
| `cooked_recipe_guards` | Last cook time per recipe, for the 5-second guard |
| `user_settings` | Key/value JSON. Added in v4. Keys in use: `user_preferences`, `welcome_v1`, `meal_plan` |

`ingredients.storage_place` was added in v3.

Services: `PantryService`, `RecipeService`, `ImpactService`, `SettingsService`.

---

## 13. App state

`lib/state/app_state.dart` is the single `ChangeNotifier` provided above `MaterialApp`.

Notable fields: `ready`, `usingDemoPipeline`, `reconnecting`, `error`, `ingredients`, `savedRecipes`, `savedIds`, `eatenLog`, `impact`, `pendingImage`, `lastAnalyse`, `clarificationAnswers`, `selectedCourse`, `chefPhase`, `deck`, `shortlist`, `swipeIndex`, `shellTabIndex` (starts at 0, Plan), `preferences`, `mealPlan`, `plannerLoading`, `plannerError`, `welcomeSeen`.

Public actions: `init`, `reconnectServer`, `refreshAll`, `markWelcomeSeen`, `updatePreferences`, `analyseImageFile`, `analysePendingImage`, `answerClarification`, `setDetectedIngredients`, `setSelectedCourse`, `finalizeScanAndGenerate`, `generateRecipesFromPantry`, `likeCurrent`, `rejectCurrent`, `undoSwipe`, `removeFromShortlist`, `toggleSave`, `addIngredient`, `editIngredient`, `removeIngredient`, `proposedCookDeductions`, `confirmCook`, `completePlannedMeal`, `generateMealPlan`, `swapPlannedMeal`, `replacePlannedMealWithSaved`, `removePlannedMeal`, `refreshPlannedImage`, `usageFor`, `recipesForIngredient`, `setShellTab`.

---

## 14. Backend

`server/src/index.ts`. Listens on `0.0.0.0` and `PORT` (default **3001**) so a phone can reach it. CORS is open. JSON body limit 1mb. Image upload limit **8MB** (memory storage). Oversize returns 413 **Image too large. Max 8MB.**

### 14.1 Environment

`server/.env.example`:

| Variable | Role |
|---|---|
| `OPENAI_API_KEY` | Required for live vision and recipes. Never put this in the Flutter app |
| `OPENAI_MODEL` | Default `gpt-6-luna` |
| `SERP_API_KEY` or `SERPAPI_API_KEY` | Google image search for dish photos |
| `PEXELS_API_KEY` | Stock photo search |
| `PORT` | Default 3001 |

Scripts (`server/package.json`): `npm run dev` (`tsx watch`), `npm run build`, `npm start`, `npm run typecheck`.

### 14.2 Endpoints

| Method | Path | Body | Success |
|---|---|---|---|
| GET | `/api/health` | — | `{ ok, openaiConfigured, pexelsConfigured, serpConfigured, demoFallback, model }` |
| POST | `/api/analyse-image` | multipart `image` | `{ ingredients, questions, isDemo? }` |
| POST | `/api/generate-recipes` | JSON, `generateRequestSchema` | `{ recipes, isDemo }` |
| POST | `/api/generate-meal-plan` | JSON, `mealPlanRequestSchema` | meal plan object |
| GET | `/api/recipe-image?q=&mealType=` | — | `{ imageUrl, query }` |

Validation failures are HTTP 400 with Zod flatten details.

OpenAI billing / `insufficient_quota` is HTTP **402** with code `insufficient_quota` and **OpenAI credits ran out. Add billing credit at platform.openai.com, then try again.** Other model failures are HTTP 502. The phone surfaces `error`, else `detail`.

Without an API key, analyse-image and generate-recipes return the demo payload with HTTP 200. The Flutter client **rejects** demo payloads when it expected a live server (`Server returned demo ingredients` / `Server returned demo recipes`). Meal plans do not have that demo fallback: the phone throws if the server or OpenAI is missing, and the server returns 502 if generation fails.

### 14.3 Image analysis

`server/src/openai.ts`, `analyseImageBuffer`.

Vision call. The model must return JSON: foods it can actually see, a quantity and unit, a confidence, `needsClarification` when unsure, and a normalised box. At most 3 clarification questions. Response is checked with `analyseResponseSchema` (at least one ingredient). Combined labels are split by `explodeCombinedFoods`, with the same “keep together” phrases as the app (plus the server’s own list). Up to 3 attempts (`withRetry`). MIME is detected from the buffer, not only the filename.

### 14.4 Recipe generation

`generateRecipes`. The prompt is built from pantry lines (name, quantity, unit, expiry), clarification answers, focus ingredients, meal type, and preferences.

Hard constraints encoded in the server:

- Allergies are never used. `allocate.ts` `recipeHitsAllergen` also scans ingredient names for hint words (peanut/groundnut, tree nuts, dairy words, egg, wheat/barley/rye/seitan, soy/tofu, shellfish, common fish, sesame/tahini). A hit becomes `allergyWarning` on a plan and can drop a recipe.
- Diet type is followed.
- Avoid-list ingredients are excluded.
- Cuisines are a nudge.
- Spice, skill, equipment, units, servings, and max minutes are respected.
- Focus ingredients should actually appear. `recipeUsesFocus` checks that.
- Missing pantry items are flagged `inPantry: false` and given an estimated GBP cost. The recipe’s `estimatedAdditionalCost` is the sum of those.
- Each recipe includes a rescue line (why it saves food), plating, and a waste tip.
- Count defaults to 5, and the schema allows 1–8.
- Macros are recomputed in `server/src/nutrition.ts` from a built-in food table (per-100g calories and macros, unit-to-grams, Atwater check) so the model’s numbers are reconciled rather than trusted blindly.
- `imageSearchQuery` is used to find a photo. If the model returns a non-http image, `keywordFallback` picks a stock URL and tries not to repeat one inside the same response.

Meal types the schema accepts: starter, main, drink, dessert, breakfast, lunch, dinner, snack.

### 14.5 Meal plan generation

`server/src/mealPlan.ts`.

- Dates are `durationDays` ISO dates starting from `startDate` or today, anchored at 12:00 so timezone edges do not skip a day.
- Slots stay in order breakfast, lunch, dinner, snack, filtered to what the user ticked.
- `pantryMode: none` sends an empty pantry into generation.
- Preferences from the form override account preferences where both exist (spice, cuisines, avoid list is merged, servings and household become the plan’s people count, max minutes).
- The model returns one recipe per slot. Invalid JSON is retried. A last-resort `emptyRecipe` exists so a slot is never blank: title based on the slot, 20 minutes, Easy, 400 kcal, three generic steps.
- `allocatePlan` (`server/src/allocate.ts`) sums ingredient needs across the week, skips staples (salt, pepper, water, oil, and similar — the `STAPLE` regex), converts to g / ml / pieces, and subtracts pantry stock by fuzzy name. Output splits into `pantryUsage` (taken from stock) and `shopping` (still short, or `unconfirmed` when the pantry quantity was unknown).
- Dish photos are attached per slot, in small parallel batches on the phone afterwards as well (`_hydratePlanImages`, 3 at a time). If the title search fails, the phone retries with the first two long words plus the slot name.

### 14.6 Dish photography

`server/src/images.ts` (this is the module `index.ts` imports; `server/src/pexels.ts` is an earlier helper with the same export names).

`findRecipeImage` order:

1. In-memory cache, 30 minutes.
2. SerpAPI image search, if a key exists. Queries are cleaned (`buildSearchQuery`) so drink words and junk (logos, packaging, raw ingredients) score poorly. A queue avoids hammering Serp.
3. Pexels search, if a key exists.
4. TheMealDB search by food tokens.
5. `keywordFallback`: a table of food keywords → photo URLs, then slot defaults (breakfast, lunch, dinner, snack, starter, dessert, drink), then a generic food photo.

The same URL is not reused inside one recipe list when a fallback is chosen.

---

## 15. Phone ↔ server connection

`lib/config.dart` and `lib/services/api_client.dart`.

| Dart define | Default | Meaning |
|---|---|---|
| `API_BASE_URL` | `http://127.0.0.1:3001` | First URL tried. This matches USB reverse (`adb reverse tcp:3001 tcp:3001`), which `start-plateful.ps1` sets up |
| `DEMO_MODE` | `false` | If true, health checks fail on purpose and recipes/analysis use `DemoData` with a short delay (900ms analyse, 800ms recipes). Meal plans still require a live server |

Fallbacks tried for 3 seconds each, skipping duplicates: `http://192.168.1.24:3001`, `http://10.0.2.2:3001` (Android emulator host), `http://localhost:3001`.

`start-plateful.ps1` (project root): checks `adb devices`, sets the USB reverse, starts the API if `/api/health` is down, then runs Flutter. The unreachable message in the app tells the user to run that script.

Timeouts: health 3s, analyse 90s, recipes 70s, meal plan 75s, image lookup 12s (server Serp wait 8s).

Cleartext HTTP is allowed in the debug Android manifest (`android:usesCleartextTraffic="true"`) so `http://` to the PC works. Permissions: internet, camera, read media images, read external storage up to API 32. Camera hardware is optional. `android/app/src/main/AndroidManifest.xml`.

---

## 16. Demo data and older screens

### 16.1 Demo content

`lib/data/demo_data.dart` and `server/src/demo.ts`.

Sample detection: Eggs 6 pcs, Tomatoes 3 pcs, Spinach 150 g, Cheese 100 g, Bread 4 slices. Clarification questions in the bundled phone demo are an empty list (`sampleQuestions`). The server demo analyse payload is the same idea and is what the API returns when OpenAI is missing.

`DemoData.recipesForPantry` builds five recipes from whatever names are in the pantry. Seed pantry items are created only when the pipeline is in demo mode and the table is empty (`AppState.init`).

The phone’s current `ApiClient` does **not** silently fall back to demo recipes when the server is down. It throws `unreachableMessage`. Demo recipes run when `DEMO_MODE=true`. The README’s “API down → demo” line describes an older client.

### 16.2 Screens that are not on the current path

These files still compile. Nothing in the shell navigates to them. `ScanScreen` is the only caller, and nothing constructs `ScanScreen`.

| Screen | File | What it was |
|---|---|---|
| `ScanScreen` | `lib/screens/scan_screen.dart` | Pick or take one photo, compress, analyse, then clarification or review |
| `ClarificationScreen` | `lib/screens/clarification_screen.dart` | Up to 3 questions, then ingredient review |
| `IngredientReviewScreen` | `lib/screens/ingredient_review_screen.dart` | Edit detected rows, then continue into generation |
| `PlatefulBottomNav` | `lib/widgets/plateful_bottom_nav.dart` | Older bar. Shell uses `FloatingNavBar` |

`ChefScreen` is still the live swipe UI. It is pushed from course select, not from a tab.

---

## 17. Business rules (tested)

`lib/utils/recipe_constraints.dart`, tests in `test/recipe_constraints_test.dart`. `test/widget_test.dart` is the Flutter widget test.

| Rule | Value |
|---|---|
| Max missing ingredients to prefer a recipe | 2 |
| Max clarification questions kept | 3 |
| Deduction clamp | 0 … available |
| Remaining after cook | never below 0; pantry service also snaps &lt; 0.05 to 0 |
| Merge | add quantity; do not replace an existing expiry with a newer one |
| Expired food | cannot be cooked, cannot be sent as plan stock |
| Double-eat | same `plan_key` cannot be cooked twice; same recipe id cannot be cooked twice inside 5 seconds |
| Near expiry for impact | 7 days (`AppConfig.expirySoonDays`), separate from the user’s 3/5/7/14 display window (`AppConfig.expiryUrgentDays` is 1 and matches “use today / tomorrow”) |

---

## 18. Project map

```
plateful/
├── lib/
│   ├── main.dart                 boot, welcome gate, theme
│   ├── config.dart               API URL, demo flag, expiry windows
│   ├── shell/app_shell.dart      three tabs
│   ├── state/app_state.dart      all session state
│   ├── models/                   pantry, recipe, plan, preferences
│   ├── data/database.dart        SQLite v5
│   ├── data/demo_data.dart       offline sample foods and recipes
│   ├── services/                 API, pantry, recipes, impact, settings
│   ├── screens/                  every page in this document
│   ├── widgets/                  design components
│   ├── theme/app_theme.dart      Sage & Linen
│   └── utils/                    expiry, name match, photo crop, constraints
├── server/src/
│   ├── index.ts                  HTTP API
│   ├── openai.ts                 vision + recipes
│   ├── mealPlan.ts               week plan
│   ├── allocate.ts               pantry vs shopping, allergen hints
│   ├── nutrition.ts              macro table
│   ├── images.ts                 dish photos
│   ├── schemas.ts                Zod contracts
│   └── demo.ts                   keyless responses
├── assets/images/                logo and splash
├── test/
├── start-plateful.ps1            server + USB tunnel + Flutter
└── README.md                     install and run
```

---

## 19. Run

```bash
flutter pub get
cd server && npm install && npm run dev
```

Health: `http://localhost:3001/api/health`.

On a USB Android phone, from the project root:

```powershell
.\start-plateful.ps1
```

Or manually:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001
```

Emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

Same Wi-Fi, replace with the PC’s LAN address. Forced offline sample data:

```bash
flutter run --dart-define=DEMO_MODE=true
```

Checks:

```bash
flutter analyze
flutter test
cd server && npm run typecheck
```

After a new native plugin, stop the app fully. Hot reload does not register it. `flutter clean` then `flutter pub get` then run again.

---

## 20. What the app deliberately does not do

- Accounts, sign-in, or a user name (the avatar is the letter P).
- Cloud sync. Pantry, plan, and prefs stay on the device.
- Real push notifications, even though four reminder toggles are saved.
- Grocery ordering. The shopping list is a list.
- Social features, comments, or sharing.
- Cooking from expired ingredients.
- Silent demo recipes when the live server is simply offline (that path now errors and offers Retry).
- Putting API keys in the Flutter binary.
