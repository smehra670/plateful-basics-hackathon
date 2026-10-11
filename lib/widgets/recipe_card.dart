import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isSaved,
    required this.onHeart,
    this.compact = false,
  });

  final Recipe recipe;
  final bool isSaved;
  final VoidCallback onHeart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: compact ? 5 : 63,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: recipe.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.creamDark),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.sageMuted,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: AppColors.green,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _HeartButton(isSaved: isSaved, onTap: onHeart),
                ),
                if (recipe.isDemo)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Demo',
                        style: AppText.label(
                          fontSize: 11,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: compact ? 4 : 37,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(fontSize: 13),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.local_fire_department_outlined,
                        label: '${recipe.calories} kcal',
                      ),
                      _MetaChip(
                        icon: Icons.fitness_center_outlined,
                        label: '${recipe.protein.toStringAsFixed(0)}g P',
                      ),
                      _MetaChip(
                        icon: Icons.grain_outlined,
                        label:
                            '${recipe.carbohydrates.toStringAsFixed(0)}g C',
                      ),
                      _MetaChip(
                        icon: Icons.water_drop_outlined,
                        label: '${recipe.fat.toStringAsFixed(0)}g F',
                      ),
                      _MetaChip(
                        icon: Icons.schedule,
                        label: '${recipe.cookingTimeMinutes} min',
                      ),
                      _MetaChip(
                        icon: Icons.payments_outlined,
                        label:
                            '+£${recipe.estimatedAdditionalCostGbp.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: recipe.missingCount == 0
                          ? AppColors.sageMuted
                          : AppColors.peachSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      recipe.availabilityBadge,
                      style: AppText.label(
                        fontSize: 12,
                        color: recipe.missingCount == 0
                            ? AppColors.green
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeGridCard extends StatelessWidget {
  const RecipeGridCard({
    super.key,
    required this.recipe,
    required this.isSaved,
    required this.onTap,
    required this.onHeart,
    this.onRemove,
  });

  final Recipe recipe;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onHeart;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.sageMuted,
                      child: const Icon(Icons.restaurant, color: AppColors.green),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _HeartButton(isSaved: isSaved, onTap: onHeart),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.cookingTimeMinutes} min · +£${recipe.estimatedAdditionalCostGbp.toStringAsFixed(2)}',
                    style: AppText.body(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isSaved),
              color: isSaved ? AppColors.heart : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppText.label(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
