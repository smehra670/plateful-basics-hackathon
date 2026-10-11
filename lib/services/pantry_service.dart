import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../data/database.dart';
import '../models/models.dart';

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
    final key = name.trim().toLowerCase();
    for (final item in all) {
      if (item.normalizedName == key) return item;
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
        estimatedUnitValueGbp: estimatedUnitValueGbp ?? 0.3,
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

  Future<void> cookRecipe({
    required Recipe recipe,
    required List<CookDeduction> deductions,
    required int servings,
  }) async {
    final db = await _db.database;

    await db.transaction((txn) async {
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

        final nearExpiry = ingredient.isExpiringSoon(AppConfig.expirySoonDays);
        final updated = ingredient.copyWith(
          quantityRemaining: ingredient.quantityRemaining - used,
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
  }

  List<CookDeduction> proposedDeductions(
    Recipe recipe,
    List<PantryIngredient> pantry,
  ) {
    final result = <CookDeduction>[];
    for (final ing in recipe.availableIngredients) {
      PantryIngredient? match;
      for (final p in pantry) {
        if (p.normalizedName == ing.name.trim().toLowerCase()) {
          match = p;
          break;
        }
      }
      if (match == null || !match.isAvailable) continue;
      final proposed =
          ing.quantity.clamp(0, match.quantityRemaining).toDouble();
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

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
