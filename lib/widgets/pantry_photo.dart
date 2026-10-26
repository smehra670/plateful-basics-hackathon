import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/food_facts.dart';

class PantryPhoto extends StatelessWidget {
  const PantryPhoto({
    super.key,
    this.path,
    this.name,
    this.fit = BoxFit.cover,
    this.showIconFallback = false,
  });

  final String? path;
  final String? name;
  final BoxFit fit;

  /// Kitchen list uses the user's photo only. Icons are for other screens.
  final bool showIconFallback;

  @override
  Widget build(BuildContext context) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return _fallback(name);
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        fit: fit,
        errorWidget: (_, _, _) => _fallback(name),
      );
    }
    final file = File(value);
    if (!file.existsSync()) return _fallback(name);
    return Image.file(file, fit: fit);
  }

  Widget _fallback(String? name) {
    final aisle = name == null ? 'Cupboard' : FoodFacts.aisle(name);
    final wash = switch (aisle) {
      'Fruit & veg' => AppColors.sageSoft,
      'Dairy' => AppColors.peachSoft,
      'Meat & fish' => AppColors.roseSoft,
      'Bakery' => AppColors.butterSoft,
      _ => AppColors.skySoft,
    };
    final ink = switch (aisle) {
      'Fruit & veg' => AppColors.forest,
      'Dairy' => AppColors.peachText,
      'Meat & fish' => AppColors.roseText,
      'Bakery' => AppColors.butterText,
      _ => AppColors.skyText,
    };
    final letter = (name == null || name.trim().isEmpty)
        ? '?'
        : name.trim()[0].toUpperCase();
    if (!showIconFallback) {
      return ColoredBox(
        color: wash,
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: wash,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
