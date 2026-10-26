import '../models/models.dart';
import 'pantry_match.dart';

/// Pure helpers for critical business rules (unit-tested).
abstract final class RecipeConstraints {
  static const maxMissingIngredients = 2;
  static const maxClarificationQuestions = 3;

  static bool hasAllowedMissingCount(Recipe recipe) =>
      recipe.missingCount <= maxMissingIngredients;

  static List<ClarificationQuestion> limitQuestions(
    List<ClarificationQuestion> questions,
  ) =>
      questions.take(maxClarificationQuestions).toList();

  static double clampDeduction(double proposed, double available) {
    if (proposed < 0) return 0;
    if (proposed > available) return available;
    return proposed;
  }

  static double remainingAfterCook(double current, double used) {
    final next = current - used;
    return next < 0 ? 0 : next;
  }

  static String normalizeName(String name) => name.trim().toLowerCase();

  static PantryIngredient? findMergeTarget(
    List<PantryIngredient> pantry,
    String name,
  ) {
    for (final item in pantry) {
      if (pantryNamesMatch(item.name, name)) return item;
    }
    return null;
  }

  /// Merge quantity; never overwrite existing expiry with a new one.
  static PantryIngredient mergeInto(
    PantryIngredient existing, {
    required double addQuantity,
    DateTime? newExpiry,
  }) {
    return existing.copyWith(
      quantityRemaining: existing.quantityRemaining + addQuantity,
      expiryDate: existing.expiryDate ?? newExpiry,
      updatedAt: DateTime.now(),
    );
  }
}
