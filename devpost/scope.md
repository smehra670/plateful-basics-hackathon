---
doc: scope
status: draft
---

This draft follows the Devpost Learn `2-scope` template. It was written from the existing Plateful repository on 26 October 2026. There is no `devpost/learner-profile.md`, and `1-start` was not run. The sentences below are descriptions of the code, not a learner interview, and they are not evidence that the skill pack built the app. The longer record is [../scope.md](../scope.md).

# Plateful

A phone app that keeps a kitchen inventory, plans meals from that inventory, and records food cooked while it is still inside the cook's own expiry window.

## The Unique Kernel

Rescued food has one rule: an ingredient counts only when it is used while it sits inside the reminder window the cook chose (3, 5, 7, or 14 days). Food with no expiry date is left out of the kilogram total. The carbon figure is a range, 2.5–2.9 kg CO₂e per rescued kilogram, taken from WRAP household-waste totals already cited in the app. The weekly plan is generated from the pantry. The five-card recipe deck is a separate, fixed set of dishes.

## Who It's For

A person who already bought food, watches it age in the fridge, and does not want a recipe site that ignores what they own. Today they remember the spinach too late, search a generic recipe app, and throw it out. Plateful is for that home cook. No account is required. This is an illustrative user, not a research participant.

## The Core Loop

The app opens on the Plan tab. The cook photographs what is in the kitchen, confirms the names, amounts, places, and dates, and those rows stay on the phone. They generate a 3-, 5-, or 7-day plan from that pantry, or they cook one of five fixed egg-and-spinach dishes. They mark the meal eaten. Quantities fall. If the food was inside the reminder window, Impact adds the kilograms.

They come back because the pantry, the current plan, saved recipes, and the cook history are still in the on-device database.

## Inspiration & Identity

[FEATURES.md](../FEATURES.md) names the visual language Sage & Linen. The built theme in [lib/theme/app_theme.dart](../lib/theme/app_theme.dart) uses an off-white ground (`#F7F8F4`), forest green (`#2E6B4E`), Figtree for interface text, and Bricolage Grotesque for display type. Welcome copy is "Make more. Waste less." The repository does not cite an external product URL as a visual reference. Impact cites WRAP UK household food-waste reports; the factors are in [IMPACT.md](../IMPACT.md) and in `lib/widgets/impact_dashboard.dart`.

## Why This Matters to the Learner

Not recorded. No learner profile was written. Do not read this section as a personal statement.

## What "Working" Looks Like

With the local server running and `OPENAI_API_KEY` set, a cook can photograph ingredients, correct the detection, and see those items after a restart. They can generate a multi-day plan of named dishes, open one, mark it eaten, and watch a near-expiry deduction raise the Impact total. Settings can also load about two weeks of demo cooks so the charts are populated without that live cook. The count-up on Impact is the demonstration beat.

The swipe deck working means five named plated meals appear and can be cooked. Those five titles come from [lib/data/chef_showcase_recipes.dart](../lib/data/chef_showcase_recipes.dart). The deck does not ask the model for new dishes.

## The POC Boundary

The current build includes an on-device pantry, photo analysis through the local server, confirm-before-save, an OpenAI meal plan, a fixed five-recipe deck, cook-and-deduct, Impact and Eating, saved recipes, food preferences, and local notifications.

## Later

Point the swipe deck at `POST /api/generate-recipes` so the course and the selected ingredients change the five cards. Show the stored allergy warning. Apply the saved metric/imperial choice. Use the weekly budget the planner already sends. Restore a clarification step if questions should be asked. Alert when a cook-mode timer finishes.

## Explicitly Cut

- Accounts and login. Pantry and history live in the phone database. The app has no user store.
- A social feed, grocery checkout, and subscriptions. [FEATURES.md](../FEATURES.md) keeps the product on pantry, cooking, and impact.
- Counting undated ingredients as rescued. [IMPACT.md](../IMPACT.md) leaves them out of the kilogram total.
- A per-ingredient carbon audit. The screen multiplies rescued kilograms by the fixed 2.5–2.9 range.
