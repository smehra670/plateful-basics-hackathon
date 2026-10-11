import 'package:flutter_test/flutter_test.dart';
import 'package:plateful/data/demo_data.dart';
import 'package:plateful/models/models.dart';
import 'package:plateful/utils/recipe_constraints.dart';

void main() {
  group('RecipeConstraints', () {
    test('demo recipes never require more than two missing ingredients', () {
      final pantry = DemoData.seedPantryIngredients();
      final recipes = DemoData.recipesForPantry(pantry);
      expect(recipes.length, 5);
      for (final recipe in recipes) {
        expect(
          RecipeConstraints.hasAllowedMissingCount(recipe),
          isTrue,
          reason: recipe.title,
        );
      }
    });

    test('clarification questions are limited to three', () {
      final many = List.generate(
        5,
        (i) => ClarificationQuestion(
          id: 'q$i',
          prompt: 'Q$i?',
          options: const ['A', 'B'],
        ),
      );
      expect(RecipeConstraints.limitQuestions(many), hasLength(3));
    });

    test('deduction never goes negative', () {
      expect(RecipeConstraints.clampDeduction(10, 4), 4);
      expect(RecipeConstraints.clampDeduction(-1, 4), 0);
      expect(RecipeConstraints.remainingAfterCook(6, 2), 4);
      expect(RecipeConstraints.remainingAfterCook(1, 5), 0);
    });

    test('merge preserves existing expiry', () {
      final now = DateTime.now();
      final existing = PantryIngredient(
        id: '1',
        name: 'Eggs',
        quantityRemaining: 2,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
      );
      final merged = RecipeConstraints.mergeInto(
        existing,
        addQuantity: 3,
        newExpiry: now.add(const Duration(days: 1)),
      );
      expect(merged.quantityRemaining, 5);
      expect(merged.expiryDate, existing.expiryDate);
    });

    test('merge finds existing by normalized name', () {
      final now = DateTime.now();
      final pantry = [
        PantryIngredient(
          id: '1',
          name: 'Tomatoes',
          quantityRemaining: 1,
          unit: 'pcs',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(
        RecipeConstraints.findMergeTarget(pantry, ' tomatoes ')?.id,
        '1',
      );
    });
  });

  group('ImpactStats', () {
    test('empty impact has no data', () {
      const stats = ImpactStats(
        mealsCooked: 0,
        totalIngredientsUsed: 0,
        estimatedValueUtilisedGbp: 0,
        ingredientsUsedBeforeExpiry: 0,
      );
      expect(stats.hasData, isFalse);
    });
  });

  group('Demo analyse', () {
    test('demo analyse asks at most three questions', () {
      final result = DemoData.analyseDemo();
      expect(result.questions.length, lessThanOrEqualTo(3));
      expect(result.ingredients, isNotEmpty);
    });
  });
}
