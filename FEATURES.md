# Plateful — features & impact

Plateful is a mobile app that helps you **cook what you already bought** before it goes in the bin. You photograph your kitchen stock, get recipes and a meal plan built around that pantry, mark meals as eaten, and see how much food you kept out of waste.

Design language: **Sage & Linen**. No login, no social feed, no grocery checkout — the product stays on pantry, cooking, and impact.

---

## Why it matters

| Problem | What Plateful does |
|---|---|
| Food expires unnoticed | Pantry tracks quantity, place, and expiry; flags items inside your reminder window |
| Recipes ignore what’s in the fridge | AI recipes and meal plans start from your pantry |
| “I meant to use that spinach” | Marking a meal eaten deducts stock and records rescues |
| Waste feels abstract | Impact shows rescued kilograms, timing, and a honest CO₂e range |
| Nutrition is guesswork | Eating tab tracks calories, protein, carbs, fat, and fibre from meals you actually cooked |

**In short:** Plateful turns leftover ingredients into meals, keeps a living pantry, and proves food was used in time — not after it spoiled.

---

## Feature map

### 1. Pantry (Food tab)

Your kitchen inventory, stored on the phone.

- Add ingredients by **camera**, **gallery**, or typing.
- AI vision (when the API is live) reads labels and produce; you confirm name, quantity, unit, and expiry before saving.
- Each item has quantity remaining, unit, optional expiry, storage place, and a price estimate (scan price or typical UK shelf price).
- Swipe or edit to update amounts; used-up items move to **Previously used**.
- Expiry badges follow your reminder setting (3, 5, 7, or 14 days).

**Positive:** You always know what’s left and what’s running out — the base for every other feature.

---

### 2. Add to pantry (camera tab)

Centre button on the floating nav.

- Photograph one or more ingredients.
- Confirm or correct what was detected.
- Saves straight into the pantry with the amounts you approve.

**Positive:** Low friction logging so the pantry stays truthful instead of becoming a forgotten list.

---

### 3. Recipes from what you have

- Pick a course (or cook from “use soon” / selected items).
- The app generates **five distinct recipes** that lean on pantry stock.
- Swipe deck to shortlist; open a recipe for steps, ingredients, and nutrition.
- Dish photos come from image search with variety rules so the same picture isn’t reused all week.
- **Cook mode** for step-by-step cooking.
- Mark as eaten: pantry quantities are deducted; near-expiry uses count as **rescued**.

**Positive:** Recipes follow your fridge, not a random recipe site — so you’re more likely to use food before it spoils.

---

### 4. Meal planner (Plan tab)

- Create a multi-day plan from preferences and pantry.
- Monday-first timetable with breakfast / lunch / dinner slots.
- Specific dish names (not “breakfast idea 1”).
- Mark planned meals eaten; plan nutrition resets when you build a **new** plan (Impact history is kept separate).
- Swap, remove, or refresh a meal when life changes.

**Positive:** A week of cooking planned around stock and expiry, not only around cravings.

---

### 5. Impact tab — food rescued

One story: **food kept out of the bin**.

**Definition (shown on the page):**  
`Rescued = used while inside your N-day window.`  
N is your expiry reminder in settings. The flag is stored when you cook.

What’s on the page:

| Piece | What it shows |
|---|---|
| Hero | Lifetime rescued kg, CO₂e as a WRAP-derived range, this week’s aim bar, last 7 days vs last week |
| Caught in time | Share of pantry uses cooked inside the window vs food that still had longer |
| Top rescued foods | Which ingredients you’re actually saving (kg), tap to filter meals |
| Milestones | First rescue, 1 kg saved, 7-day cook streak |
| See history | Month grid + cumulative rescue line |

Trust extras:

- **How we calculate** explains piece weights, the expiry rule, and the CO₂e source.
- Meals with **no expiry dates** are counted and excluded from rescued kg so gaps stay visible.
- After you cook near-expiry food: *“You just kept X kg of Y out of the bin”* and the hero number counts up.
- **Load demo week** in settings fills ~2 weeks of data for demos.

**Positive:** Impact is measurable and honest — kilograms of food used in time, not vanity metrics.

---

### 6. Eating tab — nutrition

Separate from Impact so waste and intake don’t get mixed.

- Calories, protein, carbohydrates, fat, and fibre for **every** meal goal (including Balanced).
- Interactive week: pick a nutrient, tap a day.
- Energy split (protein×4, carbs×4, fat×9); fibre stays in grams.
- Lifetime totals from meals marked eaten.

**Positive:** You see what you actually ate from planned and one-off cooks — useful for goals without inventing fake accuracy.

---

### 7. Food preferences & settings

- Allergies, diets (including Halal/Kosher alongside a style), cuisines, spice, skill, household size, cook time.
- Meal goal (high protein, weight gain/loss, balanced, budget, quick).
- Expiry reminder window and **weekly rescue aim** (0.25 / 0.5 / 1 kg).
- Units, equipment, ask-before-deduct when cooking.
- Reminder preference switches (stored; scheduling is optional/future).

**Positive:** Recipes and plans respect real constraints, so people keep using the app.

---

### 8. Saved recipes

- Heart or shortlist recipes to keep.
- Reopen from the Pantry **Saved** segment without regenerating.

**Positive:** Good pantry matches aren’t lost after one cook.

---

## Summary of positives

1. **Less food waste** — Stock is visible, recipes prefer what’s expiring, and cooking records rescues.
2. **Real pantry tracking** — Quantities go down when you eat; previously used stays in history.
3. **Expiry-aware cooking** — One clear window; rescues only count food used inside it.
4. **Meal planning that fits the fridge** — Plans use pantry selection and preferences, not a blank week.
5. **Nutrition from real meals** — Macros from what you marked eaten, including fibre.
6. **Trustworthy impact** — Separate definitions for rescued kg vs other totals; CO₂e as a cited range, not a fake precision claim.
7. **Demo-ready** — Count-up rescue moment + load demo week for judges and first impressions.
8. **Private & local-first** — Pantry and history live in on-device SQLite; no account required.

---

## What Plateful is not

- Not a supermarket or delivery app.
- Not a social network or calorie-only diet coach.
- Not a live carbon audit of each pepper — CO₂e is an estimate from published WRAP household waste totals.
- Not counting undated food as “rescued” — honesty over inflated numbers.

---

## Quick flow for a demo

1. **Load demo week** (Settings → Kitchen), or scan a few ingredients with expiry dates.  
2. Open **Impact** — hero bars, caught in time, top foods.  
3. Mark a near-expiry meal as eaten — watch the rescue line and count-up.  
4. Open **Eating** — macros for the week.  
5. Show the meal **Plan** built from pantry stock.

---

*For implementation detail and file paths, see `APP_REFERENCE.md`. For Impact calculation rules, see `IMPACT.md`.*
