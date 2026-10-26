import 'models.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.unconfirmed = false,
    this.checked = false,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool unconfirmed;
  final bool checked;

  ShoppingItem copyWith({bool? checked}) {
    return ShoppingItem(
      name: name,
      quantity: quantity,
      unit: unit,
      unconfirmed: unconfirmed,
      checked: checked ?? this.checked,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      unconfirmed: json['unconfirmed'] as bool? ?? false,
      checked: json['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unconfirmed': unconfirmed,
        'checked': checked,
      };
}

class PlannedMeal {
  const PlannedMeal({
    required this.slot,
    required this.date,
    required this.recipe,
    this.completed = false,
  });

  final String slot;
  final String date;
  final Recipe recipe;
  final bool completed;

  String get planKey => '$date|$slot';

  PlannedMeal copyWith({Recipe? recipe, bool? completed}) {
    return PlannedMeal(
      slot: slot,
      date: date,
      recipe: recipe ?? this.recipe,
      completed: completed ?? this.completed,
    );
  }

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      slot: json['slot'] as String,
      date: json['date'] as String,
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'date': date,
        'completed': completed,
        'recipe': {
          'id': recipe.id,
          'name': recipe.title,
          'description': recipe.description,
          'imageUrl': recipe.imageUrl,
          'cookingTime': recipe.cookingTimeMinutes,
          'difficulty': recipe.difficulty,
          'calories': recipe.calories,
          'protein': recipe.protein,
          'carbohydrates': recipe.carbohydrates,
          'fat': recipe.fat,
          'sugar': recipe.sugar,
          'fibre': recipe.fibre,
          'servings': recipe.servings,
          'ingredients': recipe.ingredients.map((e) => e.toJson()).toList(),
          'instructions': recipe.instructions,
          'estimatedAdditionalCost': recipe.estimatedAdditionalCostGbp,
          'rescueLine': recipe.rescueLine,
          'plating': recipe.plating,
          'wasteTip': recipe.wasteTip,
        },
      };
}

class PlanDay {
  const PlanDay({required this.date, required this.meals});

  final String date;
  final List<PlannedMeal> meals;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      date: json['date'] as String,
      meals: ((json['meals'] as List<dynamic>?) ?? [])
          .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'meals': meals.map((e) => e.toJson()).toList(),
      };
}

class MealPlan {
  const MealPlan({
    this.id = '',
    required this.days,
    required this.shoppingList,
    required this.pantryUsage,
    required this.allergyWarning,
  });

  /// New plans get a fresh id so the timetable nutrition starts at zero.
  final String id;
  final List<PlanDay> days;
  final List<ShoppingItem> shoppingList;
  final List<ShoppingItem> pantryUsage;
  final String allergyWarning;

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String? ?? '',
      days: ((json['days'] as List<dynamic>?) ?? [])
          .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      shoppingList: ((json['shoppingList'] as List<dynamic>?) ?? [])
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pantryUsage: ((json['pantryUsage'] as List<dynamic>?) ?? [])
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      allergyWarning: json['allergyWarning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'days': days.map((e) => e.toJson()).toList(),
        'shoppingList': shoppingList.map((e) => e.toJson()).toList(),
        'pantryUsage': pantryUsage.map((e) => e.toJson()).toList(),
        'allergyWarning': allergyWarning,
      };

  MealPlan replacingMeal(String date, String slot, Recipe recipe) {
    return _mapMeal(date, slot, (m) => m.copyWith(recipe: recipe));
  }

  MealPlan markingCompleted(String date, String slot, {required bool completed}) {
    return _mapMeal(date, slot, (m) => m.copyWith(completed: completed));
  }

  /// Drops meals that produced a carbon saving and clears every eaten flag
  /// so the front-page nutrient totals start again at zero.
  MealPlan withoutRescuedMeals(Set<String> rescuePlanKeys) {
    bool rescued(PlannedMeal meal) {
      final bare = '${meal.date}|${meal.slot}';
      if (id.isEmpty) return rescuePlanKeys.contains(bare);
      return rescuePlanKeys.contains('$id|$bare');
    }

    return MealPlan(
      id: id,
      days: [
        for (final day in days)
          PlanDay(
            date: day.date,
            meals: [
              for (final meal in day.meals)
                if (!rescued(meal)) meal.copyWith(completed: false),
            ],
          ),
      ],
      shoppingList: shoppingList,
      pantryUsage: pantryUsage,
      allergyWarning: allergyWarning,
    );
  }

  PlannedMeal? mealAt(String date, String slot) {
    for (final day in days) {
      if (day.date != date) continue;
      for (final meal in day.meals) {
        if (meal.slot == slot) return meal;
      }
    }
    return null;
  }

  int get completedCount =>
      days.fold(0, (n, d) => n + d.meals.where((m) => m.completed).length);

  MealPlan _mapMeal(
    String date,
    String slot,
    PlannedMeal Function(PlannedMeal) update,
  ) {
    return MealPlan(
      id: id,
      days: days
          .map(
            (d) => d.date != date
                ? d
                : PlanDay(
                    date: d.date,
                    meals: d.meals
                        .map((m) => m.slot == slot ? update(m) : m)
                        .toList(),
                  ),
          )
          .toList(),
      shoppingList: shoppingList,
      pantryUsage: pantryUsage,
      allergyWarning: allergyWarning,
    );
  }
}

class MealPlanRequest {
  const MealPlanRequest({
    required this.durationDays,
    required this.meals,
    required this.people,
    required this.goals,
    required this.spiceTolerance,
    required this.favouriteCuisines,
    required this.avoidIngredients,
    required this.maxCookMinutes,
    this.weeklyBudgetGbp,
    required this.pantryMode,
    required this.pantry,
    required this.focusIngredients,
    this.preferences,
  });

  final int durationDays;
  final List<String> meals;
  final int people;
  final List<String> goals;
  final String spiceTolerance;
  final List<String> favouriteCuisines;
  final List<String> avoidIngredients;
  final int maxCookMinutes;
  final double? weeklyBudgetGbp;
  final String pantryMode;
  final List<PantryIngredient> pantry;
  final List<String> focusIngredients;
  final Map<String, dynamic>? preferences;

  Map<String, dynamic> toJson() => {
        'durationDays': durationDays,
        'meals': meals,
        'people': people,
        'goals': goals,
        'spiceTolerance': spiceTolerance,
        'favouriteCuisines': favouriteCuisines,
        'avoidIngredients': avoidIngredients,
        'maxCookMinutes': maxCookMinutes,
        'weeklyBudgetGbp': weeklyBudgetGbp,
        'pantryMode': pantryMode,
        'pantry': pantry
            .map(
              (p) => {
                'name': p.name,
                'quantity': p.quantityRemaining,
                'unit': p.unit,
                'expiryDate': p.expiryDate?.toIso8601String(),
              },
            )
            .toList(),
        'focusIngredients': focusIngredients,
        'startDate': DateTime.now().toIso8601String(),
        if (preferences != null) 'preferences': preferences,
      };
}
