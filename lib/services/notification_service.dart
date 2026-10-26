import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/meal_plan.dart';
import '../models/models.dart';
import '../models/user_preferences.dart';
import '../utils/pantry_match.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/London'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> sync({
    required UserPreferences preferences,
    required List<PantryIngredient> ingredients,
    required MealPlan? plan,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    var id = 10;
    if (preferences.notifyExpiry) {
      for (final item in ingredients) {
        if (!item.isAvailable || item.expiryDate == null) continue;
        final when = DateTime(
          item.expiryDate!.year,
          item.expiryDate!.month,
          item.expiryDate!.day,
        ).subtract(const Duration(days: 1));
        final at = DateTime(when.year, when.month, when.day, 9);
        if (!at.isAfter(DateTime.now())) continue;
        await _schedule(
          id++,
          '${item.name} expires tomorrow',
          _expiryBody(item, plan),
          at,
        );
      }
    }
    if (preferences.notifyMealPlan) {
      final now = DateTime.now();
      var day = DateTime(now.year, now.month, now.day, 10);
      while (day.weekday != DateTime.sunday || !day.isAfter(now)) {
        day = day.add(const Duration(days: 1));
        if (day.hour != 10) {
          day = DateTime(day.year, day.month, day.day, 10);
        }
      }
      await _schedule(
        1,
        'Plan the week',
        'A few minutes now saves food later in the week.',
        day,
      );
    }
    if (preferences.notifyShopping &&
        plan != null &&
        plan.shoppingList.any((item) => !item.checked)) {
      final count = plan.shoppingList.where((item) => !item.checked).length;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await _schedule(
        2,
        'Shopping list',
        '$count item${count == 1 ? '' : 's'} still to buy for your plan.',
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      );
    }
    if (preferences.notifyPrep && plan != null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final key =
          '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final meals = plan.days.where((d) => d.date == key).expand((d) => d.meals);
      final first = meals.isEmpty ? null : meals.first.recipe.title;
      if (first != null) {
        final at = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 19);
        if (at.isAfter(DateTime.now())) {
          await _schedule(3, 'Prep for tomorrow', 'Tomorrow starts with $first.', at);
        }
      }
    }
  }

  String _expiryBody(PantryIngredient item, MealPlan? plan) {
    if (plan != null) {
      for (final day in plan.days) {
        for (final meal in day.meals) {
          final uses = meal.recipe.ingredients.any(
            (ingredient) => pantryNamesMatch(ingredient.name, item.name),
          );
          if (!uses) continue;
          final minutes = meal.recipe.cookingTimeMinutes;
          if (minutes > 0) {
            return 'Here\'s a $minutes-minute recipe: ${meal.recipe.title}.';
          }
          return 'Here\'s a recipe: ${meal.recipe.title}.';
        }
      }
    }
    return 'Open Plateful for a quick recipe before it goes off.';
  }

  Future<void> _schedule(int id, String title, String body, DateTime when) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plateful.reminders',
          'Plateful reminders',
          channelDescription: 'Expiry, meal plan, shopping and prep reminders',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
