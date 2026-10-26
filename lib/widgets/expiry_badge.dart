import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_typography.dart';
import '../utils/expiry.dart';

class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.ingredient,
    this.soonDays = 7,
  });

  final PantryIngredient ingredient;
  final int soonDays;

  @override
  Widget build(BuildContext context) {
    final urgency = ExpiryInfo.urgency(ingredient, soonDays: soonDays);
    if (urgency == ExpiryUrgency.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ExpiryInfo.color(urgency),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            urgency == ExpiryUrgency.expired
                ? Icons.error_outline_rounded
                : Icons.warning_amber_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            ExpiryInfo.label(ingredient),
            style: AppText.label(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
