import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/models.dart';

class ImpactService {
  ImpactService({AppDatabase? database}) : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<ImpactStats> compute() async {
    final db = await _db.database;

    final cookCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cooking_events'),
        ) ??
        0;

    if (cookCount == 0) {
      return const ImpactStats(
        mealsCooked: 0,
        totalIngredientsUsed: 0,
        estimatedValueUtilisedGbp: 0,
        ingredientsUsedBeforeExpiry: 0,
      );
    }

    final usageRows = await db.rawQuery('''
      SELECT u.quantity_used, u.was_near_expiry, i.estimated_unit_value_gbp, i.unit
      FROM ingredient_usage_events u
      LEFT JOIN ingredients i ON i.id = u.ingredient_id
    ''');

    var totalQty = 0.0;
    var valueGbp = 0.0;
    var nearExpiryCount = 0;
    var nearExpiryQty = 0.0;

    for (final row in usageRows) {
      final qty = (row['quantity_used'] as num).toDouble();
      final unitValue =
          (row['estimated_unit_value_gbp'] as num?)?.toDouble() ?? 0.3;
      final unit = row['unit'] as String? ?? 'pcs';
      totalQty += qty;
      valueGbp += qty * unitValue;
      final near = (row['was_near_expiry'] as int? ?? 0) == 1;
      if (near) {
        nearExpiryCount += 1;
        if (unit == 'g' || unit == 'ml') {
          nearExpiryQty += qty / 1000;
        } else {
          nearExpiryQty += qty * 0.05;
        }
      }
    }

    return ImpactStats(
      mealsCooked: cookCount,
      totalIngredientsUsed: totalQty,
      estimatedValueUtilisedGbp: valueGbp,
      ingredientsUsedBeforeExpiry: nearExpiryCount,
      estimatedWasteAvoidedKg: nearExpiryCount == 0 ? null : nearExpiryQty,
    );
  }
}
