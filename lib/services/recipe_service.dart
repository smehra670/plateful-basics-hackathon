import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/models.dart';

class RecipeService {
  RecipeService({AppDatabase? database}) : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<void> upsertRecipe(Recipe recipe) async {
    final db = await _db.database;
    await db.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMany(List<Recipe> recipes) async {
    for (final r in recipes) {
      await upsertRecipe(r);
    }
  }

  Future<Recipe?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Recipe.fromMap(rows.first);
  }

  Future<void> saveRecipe(Recipe recipe) async {
    await upsertRecipe(recipe);
    final db = await _db.database;
    await db.insert(
      'saved_recipes',
      {
        'recipe_id': recipe.id,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> unsaveRecipe(String recipeId) async {
    final db = await _db.database;
    await db.delete(
      'saved_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<bool> isSaved(String recipeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'saved_recipes',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return rows.isNotEmpty;
  }

  Future<List<Recipe>> getSavedRecipes() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT r.* FROM recipes r
      INNER JOIN saved_recipes s ON s.recipe_id = r.id
      ORDER BY s.saved_at DESC
    ''');
    return rows.map(Recipe.fromMap).toList();
  }

  Future<Set<String>> getSavedIds() async {
    final db = await _db.database;
    final rows = await db.query('saved_recipes', columns: ['recipe_id']);
    return rows.map((r) => r['recipe_id']! as String).toSet();
  }
}
