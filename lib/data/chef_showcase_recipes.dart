import '../models/models.dart';
import '../utils/pantry_match.dart';

/// Five swipe-deck meals for the recipe generator only.
/// The weekly planner does not use this list.
abstract final class ChefShowcaseRecipes {
  static const images = [
    'assets/images/chef_1.jpg',
    'assets/images/chef_2.jpg',
    'assets/images/chef_3.jpg',
    'assets/images/chef_4.webp',
    'assets/images/chef_5.jpg',
  ];

  static List<Recipe> forPantry(List<PantryIngredient> pantry) {
    return [
      _recipe(
        index: 0,
        title: 'Cheesy Spinach Scrambled Eggs on Toast',
        description:
            'Soft scrambled eggs with wilted spinach and melted cheddar on toast.',
        minutes: 15,
        calories: 489,
        protein: 28.9,
        carbohydrates: 34.7,
        fat: 26.1,
        sugar: 5.5,
        fibre: 3.4,
        cost: 0.4,
        rescueLine: 'Uses spinach while the leaves are still good.',
        plating: 'Pile the eggs on toast and finish with black pepper.',
        wasteTip: 'Wilt leftover spinach in the pan instead of throwing it out.',
        ingredients: const [
          RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs', inPantry: false, estimatedCostGbp: 0.56),
          RecipeIngredient(name: 'Spinach', quantity: 80, unit: 'g', inPantry: false, estimatedCostGbp: 0.64),
          RecipeIngredient(name: 'Cheese', quantity: 30, unit: 'g', inPantry: false, estimatedCostGbp: 0.26),
          RecipeIngredient(name: 'Bread', quantity: 2, unit: 'slices', inPantry: false, estimatedCostGbp: 0.24),
          RecipeIngredient(name: 'Butter', quantity: 5, unit: 'g', inPantry: false, estimatedCostGbp: 0.04),
          RecipeIngredient(name: 'Milk', quantity: 20, unit: 'ml', inPantry: false, estimatedCostGbp: 0.02),
        ],
        instructions: const [
          'Toast the bread until golden.',
          'Beat the eggs with the milk, salt and pepper.',
          'Melt the butter in a pan on low heat and wilt the spinach.',
          'Pour in the eggs and scramble slowly until just set.',
          'Fold through the grated cheese, then spoon onto the toast.',
        ],
        pantry: pantry,
      ),
      _recipe(
        index: 1,
        title: 'Spinach, Egg & Cheese Toastie',
        description:
            'A pressed toastie with scrambled egg, spinach and cheddar.',
        minutes: 12,
        calories: 476,
        protein: 23.4,
        carbohydrates: 32.3,
        fat: 28.2,
        sugar: 4.2,
        fibre: 2.7,
        cost: 0.35,
        rescueLine: 'Turns a handful of spinach and cheese into lunch.',
        plating: 'Cut on the diagonal while the cheese is still stretching.',
        wasteTip: 'Use the last slices of bread even if they are a little dry.',
        ingredients: const [
          RecipeIngredient(name: 'Bread', quantity: 2, unit: 'slices', inPantry: false, estimatedCostGbp: 0.24),
          RecipeIngredient(name: 'Eggs', quantity: 1, unit: 'pcs', inPantry: false, estimatedCostGbp: 0.28),
          RecipeIngredient(name: 'Cheese', quantity: 40, unit: 'g', inPantry: false, estimatedCostGbp: 0.34),
          RecipeIngredient(name: 'Spinach', quantity: 50, unit: 'g', inPantry: false, estimatedCostGbp: 0.4),
          RecipeIngredient(name: 'Butter', quantity: 10, unit: 'g', inPantry: false, estimatedCostGbp: 0.08),
        ],
        instructions: const [
          'Lightly scramble the egg in a teaspoon of butter.',
          'Wilt the spinach in the same pan until it collapses.',
          'Butter one side of each slice. Build the toastie egg-side in with cheese and spinach.',
          'Fry or press until both sides are golden and the cheese melts.',
          'Rest 30 seconds, then slice.',
        ],
        pantry: pantry,
      ),
      _recipe(
        index: 2,
        title: 'Cheesy Egg-in-a-Hole',
        description:
            'Toast with a fried egg in the centre and a cheddar lid.',
        minutes: 10,
        calories: 309,
        protein: 14.9,
        carbohydrates: 16.2,
        fat: 20.5,
        sugar: 2.1,
        fibre: 1.3,
        cost: 0.25,
        rescueLine: 'One egg and one slice, cooked before they stale.',
        plating: 'Serve in the pan or on a warm plate with the cut-out toast on the side.',
        wasteTip: 'Fry the bread circle you cut out so nothing is wasted.',
        ingredients: const [
          RecipeIngredient(name: 'Bread', quantity: 1, unit: 'slices', inPantry: false, estimatedCostGbp: 0.12),
          RecipeIngredient(name: 'Eggs', quantity: 1, unit: 'pcs', inPantry: false, estimatedCostGbp: 0.28),
          RecipeIngredient(name: 'Cheese', quantity: 20, unit: 'g', inPantry: false, estimatedCostGbp: 0.17),
          RecipeIngredient(name: 'Butter', quantity: 10, unit: 'g', inPantry: false, estimatedCostGbp: 0.08),
          RecipeIngredient(name: 'Spinach', quantity: 20, unit: 'g', inPantry: false, estimatedCostGbp: 0.16),
        ],
        instructions: const [
          'Cut a hole in the centre of the slice. Butter both sides.',
          'Fry the slice in butter until one side is golden, then flip.',
          'Crack the egg into the hole and cook until the white sets.',
          'Scatter cheese and a few spinach leaves over the top to wilt.',
          'Cover for 30 seconds so the cheese melts, then serve.',
        ],
        pantry: pantry,
      ),
      _recipe(
        index: 3,
        title: 'Spinach & Cheese Omelette with Toast',
        description:
            'A folded omelette packed with spinach and cheddar, with toast.',
        minutes: 15,
        calories: 555,
        protein: 35.2,
        carbohydrates: 20.5,
        fat: 36.9,
        sugar: 2.8,
        fibre: 3.0,
        cost: 0.3,
        rescueLine: 'A proper plate for spinach that is close to its date.',
        plating: 'Fold the omelette onto the plate and lean toast against it.',
        wasteTip: 'Any extra spinach can go in the pan for the last 20 seconds.',
        ingredients: const [
          RecipeIngredient(name: 'Eggs', quantity: 3, unit: 'pcs', inPantry: false, estimatedCostGbp: 0.84),
          RecipeIngredient(name: 'Spinach', quantity: 100, unit: 'g', inPantry: false, estimatedCostGbp: 0.8),
          RecipeIngredient(name: 'Cheese', quantity: 40, unit: 'g', inPantry: false, estimatedCostGbp: 0.34),
          RecipeIngredient(name: 'Butter', quantity: 10, unit: 'g', inPantry: false, estimatedCostGbp: 0.08),
          RecipeIngredient(name: 'Bread', quantity: 1, unit: 'slices', inPantry: false, estimatedCostGbp: 0.12),
        ],
        instructions: const [
          'Toast the bread. Beat the eggs with salt and pepper.',
          'Melt butter, wilt the spinach, then pour in the eggs.',
          'Draw the edges in as they set, keeping the middle soft.',
          'Add cheese down the centre and fold.',
          'Slide onto a plate with the toast.',
        ],
        pantry: pantry,
      ),
      _recipe(
        index: 4,
        title: 'Savoury Cheesy French Toast',
        description:
            'Egg-soaked bread fried until golden, with cheese and spinach.',
        minutes: 18,
        calories: 534,
        protein: 29.2,
        carbohydrates: 35.2,
        fat: 30.7,
        sugar: 6.1,
        fibre: 2.5,
        cost: 0.45,
        rescueLine: 'The right cook for bread that is a day past its best.',
        plating: 'Stack the slices and let the cheese sit on top so it melts.',
        wasteTip: 'Stale bread soaks better than fresh — use the end of the loaf.',
        ingredients: const [
          RecipeIngredient(name: 'Bread', quantity: 2, unit: 'slices', inPantry: false, estimatedCostGbp: 0.24),
          RecipeIngredient(name: 'Eggs', quantity: 2, unit: 'pcs', inPantry: false, estimatedCostGbp: 0.56),
          RecipeIngredient(name: 'Milk', quantity: 60, unit: 'ml', inPantry: false, estimatedCostGbp: 0.07),
          RecipeIngredient(name: 'Cheese', quantity: 30, unit: 'g', inPantry: false, estimatedCostGbp: 0.26),
          RecipeIngredient(name: 'Butter', quantity: 10, unit: 'g', inPantry: false, estimatedCostGbp: 0.08),
          RecipeIngredient(name: 'Spinach', quantity: 40, unit: 'g', inPantry: false, estimatedCostGbp: 0.32),
        ],
        instructions: const [
          'Beat eggs with milk, salt and pepper in a shallow dish.',
          'Soak each slice for 20 seconds a side.',
          'Fry in butter until both sides are deep golden.',
          'Top with cheese and spinach, cover briefly to melt and wilt.',
          'Serve hot.',
        ],
        pantry: pantry,
      ),
    ];
  }

  static Recipe _recipe({
    required int index,
    required String title,
    required String description,
    required int minutes,
    required int calories,
    required double protein,
    required double carbohydrates,
    required double fat,
    required double sugar,
    required double fibre,
    required double cost,
    required String rescueLine,
    required String plating,
    required String wasteTip,
    required List<RecipeIngredient> ingredients,
    required List<String> instructions,
    required List<PantryIngredient> pantry,
  }) {
    final tagged = [
      for (final ingredient in ingredients)
        RecipeIngredient(
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          inPantry: pantry.any((item) => pantryNamesMatch(item.name, ingredient.name)),
          estimatedCostGbp: ingredient.estimatedCostGbp,
        ),
    ];
    final missing = tagged.where((item) {
      final staple = RegExp(
        r'^(salt|pepper|black pepper|oil|olive oil|vegetable oil|water|butter)$',
        caseSensitive: false,
      );
      return !item.inPantry && !staple.hasMatch(item.name);
    });
    final extra = missing.fold<double>(0, (sum, item) => sum + item.estimatedCostGbp);
    return Recipe(
      id: 'chef-showcase-${index + 1}',
      title: title,
      description: description,
      imageUrl: '',
      cookingTimeMinutes: minutes,
      difficulty: 'Easy',
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      sugar: sugar,
      fibre: fibre,
      servings: 1,
      ingredients: tagged,
      instructions: instructions,
      estimatedAdditionalCostGbp: extra > 0 ? extra : cost,
      rescueLine: rescueLine,
      plating: plating,
      wasteTip: wasteTip,
      assetImage: images[index],
    );
  }
}
