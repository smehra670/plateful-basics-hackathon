import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onTap,
  });

  final PantryIngredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final useSoon =
        ingredient.isExpiringSoon(AppConfig.expirySoonDays);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                  if (ingredient.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: ingredient.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _fallback(),
                    )
                  else
                    _fallback(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ingredient.isAvailable
                            ? AppColors.green
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (useSoon)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Use Soon',
                          style: AppText.label(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ingredient.isAvailable
                        ? '${_fmt(ingredient.quantityRemaining)} ${ingredient.unit} remaining'
                        : 'None remaining',
                    style: AppText.body(fontSize: 12),
                  ),
                  Text(
                    'Used ${ingredient.timesUsed} times',
                    style: AppText.body(fontSize: 11),
                  ),
                  if (ingredient.expiryDate != null)
                    Text(
                      _expiryLabel(ingredient.expiryDate!),
                      style: AppText.body(
                        fontSize: 11,
                        color: useSoon ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.sageMuted,
        child: const Icon(Icons.eco_outlined, color: AppColors.green),
      );

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _expiryLabel(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires in 1 day';
    return 'Expires in $days days';
  }
}
