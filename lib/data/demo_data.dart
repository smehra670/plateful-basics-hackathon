import '../models/models.dart';

/// Bundled demonstration content for hackathon demos without API keys.
abstract final class DemoData {
  static const demoLabel = 'Demo';

  static List<DetectedIngredient> get sampleDetectedIngredients => const [
        DetectedIngredient(
          name: 'Eggs',
          quantity: 6,
          unit: 'pcs',
          confidence: 0.95,
        ),
        DetectedIngredient(
          name: 'Tomatoes',
          quantity: 3,
          unit: 'pcs',
          confidence: 0.9,
        ),
        DetectedIngredient(
          name: 'Spinach',
          quantity: 150,
          unit: 'g',
          confidence: 0.85,
        ),
        DetectedIngredient(
          name: 'Cheese',
          quantity: 100,
          unit: 'g',
          confidence: 0.88,
        ),
        DetectedIngredient(
          name: 'Bread',
          quantity: 4,
          unit: 'slices',
          confidence: 0.92,
        ),
      ];

  static List<ClarificationQuestion> get sampleQuestions => const [];

  static List<PantryIngredient> seedPantryIngredients() {
    final now = DateTime.now();
    return [
      PantryIngredient(
        id: 'demo-eggs',
        name: 'Eggs',
        quantityRemaining: 6,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 10)),
        imageUrl:
            'https://images.unsplash.com/photo-1582722875192-cdbfc14d7638?w=400&q=80',
        estimatedUnitValueGbp: 0.25,
        createdAt: now,
        updatedAt: now,
      ),
      PantryIngredient(
        id: 'demo-tomatoes',
        name: 'Tomatoes',
        quantityRemaining: 3,
        unit: 'pcs',
        expiryDate: now.add(const Duration(days: 2)),
        imageUrl:
            'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400&q=80',
        estimatedUnitValueGbp: 0.4,
        createdAt: now,
        updatedAt: now,
      ),
      PantryIngredient(
        id: 'demo-spinach',
        name: 'Spinach',
        quantityRemaining: 150,
        unit: 'g',
        expiryDate: now.add(const Duration(days: 1)),
        imageUrl:
            'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80',
        estimatedUnitValueGbp: 0.01,
        createdAt: now,
        updatedAt: now,
      ),
      PantryIngredient(
        id: 'demo-cheese',
        name: 'Cheese',
        quantityRemaining: 100,
        unit: 'g',
        expiryDate: now.add(const Duration(days: 7)),
        imageUrl:
            'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&q=80',
        estimatedUnitValueGbp: 0.02,
        createdAt: now,
        updatedAt: now,
      ),
      PantryIngredient(
        id: 'demo-bread',
        name: 'Bread',
        quantityRemaining: 4,
        unit: 'slices',
        expiryDate: now.add(const Duration(days: 3)),
        imageUrl:
            'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=400&q=80',
        estimatedUnitValueGbp: 0.15,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<Recipe> get sampleRecipes => [
        Recipe(
          id: 'demo-recipe-1',
          title: 'Spinach & Cheese Omelette',
          description:
              'A fluffy omelette folded around wilted spinach and melted cheese.',
          imageUrl:
              'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80',
          cookingTimeMinutes: 15,
          difficulty: 'Easy',
          calories: 320,
          protein: 22,
          carbohydrates: 4,
          fat: 24,
          servings: 1,
          estimatedAdditionalCostGbp: 0,
          isDemo: true,
          ingredients: const [
            RecipeIngredient(
              name: 'Eggs',
              quantity: 2,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Spinach',
              quantity: 50,
              unit: 'g',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Cheese',
              quantity: 30,
              unit: 'g',
              inPantry: true,
            ),
          ],
          instructions: const [
            'Whisk the eggs in a bowl with a pinch of salt.',
            'Wilt the spinach in a non-stick pan, then set aside.',
            'Pour in the eggs and cook gently until nearly set.',
            'Add spinach and cheese, fold, and finish for 30 seconds.',
          ],
        ),
        Recipe(
          id: 'demo-recipe-2',
          title: 'Tomato & Egg Toast',
          description:
              'Crispy toast topped with soft eggs and juicy tomatoes.',
          imageUrl:
              'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&q=80',
          cookingTimeMinutes: 12,
          difficulty: 'Easy',
          calories: 280,
          protein: 14,
          carbohydrates: 28,
          fat: 12,
          servings: 1,
          estimatedAdditionalCostGbp: 0,
          isDemo: true,
          ingredients: const [
            RecipeIngredient(
              name: 'Bread',
              quantity: 2,
              unit: 'slices',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Eggs',
              quantity: 1,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Tomatoes',
              quantity: 1,
              unit: 'pcs',
              inPantry: true,
            ),
          ],
          instructions: const [
            'Toast the bread until golden.',
            'Fry or poach the egg to your liking.',
            'Slice the tomato and layer on the toast with the egg.',
          ],
        ),
        Recipe(
          id: 'demo-recipe-3',
          title: 'Creamy Spinach Pasta',
          description:
              'Comforting pasta with a light spinach and cheese sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
          cookingTimeMinutes: 25,
          difficulty: 'Easy',
          calories: 450,
          protein: 16,
          carbohydrates: 58,
          fat: 16,
          servings: 2,
          estimatedAdditionalCostGbp: 1.2,
          isDemo: true,
          ingredients: const [
            RecipeIngredient(
              name: 'Spinach',
              quantity: 80,
              unit: 'g',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Cheese',
              quantity: 40,
              unit: 'g',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Pasta',
              quantity: 180,
              unit: 'g',
              inPantry: false,
              estimatedCostGbp: 1.2,
            ),
          ],
          instructions: const [
            'Boil the pasta until al dente.',
            'Sauté spinach until wilted.',
            'Stir in cheese with a splash of pasta water to make a sauce.',
            'Toss pasta through the sauce and serve.',
          ],
        ),
        Recipe(
          id: 'demo-recipe-4',
          title: 'Shakshuka',
          description:
              'Eggs gently poached in a spiced tomato pan sauce.',
          imageUrl:
              'https://images.unsplash.com/photo-1590412200988-a436970781fa?w=800&q=80',
          cookingTimeMinutes: 30,
          difficulty: 'Medium',
          calories: 310,
          protein: 18,
          carbohydrates: 14,
          fat: 20,
          servings: 2,
          estimatedAdditionalCostGbp: 0.8,
          isDemo: true,
          ingredients: const [
            RecipeIngredient(
              name: 'Tomatoes',
              quantity: 3,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Eggs',
              quantity: 3,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Cumin',
              quantity: 1,
              unit: 'tsp',
              inPantry: false,
              estimatedCostGbp: 0.8,
            ),
          ],
          instructions: const [
            'Chop tomatoes and simmer into a thick sauce.',
            'Season with cumin and a pinch of salt.',
            'Make wells and crack in the eggs.',
            'Cover until whites are set, then serve with bread if you like.',
          ],
        ),
        Recipe(
          id: 'demo-recipe-5',
          title: 'Cheesy Vegetable Breakfast Bake',
          description:
              'A one-dish bake of eggs, greens, tomatoes, and cheese.',
          imageUrl:
              'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&q=80',
          cookingTimeMinutes: 35,
          difficulty: 'Easy',
          calories: 380,
          protein: 24,
          carbohydrates: 12,
          fat: 26,
          servings: 2,
          estimatedAdditionalCostGbp: 0,
          isDemo: true,
          ingredients: const [
            RecipeIngredient(
              name: 'Eggs',
              quantity: 3,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Spinach',
              quantity: 60,
              unit: 'g',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Tomatoes',
              quantity: 2,
              unit: 'pcs',
              inPantry: true,
            ),
            RecipeIngredient(
              name: 'Cheese',
              quantity: 40,
              unit: 'g',
              inPantry: true,
            ),
          ],
          instructions: const [
            'Preheat the oven to 180°C.',
            'Layer spinach and chopped tomatoes in a small baking dish.',
            'Whisk eggs, pour over, and scatter cheese on top.',
            'Bake for 20–25 minutes until set and golden.',
          ],
        ),
      ];

  static AnalyseImageResult analyseDemo() {
    return AnalyseImageResult(
      ingredients: sampleDetectedIngredients,
      questions: sampleQuestions,
      isDemo: true,
    );
  }

  static List<Recipe> recipesForPantry(List<PantryIngredient> pantry) {
    final names = pantry
        .where((p) => p.isAvailable)
        .map((p) => p.normalizedName)
        .toSet();

    return sampleRecipes.map((recipe) {
      final updatedIngredients = recipe.ingredients.map((ing) {
        final inPantry = names.contains(ing.name.trim().toLowerCase());
        return RecipeIngredient(
          name: ing.name,
          quantity: ing.quantity,
          unit: ing.unit,
          inPantry: inPantry,
          estimatedCostGbp: inPantry ? 0 : (ing.estimatedCostGbp > 0 ? ing.estimatedCostGbp : 1.0),
        );
      }).toList();

      final missing = updatedIngredients.where((i) => !i.inPantry).toList();
      if (missing.length > 2) {
        // Prefer demo recipes that fit; clamp by marking extras as pantry
        // for demo continuity when pantry is sparse.
      }

      final cost = missing.fold<double>(0, (s, i) => s + i.estimatedCostGbp);
      return Recipe(
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: recipe.imageUrl,
        cookingTimeMinutes: recipe.cookingTimeMinutes,
        difficulty: recipe.difficulty,
        calories: recipe.calories,
        protein: recipe.protein,
        carbohydrates: recipe.carbohydrates,
        fat: recipe.fat,
        servings: recipe.servings,
        ingredients: updatedIngredients,
        instructions: recipe.instructions,
        estimatedAdditionalCostGbp: cost,
        isDemo: true,
        assetImage: recipe.assetImage,
      );
    }).where((r) => r.missingCount <= 2).take(5).toList();
  }
}
