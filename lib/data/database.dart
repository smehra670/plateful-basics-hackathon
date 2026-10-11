import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'plateful.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            quantity_remaining REAL NOT NULL,
            unit TEXT NOT NULL,
            expiry_date TEXT,
            times_used INTEGER NOT NULL DEFAULT 0,
            total_quantity_used REAL NOT NULL DEFAULT 0,
            image_url TEXT,
            estimated_unit_value_gbp REAL NOT NULL DEFAULT 0.3,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE recipes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            image_url TEXT NOT NULL,
            cooking_time INTEGER NOT NULL,
            difficulty TEXT NOT NULL,
            calories INTEGER NOT NULL,
            protein REAL NOT NULL,
            carbohydrates REAL NOT NULL,
            fat REAL NOT NULL,
            servings INTEGER NOT NULL,
            estimated_additional_cost REAL NOT NULL,
            instructions_json TEXT NOT NULL,
            ingredients_json TEXT NOT NULL,
            is_demo INTEGER NOT NULL DEFAULT 0,
            asset_image TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE recipe_ingredients (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            in_pantry INTEGER NOT NULL,
            estimated_cost_gbp REAL NOT NULL DEFAULT 0,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE saved_recipes (
            recipe_id TEXT PRIMARY KEY,
            saved_at TEXT NOT NULL,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE scan_sessions (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            ingredients_json TEXT NOT NULL,
            answers_json TEXT,
            is_demo INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE cooking_events (
            id TEXT PRIMARY KEY,
            recipe_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            servings_prepared INTEGER NOT NULL,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE ingredient_usage_events (
            id TEXT PRIMARY KEY,
            ingredient_id TEXT NOT NULL,
            recipe_id TEXT NOT NULL,
            quantity_used REAL NOT NULL,
            unit TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            was_near_expiry INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
            FOREIGN KEY (recipe_id) REFERENCES recipes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE cooked_recipe_guards (
            recipe_id TEXT PRIMARY KEY,
            last_cooked_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
