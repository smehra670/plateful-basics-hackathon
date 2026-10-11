import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RecipeIdea {
  const RecipeIdea({
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.calories,
    required this.tag,
  });

  final String title;
  final String imageUrl;
  final int minutes;
  final int calories;
  final String tag;
}

class GoalCard {
  const GoalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class SavedListItem {
  const SavedListItem({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.done,
  });

  final String title;
  final String subtitle;
  final int items;
  final bool done;
}

abstract final class SampleData {
  static const categories = [
    'For You',
    'Quick',
    'Use Soon',
    'High Protein',
    'Veggie',
  ];

  static const featured = RecipeIdea(
    title: 'Roasted veggie grain bowl',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    minutes: 25,
    calories: 420,
    tag: 'Use leftovers',
  );

  static const recipes = [
    RecipeIdea(
      title: 'Herb lemon chicken',
      imageUrl:
          'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=600&q=80',
      minutes: 30,
      calories: 380,
      tag: 'Dinner',
    ),
    RecipeIdea(
      title: 'Creamy tomato pasta',
      imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80',
      minutes: 20,
      calories: 510,
      tag: 'Pantry',
    ),
    RecipeIdea(
      title: 'Citrus avocado toast',
      imageUrl:
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&q=80',
      minutes: 10,
      calories: 290,
      tag: 'Breakfast',
    ),
    RecipeIdea(
      title: 'Green goddess salad',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
      minutes: 15,
      calories: 240,
      tag: 'Fresh',
    ),
  ];

  static const goals = [
    GoalCard(
      title: 'Use soon',
      subtitle: 'Items expiring',
      icon: Icons.schedule_rounded,
      color: AppColors.softPeach,
    ),
    GoalCard(
      title: 'Zero waste',
      subtitle: 'Weekly challenge',
      icon: Icons.eco_outlined,
      color: AppColors.sage,
    ),
    GoalCard(
      title: 'Quick meals',
      subtitle: 'Under 20 min',
      icon: Icons.bolt_outlined,
      color: AppColors.softBlue,
    ),
    GoalCard(
      title: 'Meal prep',
      subtitle: 'Batch cook',
      icon: Icons.kitchen_outlined,
      color: AppColors.lavender,
    ),
  ];

  static const savedLists = [
    SavedListItem(
      title: 'Fridge clean-out',
      subtitle: 'Tonight',
      items: 6,
      done: false,
    ),
    SavedListItem(
      title: 'Weekend meal prep',
      subtitle: 'Sat · Sun',
      items: 8,
      done: false,
    ),
    SavedListItem(
      title: 'Shopping — greens',
      subtitle: 'Market list',
      items: 11,
      done: true,
    ),
    SavedListItem(
      title: 'Leftover lunches',
      subtitle: 'Work week',
      items: 5,
      done: false,
    ),
  ];

  static const prompts = [
    'What can I make with spinach and eggs?',
    'Use my leftover rice',
    'Low-waste dinner for two',
  ];
}
