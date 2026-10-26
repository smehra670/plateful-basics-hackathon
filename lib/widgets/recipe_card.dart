import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_label.dart';
import 'recipe_photo.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onMissingTap,
    this.expiringCount = 0,
  });

  final Recipe recipe;
  final VoidCallback? onMissingTap;
  final int expiringCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: AppShadows.heroCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight * 0.42).clamp(140.0, 260.0)
              : 260.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: imageHeight, child: _image()),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.cardTitle(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recipe.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(fontSize: 14),
                                  ),
                                  const SizedBox(height: 14),
                                  _macros(),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _missingBar(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _image() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.imageBg,
          child: RecipePhoto.of(recipe),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: _FrostedPill(
            icon: PhosphorIconsRegular.clock,
            label: '${recipe.cookingTimeMinutes} min',
            emphasize: false,
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: _FrostedPill(
            label: '+£${recipe.estimatedAdditionalCostGbp.toStringAsFixed(2)}',
            emphasize: true,
          ),
        ),
        if (expiringCount > 0)
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                'Uses $expiringCount expiring item${expiringCount == 1 ? '' : 's'}',
                style: AppText.caption(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _macros() {
    return Row(
      children: [
        _tile('${recipe.calories}', 'kcal', AppColors.ground, AppColors.ink),
        const SizedBox(width: 6),
        _tile(
          recipe.protein.toStringAsFixed(0),
          'protein',
          AppColors.peachSoft,
          AppColors.proteinText,
        ),
        const SizedBox(width: 6),
        _tile(
          recipe.carbohydrates.toStringAsFixed(0),
          'carbs',
          AppColors.sageSoft,
          AppColors.carbsText,
        ),
        const SizedBox(width: 6),
        _tile(
          recipe.fat.toStringAsFixed(0),
          'fat',
          AppColors.skySoft,
          AppColors.fatText,
        ),
      ],
    );
  }

  Widget _tile(String value, String label, Color background, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missingBar() {
    final missing = recipe.missingCount == 0;
    final background = missing ? AppColors.sageSoft : AppColors.roseSoft;
    final foreground = missing ? AppColors.forest : AppColors.roseText;
    final label = missing ? 'You have everything' : recipe.availabilityBadge;
    return Pressable(
      onTap: missing ? null : onMissingTap,
      semanticLabel: label,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(color: foreground, fontSize: 14).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!missing)
              Text(
                'Add to list ›',
                style: AppText.label(color: foreground, fontSize: 14).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({
    required this.label,
    required this.emphasize,
    this.icon,
  });

  final String label;
  final bool emphasize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.ink),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.caption(
              color: emphasize ? AppColors.forest : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

void showMissingIngredientsSheet(BuildContext context, Recipe recipe) {
  final missing = recipe.missingIngredients;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Missing ingredients', style: AppText.section()),
              const SizedBox(height: 8),
              for (final item in missing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.itemTitle(),
                        ),
                      ),
                      Text(
                        '${formatQuantity(item.quantity)} ${item.unit}',
                        style: AppText.caption(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Add to list',
                onPressed: () {
                  // TODO(data): shopping list is only produced with the meal plan.
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'The shopping list is created with your meal plan.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
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
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.imageBg,
                    child: RecipePhoto.of(recipe),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SavedHeart(isSaved: isSaved, onTap: onHeart),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Pressable(
                        semanticLabel: 'Remove from shortlist',
                        onTap: onRemove,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.x,
                            size: 16,
                            color: AppColors.ink,
                          ),
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

class _SavedHeart extends StatelessWidget {
  const _SavedHeart({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: isSaved ? 'Saved' : 'Save forever',
      toggled: isSaved,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
          size: 16,
          color: AppColors.roseText,
        ),
      ),
    );
  }
}
