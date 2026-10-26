import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NutritionInfo extends StatelessWidget {
  const NutritionInfo({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _cell('${recipe.calories}', 'kcal'),
          _cell('${recipe.protein.toStringAsFixed(0)}g', 'protein'),
          _cell('${recipe.carbohydrates.toStringAsFixed(0)}g', 'carbs'),
          _cell('${recipe.fat.toStringAsFixed(0)}g', 'fat'),
          _cell('${recipe.sugar.toStringAsFixed(0)}g', 'sugar'),
        ],
      ),
    );
  }

  Widget _cell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.title(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.body(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
