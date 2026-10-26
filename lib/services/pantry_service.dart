import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../models/models.dart';
import '../utils/food_facts.dart';
import '../utils/pantry_match.dart';

class PantryService {
  PantryService({AppDatabase? database}) : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<List<PantryIngredient>> getAll() async {
    final db = await _db.database;
    final rows =
        await db.query('ingredients', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(PantryIngredient.fromMap).toList();
  }

  Future<PantryIngredient?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('ingredients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PantryIngredient.fromMap(rows.first);
  }

  Future<PantryIngredient?> findByName(String name) async {
    final all = await getAll();
    for (final item in all) {
      if (pantryNamesMatch(item.name, name)) return item;
    }
    return null;
  }

  /// Merge detected / manual ingredients without overwriting existing expiry.
  Future<PantryIngredient> mergeIngredient({
    required String name,
    required double quantity,
    required String unit,
    DateTime? expiryDate,
    String? imageUrl,
    double? estimatedUnitValueGbp,
    String? storagePlace,
  }) async {
    final existing = await findByName(name);
    final now = DateTime.now();
    final db = await _db.database;

    if (existing == null) {
      final item = PantryIngredient(
        id: _uuid.v4(),
        name: _titleCase(name),
        quantityRemaining: quantity,
        unit: unit,
        expiryDate: expiryDate,
        imageUrl: imageUrl,
        estimatedUnitValueGbp:
            estimatedUnitValueGbp ?? FoodFacts.pricePerUnit(name, unit),
        storagePlace: storagePlace,
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('ingredients', item.toMap());
      return item;
    }

    final updated = existing.copyWith(
      quantityRemaining: existing.quantityRemaining + quantity,
      unit: unit.isNotEmpty ? unit : existing.unit,
      expiryDate: existing.expiryDate ?? expiryDate,
      imageUrl: existing.imageUrl ?? imageUrl,
      storagePlace: existing.storagePlace ?? storagePlace,
      updatedAt: now,
    );
    await db.update(
      'ingredients',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [existing.id],
    );
    return updated;
  }

  Future<PantryIngredient> upsertManual(PantryIngredient item) async {
    final db = await _db.database;
    final existing = await getById(item.id);
    if (existing == null) {
      await db.insert('ingredients', item.toMap());
    } else {
      await db.update(
        'ingredients',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
    return item;
  }

  Future<void> updateQuantity(String id, double quantity) async {
    final item = await getById(id);
    if (item == null) return;
    final updated = item.copyWith(
      quantityRemaining: quantity < 0 ? 0 : quantity,
      updatedAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.update(
      'ingredients',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateExpiry(String id, DateTime? expiry) async {
    final item = await getById(id);
    if (item == null) return;
    final map = item
        .copyWith(
          expiryDate: expiry ?? item.expiryDate,
          updatedAt: DateTime.now(),
        )
        .toMap();
    if (expiry == null) map['expiry_date'] = null;
    final db = await _db.database;
    await db.update('ingredients', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> remove(String id) async {
    final db = await _db.database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<IngredientUsageEvent>> usageHistory(String ingredientId) async {
    final db = await _db.database;
    final rows = await db.query(
      'ingredient_usage_events',
      where: 'ingredient_id = ?',
      whereArgs: [ingredientId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(IngredientUsageEvent.fromMap).toList();
  }

  Future<List<EatenLogEntry>> eatenLog() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT
        c.id,
        c.timestamp,
        c.calories,
        c.protein,
        c.carbohydrates,
        c.fat,
        c.fibre,
        c.plan_key,
        COALESCE(NULLIF(c.title, ''), r.title, 'Meal') AS title,
        COALESCE(r.sugar, 0) AS sugar
      FROM cooking_events c
      LEFT JOIN recipes r ON r.id = c.recipe_id
      ORDER BY c.timestamp DESC
    ''');
    return rows.map(EatenLogEntry.fromMap).toList();
  }

  Future<List<String>> recipeIdsUsingIngredient(String ingredientId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT recipe_id FROM ingredient_usage_events
      WHERE ingredient_id = ?
      ORDER BY timestamp DESC
      ''',
      [ingredientId],
    );
    return rows.map((r) => r['recipe_id']! as String).toList();
  }

  Future<CookRescueSummary> cookRecipe({
    required Recipe recipe,
    required List<CookDeduction> deductions,
    required int servings,
    String? planKey,
    int soonDays = 7,
  }) async {
    final db = await _db.database;
    var rescuedKg = 0.0;
    var highlightKg = 0.0;
    String? highlightFood;

    await db.transaction((txn) async {
      if (planKey != null && planKey.isNotEmpty) {
        final existing = await txn.query(
          'cooking_events',
          where: 'plan_key = ?',
          whereArgs: [planKey],
        );
        if (existing.isNotEmpty) {
          throw StateError('This planned meal is already marked as eaten.');
        }
      }

      final guard = await txn.query(
        'cooked_recipe_guards',
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );
      if (guard.isNotEmpty) {
        final last = DateTime.parse(guard.first['last_cooked_at']! as String);
        if (DateTime.now().difference(last) < const Duration(seconds: 5)) {
          throw StateError('This recipe was just marked as cooked.');
        }
      }

      final now = DateTime.now();
      await txn.insert(
        'cooking_events',
        CookingEvent(
          id: _uuid.v4(),
          recipeId: recipe.id,
          timestamp: now,
          servingsPrepared: servings,
          calories: recipe.calories,
          protein: recipe.protein,
          carbohydrates: recipe.carbohydrates,
          fat: recipe.fat,
          fibre: recipe.fibre,
          title: recipe.title,
          planKey: planKey,
        ).toMap(),
      );

      for (final d in deductions) {
        if (d.proposedQuantity <= 0) continue;
        final rows = await txn.query(
          'ingredients',
          where: 'id = ?',
          whereArgs: [d.ingredientId],
        );
        if (rows.isEmpty) continue;
        final ingredient = PantryIngredient.fromMap(rows.first);
        final used =
            d.proposedQuantity.clamp(0, ingredient.quantityRemaining).toDouble();
        if (used <= 0) continue;

        final nearExpiry = ingredient.isExpiringSoon(soonDays);
        var remaining = ingredient.quantityRemaining - used;
        if (remaining < 0.05) remaining = 0;
        final updated = ingredient.copyWith(
          quantityRemaining: remaining,
          timesUsed: ingredient.timesUsed + 1,
          totalQuantityUsed: ingredient.totalQuantityUsed + used,
          updatedAt: now,
        );
        await txn.update(
          'ingredients',
          updated.toMap(),
          where: 'id = ?',
          whereArgs: [ingredient.id],
        );
        await txn.insert(
          'ingredient_usage_events',
          IngredientUsageEvent(
            id: _uuid.v4(),
            ingredientId: ingredient.id,
            recipeId: recipe.id,
            quantityUsed: used,
            unit: ingredient.unit,
            timestamp: now,
            wasNearExpiry: nearExpiry,
          ).toMap(),
        );
        if (nearExpiry) {
          final kg = FoodFacts.toKg(used, ingredient.unit, ingredient.name);
          rescuedKg += kg;
          if (kg >= highlightKg) {
            highlightKg = kg;
            highlightFood = ingredient.name;
          }
        }
      }

      await txn.insert(
        'recipes',
        recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'cooked_recipe_guards',
        {
          'recipe_id': recipe.id,
          'last_cooked_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return CookRescueSummary(
      rescuedKg: rescuedKg,
      highlightFood: highlightFood,
    );
  }

  List<CookDeduction> proposedDeductions(
    Recipe recipe,
    List<PantryIngredient> pantry,
  ) {
    final result = <CookDeduction>[];
    final claimed = <String>{};
    for (final ing in recipe.ingredients) {
      PantryIngredient? match;
      for (final p in pantry) {
        if (!p.isAvailable || claimed.contains(p.id)) continue;
        if (pantryNamesMatch(p.name, ing.name)) {
          match = p;
          break;
        }
      }
      if (match == null) continue;
      claimed.add(match.id);
      final needed = convertFoodAmount(
        ing.quantity,
        ing.unit,
        match.unit,
        foodName: match.name,
      );
      final proposed = needed.clamp(0, match.quantityRemaining).toDouble();
      if (proposed <= 0) continue;
      result.add(
        CookDeduction(
          ingredientId: match.id,
          name: match.name,
          unit: match.unit,
          proposedQuantity: proposed,
          maxAvailable: match.quantityRemaining,
        ),
      );
    }
    return result;
  }

  /// Plan keys for cooks that used near-expiry food, which is what the
  /// carbon-savings graph counts.
  Future<Set<String>> rescuePlanKeys() async {
    final db = await _db.database;
    final cooks = await db.query('cooking_events');
    final uses = await db.query(
      'ingredient_usage_events',
      where: 'was_near_expiry = ?',
      whereArgs: [1],
    );
    final keys = <String>{};
    for (final cook in cooks) {
      final planKey = cook['plan_key'] as String?;
      if (planKey == null || planKey.isEmpty) continue;
      final recipeId = cook['recipe_id'] as String? ?? '';
      final cookedAt =
          DateTime.tryParse(cook['timestamp'] as String? ?? '')?.toLocal();
      if (cookedAt == null) continue;
      final savedCarbon = uses.any((use) {
        if ((use['recipe_id'] as String? ?? '') != recipeId) return false;
        final usedAt =
            DateTime.tryParse(use['timestamp'] as String? ?? '')?.toLocal();
        if (usedAt == null) return false;
        return usedAt.difference(cookedAt).inMinutes.abs() <= 3;
      });
      if (savedCarbon) keys.add(planKey);
    }
    return keys;
  }

  /// Clears lifetime Impact and Eating graphs. Pantry stock is left in place.
  Future<void> clearAllGraphHistory() async {
    final db = await _db.database;
    await db.delete('ingredient_usage_events');
    await db.delete('cooking_events');
    await db.delete('cooked_recipe_guards');
    await db.delete('recipes', where: "id LIKE 'demo-recipe-%'");
  }

  /// Seeds ~14 days of realistic rescued cooking for hackathon demos.
  Future<void> seedDemoImpactWeek() async {
    final db = await _db.database;
    final now = DateTime.now();
    final demoFoods = <({String name, String unit, double qty, double price})>[
      (name: 'Spinach', unit: 'g', qty: 120, price: 0.004),
      (name: 'Bread', unit: 'slice', qty: 4, price: 0.12),
      (name: 'Milk', unit: 'ml', qty: 250, price: 0.001),
      (name: 'Chicken breast', unit: 'g', qty: 180, price: 0.008),
      (name: 'Tomatoes', unit: 'piece', qty: 2, price: 0.25),
      (name: 'Yoghurt', unit: 'g', qty: 150, price: 0.003),
    ];
    final ingredientIds = <String>[];
    for (final food in demoFoods) {
      final id = 'demo-food-${food.name.toLowerCase().replaceAll(' ', '-')}';
      ingredientIds.add(id);
      await db.insert(
        'ingredients',
        PantryIngredient(
          id: id,
          name: food.name,
          quantityRemaining: food.qty * 6,
          unit: food.unit,
          expiryDate: now.add(const Duration(days: 3)),
          estimatedUnitValueGbp: food.price,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    const meals = [
      ('Spinach omelette', 380, 28.0, 12.0, 22.0, 3.0),
      ('Tomato toast', 320, 12.0, 42.0, 10.0, 4.0),
      ('Chicken and greens', 480, 42.0, 18.0, 18.0, 5.0),
      ('Yoghurt bowl', 280, 18.0, 32.0, 8.0, 2.0),
      ('Milk porridge', 350, 14.0, 48.0, 9.0, 3.0),
    ];

    for (var dayAgo = 13; dayAgo >= 0; dayAgo--) {
      if (dayAgo == 11 || dayAgo == 4) continue;
      final stamp = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayAgo))
          .add(Duration(hours: 12 + (dayAgo % 3)));
      final meal = meals[dayAgo % meals.length];
      final recipeId = 'demo-recipe-$dayAgo';
      final cookId = 'demo-cook-$dayAgo';
      await db.insert(
        'recipes',
        Recipe(
          id: recipeId,
          title: meal.$1,
          description: 'Demo meal for Impact',
          imageUrl: '',
          cookingTimeMinutes: 20,
          difficulty: 'Easy',
          calories: meal.$2,
          protein: meal.$3,
          carbohydrates: meal.$4,
          fat: meal.$5,
          fibre: meal.$6,
          servings: 1,
          ingredients: const [],
          instructions: const ['Demo cook'],
          estimatedAdditionalCostGbp: 0,
          isDemo: true,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'cooking_events',
        CookingEvent(
          id: cookId,
          recipeId: recipeId,
          timestamp: stamp,
          servingsPrepared: 1,
          calories: meal.$2,
          protein: meal.$3,
          carbohydrates: meal.$4,
          fat: meal.$5,
          fibre: meal.$6,
          title: meal.$1,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final foodIndex = dayAgo % demoFoods.length;
      final food = demoFoods[foodIndex];
      final second = demoFoods[(foodIndex + 2) % demoFoods.length];
      await db.insert(
        'ingredient_usage_events',
        IngredientUsageEvent(
          id: 'demo-use-$dayAgo-a',
          ingredientId: ingredientIds[foodIndex],
          recipeId: recipeId,
          quantityUsed: food.qty,
          unit: food.unit,
          timestamp: stamp,
          wasNearExpiry: true,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'ingredient_usage_events',
        IngredientUsageEvent(
          id: 'demo-use-$dayAgo-b',
          ingredientId: ingredientIds[(foodIndex + 2) % demoFoods.length],
          recipeId: recipeId,
          quantityUsed: second.qty * 0.5,
          unit: second.unit,
          timestamp: stamp,
          wasNearExpiry: dayAgo.isEven,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
