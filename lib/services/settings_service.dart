import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/user_preferences.dart';

class SettingsService {
  SettingsService({AppDatabase? database}) : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;
  static const _key = 'user_preferences';

  Future<UserPreferences> load() async {
    final db = await _db.database;
    final rows = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [_key],
    );
    if (rows.isEmpty) return const UserPreferences();
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return const UserPreferences();
    try {
      return UserPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const UserPreferences();
    }
  }

  Future<Map<String, dynamic>?> loadJson(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    final db = await _db.database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> save(UserPreferences prefs) async {
    final db = await _db.database;
    await db.insert(
      'user_settings',
      {'key': _key, 'value': jsonEncode(prefs.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
