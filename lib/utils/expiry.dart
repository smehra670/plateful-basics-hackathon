import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';

enum ExpiryUrgency { none, week, day, expired }

abstract final class ExpiryInfo {
  static int? daysLeft(PantryIngredient item) => item.daysUntilExpiry;

  static ExpiryUrgency urgency(
    PantryIngredient item, {
    int soonDays = 7,
  }) {
    final days = daysLeft(item);
    if (days == null) return ExpiryUrgency.none;
    if (days < 0) return ExpiryUrgency.expired;
    if (days <= 1) return ExpiryUrgency.day;
    if (days <= soonDays) return ExpiryUrgency.week;
    return ExpiryUrgency.none;
  }

  static String label(PantryIngredient item) {
    final days = daysLeft(item);
    if (days == null) return 'No expiry set';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Use today';
    if (days == 1) return '1 day left';
    if (days <= 7) return '$days days left';
    return 'Expires in $days days';
  }

  static String kitchenLine(PantryIngredient item) {
    final days = daysLeft(item);
    if (days == null) return 'No expiry set';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }

  static Color color(ExpiryUrgency urgency) {
    return switch (urgency) {
      ExpiryUrgency.expired => AppColors.error,
      ExpiryUrgency.day => AppColors.error,
      ExpiryUrgency.week => AppColors.accent,
      ExpiryUrgency.none => AppColors.textMuted,
    };
  }
}
