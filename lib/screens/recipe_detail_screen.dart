import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'cook_mode_screen.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/expiry.dart';
import '../utils/pantry_match.dart';
import '../widgets/recipe_photo.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.planDate,
    this.planSlot,
  });

  final Recipe recipe;
  final String? planDate;
  final String? planSlot;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saved = state.savedIds.contains(recipe.id);
    final date = planDate;
    final slot = planSlot;
    final alreadyEaten = date != null &&
        slot != null &&
        state.isPlannedMealCompleted(date, slot);
    final blocked = state.cookBlockReason(recipe);
    final expiredUsed = state.expiredItemsUsedBy(recipe);
    final rescue = _rescueCopy(recipe, state);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.ink,
            actions: [
              IconButton(
                onPressed: () => state.toggleSave(recipe),
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.heart,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: RecipePhoto.of(recipe),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: AppText.h1().copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 22),
                    _ServiceStrip(recipe: recipe),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (blocked != null) ...[
                    _Callout(
                      color: AppColors.error,
                      title: 'Cannot cook this',
                      body: blocked,
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    recipe.description,
                    style: AppText.body(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Callout(
                    color: AppColors.green,
                    title: 'Why this, tonight',
                    body: rescue,
                  ),
                  const SizedBox(height: 24),
                  _MacroRow(recipe: recipe),
                  const SizedBox(height: 32),
                  Text('Mise en place', style: AppText.section()),
                  const SizedBox(height: 8),
                  Text(
                    recipe.missingCount == 0
                        ? 'Everything is already in your kitchen.'
                        : 'Buy ${recipe.missingCount} extra · £${recipe.estimatedAdditionalCostGbp.toStringAsFixed(2)}',
                    style: AppText.body(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.ingredients.map((i) {
                    final match = _pantryMatch(state, i);
                    final urgency = match == null
                        ? null
                        : ExpiryInfo.urgency(match);
                    return _IngredientRow(
                      ingredient: i,
                      fmt: _fmt,
                      expired: urgency == ExpiryUrgency.expired ||
                          expiredUsed.any(
                            (p) => pantryNamesMatch(p.name, i.name),
                          ),
                    );
                  }),
                  const SizedBox(height: 32),
                  Text('The cook', style: AppText.section()),
                  const SizedBox(height: 8),
                  Text(
                    'Follow the heat, the smell, and the colour — not the clock alone.',
                    style: AppText.body(fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(recipe.instructions.length, (index) {
                    final last = index == recipe.instructions.length - 1;
                    return _StepRow(
                      index: index,
                      text: recipe.instructions[index],
                      last: last,
                    );
                  }),
                  if (recipe.plating.trim().isNotEmpty ||
                      recipe.instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Callout(
                      color: AppColors.accent,
                      title: 'How it should look',
                      body: recipe.plating.trim().isNotEmpty
                          ? recipe.plating.trim()
                          : 'Serve immediately. Give it height, a fresh garnish, and a contrasting colour on the plate.',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Callout(
                    color: AppColors.greenDeep,
                    title: 'Don’t bin the rest',
                    body: recipe.wasteTip.trim().isNotEmpty
                        ? recipe.wasteTip.trim()
                        : 'Cool leftovers quickly, box them, and eat within two days — or fold them into tomorrow’s lunch.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Photo is an illustration of the finished dish, not your plate.',
                    style: AppText.body(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: blocked != null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CookModeScreen(recipe: recipe),
                            ),
                          );
                        },
                  child: Text('Start cooking', style: AppText.button()),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: alreadyEaten || blocked != null
                      ? null
                      : () {
                          if (state.preferences.askBeforeDeducting) {
                            _showCookSheet(context, recipe);
                          } else {
                            _cookNow(context, recipe);
                          }
                        },
                  child: Text(
                    alreadyEaten
                        ? 'Meal completed'
                        : blocked != null
                            ? 'Expired ingredients — cannot cook'
                            : 'Mark as eaten',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rescueCopy(Recipe recipe, AppState state) {
    if (recipe.rescueLine.trim().isNotEmpty) return recipe.rescueLine.trim();
    final soon = state.useSoonIngredients
        .where(
          (p) => recipe.ingredients.any(
            (i) => i.inPantry && pantryNamesMatch(i.name, p.name),
          ),
        )
        .map((p) => p.name)
        .toList();
    if (soon.isNotEmpty) {
      return 'This dinner exists to use ${soon.join(', ')} while it still tastes like itself.';
    }
    return 'A waste-first plate: cook what you already bought, skip another supermarket run.';
  }

  PantryIngredient? _pantryMatch(AppState state, RecipeIngredient ingredient) {
    for (final item in state.availableIngredients) {
      if (pantryNamesMatch(item.name, ingredient.name)) return item;
    }
    return null;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _cookNow(BuildContext context, Recipe recipe) async {
    final state = context.read<AppState>();
    final blocked = state.cookBlockReason(recipe);
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final deductions = state.proposedCookDeductions(recipe);
    final summary = await state.confirmCook(
      recipe: recipe,
      deductions: deductions,
      planDate: planDate,
      planSlot: planSlot,
    );
    if (!context.mounted) return;
    HapticFeedback.heavyImpact();
    final rescueLine = summary.hasRescue
        ? 'You just kept ${summary.rescuedKg.toStringAsFixed(2)} kg of ${summary.highlightFood!.toLowerCase()} out of the bin. Open Impact to see it count up.'
        : 'Logged as eaten. Pantry is updated. Add expiry dates to count rescues on Impact.';
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          summary.hasRescue ? 'Food rescued' : 'Nice work!',
          style: AppText.title(),
        ),
        content: Text(rescueLine, style: AppText.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCookSheet(BuildContext context, Recipe recipe) async {
    final state = context.read<AppState>();
    final blocked = state.cookBlockReason(recipe);
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    final deductions = state.proposedCookDeductions(recipe);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm pantry update', style: AppText.title()),
                  const SizedBox(height: 6),
                  Text(
                    'Adjust quantities before we deduct from your pantry.',
                    style: AppText.body(),
                  ),
                  const SizedBox(height: 16),
                  if (deductions.isEmpty)
                    Text(
                      'No matching pantry items to deduct.',
                      style: AppText.body(),
                    )
                  else
                    ...deductions.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.name,
                                style: AppText.label(),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setModal(() {
                                  d.proposedQuantity =
                                      (d.proposedQuantity - 1).clamp(0, d.maxAvailable);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${d.proposedQuantity == d.proposedQuantity.roundToDouble() ? d.proposedQuantity.toInt() : d.proposedQuantity.toStringAsFixed(1)} ${d.unit}',
                              style: AppText.label(),
                            ),
                            IconButton(
                              onPressed: () {
                                setModal(() {
                                  d.proposedQuantity =
                                      (d.proposedQuantity + 1).clamp(0, d.maxAvailable);
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final summary = await state.confirmCook(
                            recipe: recipe,
                            deductions: deductions,
                            planDate: planDate,
                            planSlot: planSlot,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                          final rescueLine = summary.hasRescue
                              ? 'You just kept ${summary.rescuedKg.toStringAsFixed(2)} kg of ${summary.highlightFood!.toLowerCase()} out of the bin. Open Impact to see it count up.'
                              : 'Logged as eaten. Pantry is updated. Add expiry dates to count rescues on Impact.';
                          await showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                summary.hasRescue ? 'Food rescued' : 'Nice work!',
                                style: AppText.title(),
                              ),
                              content: Text(rescueLine, style: AppText.body()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceStrip extends StatelessWidget {
  const _ServiceStrip({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _cell('${recipe.cookingTimeMinutes}', 'minutes'),
        _cell('${recipe.servings}', 'plates'),
        _cell(recipe.difficulty, 'effort'),
      ],
    );
  }

  Widget _cell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppText.title(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.body(fontSize: 11)),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _pill('${recipe.calories}', 'kcal', AppColors.forest),
          _pill(recipe.protein.toStringAsFixed(0), 'protein', AppColors.proteinText),
          _pill(recipe.carbohydrates.toStringAsFixed(0), 'carbs', AppColors.carbsText),
          _pill(recipe.fat.toStringAsFixed(0), 'fat', AppColors.fatText),
          _pill(recipe.fibre.toStringAsFixed(0), 'fibre', AppColors.fibreText),
        ],
      ),
    );
  }

  Widget _pill(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.title(fontSize: 15, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.label(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.color,
    required this.title,
    required this.body,
  });

  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.overline(color: color),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.body(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.fmt,
    required this.expired,
  });

  final RecipeIngredient ingredient;
  final String Function(double) fmt;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.name,
              style: AppText.body(
                color: expired ? AppColors.error : AppColors.textPrimary,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),
          Text(
            '${fmt(ingredient.quantity)} ${ingredient.unit}',
            style: AppText.label(fontSize: 13),
          ),
          const SizedBox(width: 10),
          if (expired)
            Text('Expired', style: AppText.caption(color: AppColors.error))
          else if (ingredient.inPantry)
            const Icon(Icons.check_circle, color: AppColors.forest, size: 18)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.roseSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Buy',
                style: AppText.caption(color: AppColors.roseText),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.last,
  });

  final int index;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: AppText.label(
                    fontSize: 16,
                    color: AppColors.green,
                  ),
                ),
                if (!last)
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.only(top: 6),
                    color: AppColors.greenSoft,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                text,
                style: AppText.body(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
