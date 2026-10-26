import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/expiry.dart';
import '../utils/food_facts.dart';
import 'pantry_photo.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onTap,
    this.onEdit,
    this.selected = false,
    this.soonDays = 7,
  });

  final PantryIngredient ingredient;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool selected;
  final int soonDays;

  @override
  Widget build(BuildContext context) {
    final days = ingredient.daysUntilExpiry;
    final place = _place(ingredient);
    final wash = _wash(ingredient.name);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onEdit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 52,
                height: 52,
                child: ColoredBox(
                  color: wash,
                  child: PantryPhoto(
                    path: ingredient.imageUrl,
                    name: ingredient.name,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.itemTitle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ingredient.isAvailable
                        ? '$place · ${ExpiryInfo.kitchenLine(ingredient)}'
                        : 'Used up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (days != null) _DaysPill(days: days),
          ],
        ),
      ),
    );
  }

  String _place(PantryIngredient item) {
    final raw = (item.storagePlace ?? FoodFacts.storage(item.name)).trim();
    if (raw.isEmpty) return 'Pantry';
    if (raw.toLowerCase() == 'cupboard' || raw.toLowerCase() == 'counter') {
      return 'Pantry';
    }
    return raw;
  }

  Color _wash(String name) {
    return switch (FoodFacts.aisle(name)) {
      'Fruit & veg' => AppColors.sageSoft,
      'Dairy' => AppColors.peachSoft,
      'Meat & fish' => AppColors.roseSoft,
      'Bakery' => AppColors.butterSoft,
      _ => AppColors.skySoft,
    };
  }
}

class _DaysPill extends StatelessWidget {
  const _DaysPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final (fill, ink, label) = switch (days) {
      < 0 => (AppColors.roseSoft, AppColors.roseText, 'Expired'),
      0 => (AppColors.roseSoft, AppColors.roseText, 'Today'),
      1 => (AppColors.roseSoft, AppColors.roseText, '1 day'),
      <= 3 => (AppColors.butterSoft, AppColors.butterText, '$days days'),
      <= 7 => (AppColors.sageSoft, AppColors.forest, '$days days'),
      _ => (AppColors.sageSoft, AppColors.forest, '$days days'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppText.caption(color: ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}
