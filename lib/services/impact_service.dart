import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/models.dart';
import '../utils/food_facts.dart';

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

    final nutrition = await db.rawQuery('''
      SELECT
        COALESCE(SUM(calories), 0) AS calories,
        COALESCE(SUM(protein), 0) AS protein,
        COALESCE(SUM(carbohydrates), 0) AS carbs,
        COALESCE(SUM(fat), 0) AS fat,
        COALESCE(SUM(fibre), 0) AS fibre
      FROM cooking_events
    ''');
    final n = nutrition.first;

    final usageRows = await db.rawQuery('''
      SELECT u.quantity_used, u.was_near_expiry, u.timestamp, u.unit,
             u.recipe_id, i.estimated_unit_value_gbp, i.name, i.expiry_date
      FROM ingredient_usage_events u
      LEFT JOIN ingredients i ON i.id = u.ingredient_id
    ''');

    var totalQty = 0.0;
    var valueGbp = 0.0;
    var nearExpiryCount = 0;
    var nearExpiryQty = 0.0;
    var weekNearKg = 0.0;
    var weekNearCount = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daily = List<double>.filled(7, 0);
    final previous = List<double>.filled(7, 0);
    final valueDaily = List<double>.filled(7, 0);
    final rescuedByName = <String, double>{};
    final monthRescued = <int>{};
    final rescueByRecipe = <String, _RecipeRescue>{};
    final dailyRescueAll = <int, double>{};
    final uses = <_Use>[];

    for (final row in usageRows) {
      final qty = (row['quantity_used'] as num).toDouble();
      final unit = row['unit'] as String? ?? 'pcs';
      final name = row['name'] as String? ?? 'food';
      final recipeId = row['recipe_id'] as String? ?? '';
      final unitValue = (row['estimated_unit_value_gbp'] as num?)?.toDouble() ??
          FoodFacts.pricePerUnit(name, unit);
      totalQty += qty;
      valueGbp += qty * unitValue;
      final expiry = row['expiry_date'] as String?;
      uses.add(
        _Use(
          recipeId: recipeId,
          time: DateTime.tryParse(row['timestamp'] as String? ?? '')?.toLocal(),
          hasExpiry: expiry != null && expiry.isNotEmpty,
        ),
      );
      final stamp = DateTime.tryParse(row['timestamp'] as String? ?? '');
      final local = stamp?.toLocal();
      if (local != null) {
        final day = DateTime(local.year, local.month, local.day);
        final daysAgo = today.difference(day).inDays;
        if (daysAgo >= 0 && daysAgo <= 6) {
          valueDaily[6 - daysAgo] += qty * unitValue;
        }
      }
      final near = (row['was_near_expiry'] as int? ?? 0) == 1;
      if (!near) continue;
      nearExpiryCount += 1;
      final kg = FoodFacts.toKg(qty, unit, name);
      nearExpiryQty += kg;
      rescuedByName[name] = (rescuedByName[name] ?? 0) + kg;
      if (recipeId.isNotEmpty) {
        final bucket = rescueByRecipe.putIfAbsent(
          recipeId,
          () => _RecipeRescue(),
        );
        bucket.kg += kg;
        if (!bucket.foods.contains(name)) bucket.foods.add(name);
      }
      if (local == null) continue;
      final day = DateTime(local.year, local.month, local.day);
      if (local.year == today.year && local.month == today.month) {
        monthRescued.add(local.day);
      }
      final daysAgo = today.difference(day).inDays;
      if (daysAgo >= 0) {
        dailyRescueAll[daysAgo] = (dailyRescueAll[daysAgo] ?? 0) + kg;
      }
      if (daysAgo >= 0 && daysAgo <= 6) {
        weekNearKg += kg;
        weekNearCount += 1;
        daily[6 - daysAgo] += kg;
      } else if (daysAgo >= 7 && daysAgo <= 13) {
        previous[6 - (daysAgo - 7)] += kg;
      }
    }

    final topFoods = rescuedByName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxAgo = dailyRescueAll.keys.fold<int>(0, (max, ago) => ago > max ? ago : max);
    final complete = maxAgo <= 84;
    final startAgo = complete ? maxAgo : 84;
    final full = <double>[];
    var running = 0.0;
    for (var ago = startAgo; ago >= 0; ago--) {
      running += dailyRescueAll[ago] ?? 0;
      full.add(running);
    }
    final cumulative = <double>[];
    if (full.length <= 60) {
      cumulative.addAll(full);
    } else {
      final step = (full.length / 60).ceil();
      for (var i = 0; i < full.length; i += step) {
        cumulative.add(full[i]);
      }
      if (cumulative.last != full.last) cumulative.add(full.last);
    }

    final cookRows = await db.rawQuery('''
      SELECT
        c.recipe_id,
        c.timestamp,
        c.calories,
        c.protein,
        c.carbohydrates,
        c.fat,
        c.fibre,
        COALESCE(NULLIF(c.title, ''), r.title, 'Meal') AS title,
        COALESCE(r.image_url, '') AS image_url
      FROM cooking_events c
      LEFT JOIN recipes r ON r.id = c.recipe_id
      ORDER BY c.timestamp DESC
    ''');
    final cookDays = <String>{};
    final monthCooked = <int>{};
    final mealsDaily = List<int>.filled(7, 0);
    final caloriesDaily = List<int>.filled(7, 0);
    final proteinDaily = List<double>.filled(7, 0);
    final carbsDaily = List<double>.filled(7, 0);
    final fatDaily = List<double>.filled(7, 0);
    final fibreDaily = List<double>.filled(7, 0);
    final recentMeals = <ImpactMeal>[];
    var mealsMissingExpiry = 0;
    for (final row in cookRows) {
      final stamp = DateTime.tryParse(row['timestamp'] as String? ?? '');
      if (stamp == null) continue;
      final local = stamp.toLocal();
      cookDays.add(
        '${local.year}-${local.month}-${local.day}',
      );
      if (local.year == today.year && local.month == today.month) {
        monthCooked.add(local.day);
      }
      final day = DateTime(local.year, local.month, local.day);
      final daysAgo = today.difference(day).inDays;
      final calories = (row['calories'] as num?)?.toInt() ?? 0;
      final protein = (row['protein'] as num?)?.toDouble() ?? 0;
      final carbs = (row['carbohydrates'] as num?)?.toDouble() ?? 0;
      final fat = (row['fat'] as num?)?.toDouble() ?? 0;
      final fibre = (row['fibre'] as num?)?.toDouble() ?? 0;
      final recipeId = row['recipe_id'] as String? ?? '';
      final matched = uses.where((use) {
        if (use.recipeId != recipeId || use.time == null) return false;
        return use.time!.difference(local).inMinutes.abs() <= 3;
      });
      if (matched.isNotEmpty && matched.every((use) => !use.hasExpiry)) {
        mealsMissingExpiry += 1;
      }
      if (daysAgo >= 0 && daysAgo <= 6) {
        mealsDaily[6 - daysAgo] += 1;
        caloriesDaily[6 - daysAgo] += calories;
        proteinDaily[6 - daysAgo] += protein;
        carbsDaily[6 - daysAgo] += carbs;
        fatDaily[6 - daysAgo] += fat;
        fibreDaily[6 - daysAgo] += fibre;
      }
      if (recentMeals.length < 8) {
        final rescue = rescueByRecipe[recipeId];
        recentMeals.add(
          ImpactMeal(
            title: row['title'] as String? ?? 'Meal',
            imageUrl: row['image_url'] as String? ?? '',
            calories: calories,
            protein: protein,
            timestamp: local,
            rescuedFoods: rescue?.foods.take(4).toList() ?? const [],
            rescuedKg: rescue?.kg ?? 0,
          ),
        );
      }
    }
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!cookDays.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (cookDays.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return ImpactStats(
      mealsCooked: cookCount,
      totalIngredientsUsed: totalQty,
      estimatedValueUtilisedGbp: valueGbp,
      ingredientsUsedBeforeExpiry: nearExpiryCount,
      estimatedWasteAvoidedKg: nearExpiryCount == 0 ? null : nearExpiryQty,
      caloriesEaten: (n['calories'] as num?)?.toInt() ?? 0,
      proteinEaten: (n['protein'] as num?)?.toDouble() ?? 0,
      carbohydratesEaten: (n['carbs'] as num?)?.toDouble() ?? 0,
      fatEaten: (n['fat'] as num?)?.toDouble() ?? 0,
      fibreEaten: (n['fibre'] as num?)?.toDouble() ?? 0,
      foodSavedThisWeekKg: weekNearKg,
      nearExpiryUsesThisWeek: weekNearCount,
      usageEvents: usageRows.length,
      savedKgLast7Days: daily,
      savedKgPrevious7Days: previous,
      mealsLast7Days: mealsDaily,
      caloriesLast7Days: caloriesDaily,
      proteinLast7Days: proteinDaily,
      carbsLast7Days: carbsDaily,
      fatLast7Days: fatDaily,
      fibreLast7Days: fibreDaily,
      valueGbpLast7Days: valueDaily,
      cumulativeSavedKg: cumulative,
      cumulativeIsComplete: complete,
      mealsMissingExpiry: mealsMissingExpiry,
      topRescuedFoods: [
        for (final entry in topFoods.take(5))
          RescuedFood(name: entry.key, kilograms: entry.value),
      ],
      recentMeals: recentMeals,
      monthCookedDays: monthCooked.toList()..sort(),
      monthRescuedDays: monthRescued.toList()..sort(),
      cookStreakDays: streak,
    );
  }
}

class _RecipeRescue {
  double kg = 0;
  final List<String> foods = [];
}

class _Use {
  _Use({required this.recipeId, required this.time, required this.hasExpiry});

  final String recipeId;
  final DateTime? time;
  final bool hasExpiry;
}
