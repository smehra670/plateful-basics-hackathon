import '../models/meal_plan.dart';
import '../models/models.dart';
import 'food_facts.dart';
import 'pantry_match.dart';

final _staple = RegExp(
  r'^(salt|pepper|black pepper|oil|olive oil|vegetable oil|water|sugar|flour)$',
  caseSensitive: false,
);

class _Need {
  _Need(this.name, this.unit, this.amount);
  final String name;
  String unit;
  double amount;
}

/// Rebuild shopping and pantry-usage lists from the meals currently on the plan.
MealPlan reallocatePlan(MealPlan plan, List<PantryIngredient> pantry) {
  final checked = <String, bool>{
    for (final item in plan.shoppingList)
      pantryNorm(item.name): item.checked,
  };

  final needs = <String, _Need>{};
  for (final day in plan.days) {
    for (final meal in day.meals) {
      for (final ing in meal.recipe.ingredients) {
        if (_staple.hasMatch(ing.name.trim())) continue;
        final canon = _canon(ing.name, ing.quantity, ing.unit);
        final key = '${pantrySingular(ing.name)}|${canon.unit}';
        final prev = needs[key];
        if (prev == null) {
          needs[key] = _Need(ing.name, canon.unit, canon.amount);
        } else {
          prev.amount += canon.amount;
        }
      }
    }
  }

  final stock = [
    for (final item in pantry)
      if (item.isAvailable)
        _Need(
          item.name,
          _canon(item.name, item.quantityRemaining, item.unit).unit,
          _canon(item.name, item.quantityRemaining, item.unit).amount,
        ),
  ];

  final shopping = <ShoppingItem>[];
  final usage = <ShoppingItem>[];
  for (final need in needs.values) {
    var fromPantry = 0.0;
    for (final item in stock) {
      if (item.unit != need.unit) continue;
      if (!pantryNamesMatch(item.name, need.name)) continue;
      final take = (need.amount - fromPantry).clamp(0, item.amount).toDouble();
      item.amount -= take;
      fromPantry += take;
      if (fromPantry >= need.amount - 0.01) break;
    }
    if (fromPantry > 0.05) {
      usage.add(
        ShoppingItem(
          name: need.name,
          quantity: _round(fromPantry),
          unit: need.unit,
        ),
      );
    }
    final missing = need.amount - fromPantry;
    if (missing > 0.05) {
      shopping.add(
        ShoppingItem(
          name: need.name,
          quantity: _round(missing),
          unit: need.unit,
          checked: checked[pantryNorm(need.name)] ?? false,
        ),
      );
    }
  }

  return MealPlan(
    id: plan.id,
    days: plan.days,
    shoppingList: shopping,
    pantryUsage: usage,
    allergyWarning: plan.allergyWarning,
  );
}

class _Canon {
  const _Canon(this.amount, this.unit);
  final double amount;
  final String unit;
}

_Canon _canon(String name, double quantity, String unit) {
  final u = unit.trim().toLowerCase();
  if (const {'kg'}.contains(u)) return _Canon(quantity * 1000, 'g');
  if (const {'g', 'gram', 'grams'}.contains(u)) return _Canon(quantity, 'g');
  if (const {'l', 'litre', 'liter', 'litres', 'liters'}.contains(u)) {
    return _Canon(quantity * 1000, 'ml');
  }
  if (u == 'ml') return _Canon(quantity, 'ml');
  if (const {'tbsp', 'tablespoon', 'tablespoons'}.contains(u)) {
    return _Canon(quantity * 15, 'ml');
  }
  if (const {'tsp', 'teaspoon', 'teaspoons'}.contains(u)) {
    return _Canon(quantity * 5, 'ml');
  }
  final piece = FoodFacts.pieceGrams(name);
  const counts = {
    'pcs',
    'pc',
    'piece',
    'pieces',
    'item',
    'items',
    'slice',
    'slices',
    'clove',
    'cloves',
  };
  if (piece != null && counts.contains(u)) return _Canon(quantity * piece, 'g');
  return _Canon(quantity, u.isEmpty ? 'pcs' : u);
}

double _round(double n) => (n * 10).round() / 10;
