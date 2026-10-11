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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition (estimates per serving)',
            style: AppText.label(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _cell('${recipe.calories}', 'kcal'),
              _cell('${recipe.protein.toStringAsFixed(0)}g', 'protein'),
              _cell('${recipe.carbohydrates.toStringAsFixed(0)}g', 'carbs'),
              _cell('${recipe.fat.toStringAsFixed(0)}g', 'fat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.title(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: AppText.body(fontSize: 11)),
        ],
      ),
    );
  }
}
