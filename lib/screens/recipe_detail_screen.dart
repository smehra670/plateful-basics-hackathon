import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/nutrition_info.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final saved = state.savedIds.contains(recipe.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.cream,
            actions: [
              IconButton(
                onPressed: () => state.toggleSave(recipe),
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? AppColors.heart : AppColors.textPrimary,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: AppColors.sageMuted,
                  child: const Icon(Icons.restaurant, size: 64),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: AppText.display(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(recipe.description, style: AppText.body()),
                  const SizedBox(height: 12),
                  Text(
                    '${recipe.cookingTimeMinutes} min · ${recipe.servings} servings · ${recipe.difficulty}',
                    style: AppText.label(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  NutritionInfo(recipe: recipe),
                  const SizedBox(height: 24),
                  Text('Already in your pantry', style: AppText.title()),
                  const SizedBox(height: 10),
                  ...recipe.availableIngredients.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '${_fmt(i.quantity)} ${i.unit} ${i.name}',
                            style: AppText.body(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recipe.availableIngredients.isEmpty)
                    Text('None matched yet.', style: AppText.body()),
                  const SizedBox(height: 20),
                  Text('Things you\'ll need', style: AppText.title()),
                  const SizedBox(height: 10),
                  ...recipe.missingIngredients.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_fmt(i.quantity)} ${i.unit} ${i.name} — approx. £${i.estimatedCostGbp.toStringAsFixed(2)}',
                              style: AppText.body(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recipe.missingIngredients.isEmpty)
                    Text('Ready to cook — nothing extra.', style: AppText.body()),
                  const SizedBox(height: 12),
                  Text(
                    'Estimated additional spend: £${recipe.estimatedAdditionalCostGbp.toStringAsFixed(2)}',
                    style: AppText.label(color: AppColors.green),
                  ),
                  const SizedBox(height: 28),
                  Text('Instructions', style: AppText.title()),
                  const SizedBox(height: 12),
                  ...List.generate(recipe.instructions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.sageMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: AppText.label(color: AppColors.green),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.instructions[index],
                              style: AppText.body(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => _showCookSheet(context, recipe),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text('Cooked It!', style: AppText.button()),
          ),
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _showCookSheet(BuildContext context, Recipe recipe) async {
    final state = context.read<AppState>();
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
                          await state.confirmCook(
                            recipe: recipe,
                            deductions: deductions,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                          await showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text('Nice work!', style: AppText.title()),
                              content: Text(
                                'Another delicious meal made.',
                                style: AppText.body(),
                              ),
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
