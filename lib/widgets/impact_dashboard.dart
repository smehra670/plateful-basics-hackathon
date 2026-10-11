import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ImpactDashboard extends StatelessWidget {
  const ImpactDashboard({super.key, required this.stats});

  final ImpactStats stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasData) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.eco_outlined, size: 56, color: AppColors.greenSoft),
            const SizedBox(height: 16),
            Text('Your impact starts here.', style: AppText.title()),
            const SizedBox(height: 8),
            Text(
              'Cook a recipe to see meals made, ingredients used, and estimated value utilised.',
              textAlign: TextAlign.center,
              style: AppText.body(),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('My Impact', style: AppText.display(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          'Measured from your cooking events. Estimates are labelled clearly.',
          style: AppText.body(),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _StatCard(
              title: 'Meals cooked',
              value: '${stats.mealsCooked}',
              subtitle: 'Recorded cook events',
            ),
            _StatCard(
              title: 'Ingredients used',
              value: stats.totalIngredientsUsed.toStringAsFixed(1),
              subtitle: 'Sum of deducted quantities',
            ),
            _StatCard(
              title: 'Value utilised',
              value: '£${stats.estimatedValueUtilisedGbp.toStringAsFixed(2)}',
              subtitle: 'Estimate from unit values',
            ),
            _StatCard(
              title: 'Used before expiry',
              value: '${stats.ingredientsUsedBeforeExpiry}',
              subtitle: 'Near-expiry cook uses',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated food waste avoided',
                style: AppText.label(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                stats.estimatedWasteAvoidedKg == null
                    ? 'Estimate unavailable'
                    : '${stats.estimatedWasteAvoidedKg!.toStringAsFixed(2)} kg (proxy)',
                style: AppText.title(fontSize: 22, color: AppColors.green),
              ),
              const SizedBox(height: 8),
              Text(
                'Proxy based only on ingredients consumed while marked Use Soon. '
                'We do not claim all food would otherwise have been wasted.',
                style: AppText.body(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (stats.ingredientsUsedBeforeExpiry /
                          (stats.mealsCooked * 3).clamp(1, 100))
                      .clamp(0.05, 1),
                  minHeight: 8,
                  backgroundColor: AppColors.creamDark,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body(fontSize: 12)),
          const Spacer(),
          Text(value, style: AppText.display(fontSize: 24)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.body(fontSize: 11)),
        ],
      ),
    );
  }
}
