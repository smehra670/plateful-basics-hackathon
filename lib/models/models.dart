import 'dart:convert';

class PantryIngredient {
  const PantryIngredient({
    required this.id,
    required this.name,
    required this.quantityRemaining,
    required this.unit,
    this.expiryDate,
    this.timesUsed = 0,
    this.totalQuantityUsed = 0,
    this.imageUrl,
    this.estimatedUnitValueGbp = 0.3,
    this.storagePlace,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double quantityRemaining;
  final String unit;
  final DateTime? expiryDate;
  final int timesUsed;
  final double totalQuantityUsed;
  final String? imageUrl;
  final double estimatedUnitValueGbp;
  final String? storagePlace;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => quantityRemaining > 0;

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return exp.difference(today).inDays;
  }

  bool isExpiringSoon(int withinDays) {
    if (!isAvailable) return false;
    final days = daysUntilExpiry;
    if (days == null) return false;
    return days >= 0 && days <= withinDays;
  }

  String get normalizedName => name.trim().toLowerCase();

  PantryIngredient copyWith({
    String? id,
    String? name,
    double? quantityRemaining,
    String? unit,
    DateTime? expiryDate,
    int? timesUsed,
    double? totalQuantityUsed,
    String? imageUrl,
    double? estimatedUnitValueGbp,
    String? storagePlace,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearExpiry = false,
  }) {
    return PantryIngredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      unit: unit ?? this.unit,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      timesUsed: timesUsed ?? this.timesUsed,
      totalQuantityUsed: totalQuantityUsed ?? this.totalQuantityUsed,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedUnitValueGbp:
          estimatedUnitValueGbp ?? this.estimatedUnitValueGbp,
      storagePlace: storagePlace ?? this.storagePlace,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'quantity_remaining': quantityRemaining,
        'unit': unit,
        'expiry_date': expiryDate?.toIso8601String(),
        'times_used': timesUsed,
        'total_quantity_used': totalQuantityUsed,
        'image_url': imageUrl,
        'estimated_unit_value_gbp': estimatedUnitValueGbp,
        'storage_place': storagePlace,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PantryIngredient.fromMap(Map<String, Object?> map) {
    return PantryIngredient(
      id: map['id']! as String,
      name: map['name']! as String,
      quantityRemaining: (map['quantity_remaining'] as num).toDouble(),
      unit: map['unit']! as String,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date']! as String)
          : null,
      timesUsed: map['times_used'] as int? ?? 0,
      totalQuantityUsed:
          (map['total_quantity_used'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url'] as String?,
      estimatedUnitValueGbp:
          (map['estimated_unit_value_gbp'] as num?)?.toDouble() ?? 0.3,
      storagePlace: map['storage_place'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.inPantry,
    this.estimatedCostGbp = 0,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool inPantry;
  final double estimatedCostGbp;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'inPantry': inPantry,
        'estimatedCostGbp': estimatedCostGbp,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      inPantry: json['inPantry'] as bool? ?? false,
      estimatedCostGbp:
          (json['estimatedCostGbp'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cookingTimeMinutes,
    required this.difficulty,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.sugar = 0,
    this.fibre = 0,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.estimatedAdditionalCostGbp,
    this.rescueLine = '',
    this.plating = '',
    this.wasteTip = '',
    this.isDemo = false,
    this.assetImage,
    this.mealSlot,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int cookingTimeMinutes;
  final String difficulty;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double sugar;
  final double fibre;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final double estimatedAdditionalCostGbp;
  final String rescueLine;
  final String plating;
  final String wasteTip;
  final bool isDemo;
  final String? assetImage;
  final String? mealSlot;

  List<RecipeIngredient> get availableIngredients =>
      ingredients.where((i) => i.inPantry).toList();

  List<RecipeIngredient> get missingIngredients =>
      ingredients.where((i) => !i.inPantry).toList();

  int get missingCount => missingIngredients.length;

  String get availabilityBadge {
    if (missingCount == 0) return 'Ready to cook';
    if (missingCount == 1) return 'Missing 1 ingredient';
    return 'Missing $missingCount ingredients';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'cooking_time': cookingTimeMinutes,
        'difficulty': difficulty,
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'sugar': sugar,
        'fibre': fibre,
        'servings': servings,
        'estimated_additional_cost': estimatedAdditionalCostGbp,
        'instructions_json': jsonEncode(instructions),
        'ingredients_json':
            jsonEncode(ingredients.map((e) => e.toJson()).toList()),
        'is_demo': isDemo ? 1 : 0,
        'asset_image': assetImage,
      };

  factory Recipe.fromMap(Map<String, Object?> map) {
    final ingredientsJson =
        jsonDecode(map['ingredients_json']! as String) as List<dynamic>;
    final instructionsJson =
        jsonDecode(map['instructions_json']! as String) as List<dynamic>;
    return Recipe(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description']! as String,
      imageUrl: map['image_url']! as String,
      cookingTimeMinutes: map['cooking_time'] as int,
      difficulty: map['difficulty']! as String,
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbohydrates: (map['carbohydrates'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      fibre: (map['fibre'] as num?)?.toDouble() ?? 0,
      servings: map['servings'] as int,
      estimatedAdditionalCostGbp:
          (map['estimated_additional_cost'] as num).toDouble(),
      instructions: instructionsJson.map((e) => e as String).toList(),
      ingredients: ingredientsJson
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      rescueLine: map['rescue_line'] as String? ?? '',
      plating: map['plating'] as String? ?? '',
      wasteTip: map['waste_tip'] as String? ?? '',
      isDemo: (map['is_demo'] as int? ?? 0) == 1,
      assetImage: map['asset_image'] as String?,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = (json['ingredients'] as List<dynamic>)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
    return Recipe(
      id: json['id'] as String,
      title: json['name'] as String? ?? json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      cookingTimeMinutes: json['cookingTime'] as int? ??
          json['cookingTimeMinutes'] as int? ??
          20,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      fibre: (json['fibre'] as num?)?.toDouble() ?? 0,
      servings: json['servings'] as int? ?? 2,
      ingredients: ingredients,
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      estimatedAdditionalCostGbp:
          (json['estimatedAdditionalCost'] as num?)?.toDouble() ??
              (json['estimatedAdditionalCostGbp'] as num?)?.toDouble() ??
              0,
      rescueLine: json['rescueLine'] as String? ?? '',
      plating: json['plating'] as String? ?? json['platingNote'] as String? ?? '',
      wasteTip: json['wasteTip'] as String? ?? '',
      isDemo: json['isDemo'] as bool? ?? false,
      assetImage: json['assetImage'] as String?,
      mealSlot: json['mealSlot'] as String? ?? json['slot'] as String?,
    );
  }

  Recipe copyWith({
    bool? isDemo,
    String? assetImage,
    String? imageUrl,
    String? mealSlot,
    String? rescueLine,
    String? plating,
    String? wasteTip,
  }) {
    return Recipe(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      cookingTimeMinutes: cookingTimeMinutes,
      difficulty: difficulty,
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      sugar: sugar,
      fibre: fibre,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions,
      estimatedAdditionalCostGbp: estimatedAdditionalCostGbp,
      rescueLine: rescueLine ?? this.rescueLine,
      plating: plating ?? this.plating,
      wasteTip: wasteTip ?? this.wasteTip,
      isDemo: isDemo ?? this.isDemo,
      assetImage: assetImage ?? this.assetImage,
      mealSlot: mealSlot ?? this.mealSlot,
    );
  }
}

class ClarificationQuestion {
  const ClarificationQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.allowOther = true,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final bool allowOther;

  factory ClarificationQuestion.fromJson(Map<String, dynamic> json) {
    return ClarificationQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      allowOther: json['allowOther'] as bool? ?? true,
    );
  }
}

class IngredientBox {
  const IngredientBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final double x;
  final double y;
  final double w;
  final double h;

  factory IngredientBox.fromJson(Map<String, dynamic> json) {
    return IngredientBox(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      w: (json['w'] as num?)?.toDouble() ?? 0,
      h: (json['h'] as num?)?.toDouble() ?? 0,
    );
  }

  bool get usable => w > 0.04 && h > 0.04;

  String get key =>
      '${(x * 20).round()}-${(y * 20).round()}-${(w * 20).round()}-${(h * 20).round()}';
}

class DetectedIngredient {
  const DetectedIngredient({
    required this.name,
    this.quantity,
    this.unit = 'pcs',
    this.confidence = 1,
    this.needsClarification = false,
    this.box,
    this.shelfLifeDays,
    this.storagePlace,
    this.estimatedPriceGbp,
  });

  final String name;
  final double? quantity;
  final String unit;
  final double confidence;
  final bool needsClarification;
  final IngredientBox? box;
  final int? shelfLifeDays;
  final String? storagePlace;
  final double? estimatedPriceGbp;

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    final rawBox = json['box'];
    return DetectedIngredient(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
      needsClarification: json['needsClarification'] as bool? ?? false,
      box: rawBox is Map<String, dynamic>
          ? IngredientBox.fromJson(rawBox)
          : rawBox is Map
              ? IngredientBox.fromJson(Map<String, dynamic>.from(rawBox))
              : null,
      shelfLifeDays: (json['shelfLifeDays'] as num?)?.toInt(),
      storagePlace: json['storagePlace'] as String?,
      estimatedPriceGbp: (json['estimatedPriceGbp'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'confidence': confidence,
        'needsClarification': needsClarification,
        if (box != null)
          'box': {'x': box!.x, 'y': box!.y, 'w': box!.w, 'h': box!.h},
        if (shelfLifeDays != null) 'shelfLifeDays': shelfLifeDays,
        if (storagePlace != null) 'storagePlace': storagePlace,
        if (estimatedPriceGbp != null) 'estimatedPriceGbp': estimatedPriceGbp,
      };

  DetectedIngredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? confidence,
    bool? needsClarification,
    IngredientBox? box,
  }) {
    return DetectedIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      needsClarification: needsClarification ?? this.needsClarification,
      box: box ?? this.box,
    );
  }
}

class AnalyseImageResult {
  const AnalyseImageResult({
    required this.ingredients,
    required this.questions,
    this.isDemo = false,
  });

  final List<DetectedIngredient> ingredients;
  final List<ClarificationQuestion> questions;
  final bool isDemo;

  factory AnalyseImageResult.fromJson(Map<String, dynamic> json) {
    return AnalyseImageResult(
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => DetectedIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map(
            (e) => ClarificationQuestion.fromJson(e as Map<String, dynamic>),
          )
          .take(3)
          .toList(),
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }
}

class CookingEvent {
  const CookingEvent({
    required this.id,
    required this.recipeId,
    required this.timestamp,
    required this.servingsPrepared,
    this.calories = 0,
    this.protein = 0,
    this.carbohydrates = 0,
    this.fat = 0,
    this.fibre = 0,
    this.title,
    this.planKey,
  });

  final String id;
  final String recipeId;
  final DateTime timestamp;
  final int servingsPrepared;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fibre;
  final String? title;
  final String? planKey;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'timestamp': timestamp.toIso8601String(),
        'servings_prepared': servingsPrepared,
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'fibre': fibre,
        'title': title,
        'plan_key': planKey,
      };

  factory CookingEvent.fromMap(Map<String, Object?> map) {
    return CookingEvent(
      id: map['id']! as String,
      recipeId: map['recipe_id']! as String,
      timestamp: DateTime.parse(map['timestamp']! as String),
      servingsPrepared: map['servings_prepared'] as int,
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fibre: (map['fibre'] as num?)?.toDouble() ?? 0,
      title: map['title'] as String?,
      planKey: map['plan_key'] as String?,
    );
  }
}

class EatenLogEntry {
  const EatenLogEntry({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.fibre = 0,
    required this.sugar,
    this.planKey,
  });

  final String id;
  final String title;
  final DateTime timestamp;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fibre;
  final double sugar;
  final String? planKey;

  factory EatenLogEntry.fromMap(Map<String, Object?> map) {
    return EatenLogEntry(
      id: map['id']! as String,
      title: map['title'] as String? ?? 'Meal',
      timestamp: DateTime.parse(map['timestamp']! as String),
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fibre: (map['fibre'] as num?)?.toDouble() ?? 0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      planKey: map['plan_key'] as String?,
    );
  }

  bool countsOn(String date) {
    final key = planKey;
    if (key != null && key.isNotEmpty) return key.startsWith('$date|');
    final local = timestamp.toLocal();
    final day =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return day == date;
  }
}

class IngredientUsageEvent {
  const IngredientUsageEvent({
    required this.id,
    required this.ingredientId,
    required this.recipeId,
    required this.quantityUsed,
    required this.unit,
    required this.timestamp,
    this.wasNearExpiry = false,
  });

  final String id;
  final String ingredientId;
  final String recipeId;
  final double quantityUsed;
  final String unit;
  final DateTime timestamp;
  final bool wasNearExpiry;

  Map<String, Object?> toMap() => {
        'id': id,
        'ingredient_id': ingredientId,
        'recipe_id': recipeId,
        'quantity_used': quantityUsed,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'was_near_expiry': wasNearExpiry ? 1 : 0,
      };

  factory IngredientUsageEvent.fromMap(Map<String, Object?> map) {
    return IngredientUsageEvent(
      id: map['id']! as String,
      ingredientId: map['ingredient_id']! as String,
      recipeId: map['recipe_id']! as String,
      quantityUsed: (map['quantity_used'] as num).toDouble(),
      unit: map['unit']! as String,
      timestamp: DateTime.parse(map['timestamp']! as String),
      wasNearExpiry: (map['was_near_expiry'] as int? ?? 0) == 1,
    );
  }
}

class RescuedFood {
  const RescuedFood({required this.name, required this.kilograms});

  final String name;
  final double kilograms;
}

/// What was rescued when a meal was marked eaten (near-expiry pantry uses only).
class CookRescueSummary {
  const CookRescueSummary({
    this.rescuedKg = 0,
    this.highlightFood,
  });

  final double rescuedKg;
  final String? highlightFood;

  bool get hasRescue => rescuedKg >= 0.005 && (highlightFood ?? '').isNotEmpty;
}

/// Flash shown on Impact after cooking, for the count-up wow moment.
class ImpactRescueFlash {
  const ImpactRescueFlash({
    required this.previousKg,
    required this.rescuedKg,
    required this.highlightFood,
  });

  final double previousKg;
  final double rescuedKg;
  final String highlightFood;
}

class ImpactMeal {
  const ImpactMeal({
    required this.title,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.timestamp,
    this.rescuedFoods = const [],
    this.rescuedKg = 0,
  });

  final String title;
  final String imageUrl;
  final int calories;
  final double protein;
  final DateTime timestamp;
  final List<String> rescuedFoods;
  final double rescuedKg;
}

class ImpactStats {
  const ImpactStats({
    required this.mealsCooked,
    required this.totalIngredientsUsed,
    required this.estimatedValueUtilisedGbp,
    required this.ingredientsUsedBeforeExpiry,
    this.estimatedWasteAvoidedKg,
    this.caloriesEaten = 0,
    this.proteinEaten = 0,
    this.carbohydratesEaten = 0,
    this.fatEaten = 0,
    this.fibreEaten = 0,
    this.foodSavedThisWeekKg = 0,
    this.nearExpiryUsesThisWeek = 0,
    this.usageEvents = 0,
    this.savedKgLast7Days = const [],
    this.savedKgPrevious7Days = const [],
    this.mealsLast7Days = const [],
    this.caloriesLast7Days = const [],
    this.proteinLast7Days = const [],
    this.carbsLast7Days = const [],
    this.fatLast7Days = const [],
    this.fibreLast7Days = const [],
    this.valueGbpLast7Days = const [],
    this.cumulativeSavedKg = const [],
    this.cumulativeIsComplete = true,
    this.mealsMissingExpiry = 0,
    this.topRescuedFoods = const [],
    this.recentMeals = const [],
    this.monthCookedDays = const [],
    this.monthRescuedDays = const [],
    this.cookStreakDays = 0,
    this.weeklyAimKg = 0.5,
  });

  final int mealsCooked;
  final double totalIngredientsUsed;
  final double estimatedValueUtilisedGbp;
  final int ingredientsUsedBeforeExpiry;
  final double? estimatedWasteAvoidedKg;
  final int caloriesEaten;
  final double proteinEaten;
  final double carbohydratesEaten;
  final double fatEaten;
  final double fibreEaten;
  final double foodSavedThisWeekKg;
  final int nearExpiryUsesThisWeek;
  final int usageEvents;
  final List<double> savedKgLast7Days;
  final List<double> savedKgPrevious7Days;
  final List<int> mealsLast7Days;
  final List<int> caloriesLast7Days;
  final List<double> proteinLast7Days;
  final List<double> carbsLast7Days;
  final List<double> fatLast7Days;
  final List<double> fibreLast7Days;
  final List<double> valueGbpLast7Days;
  final List<double> cumulativeSavedKg;
  final bool cumulativeIsComplete;
  final int mealsMissingExpiry;
  final List<RescuedFood> topRescuedFoods;
  final List<ImpactMeal> recentMeals;
  final List<int> monthCookedDays;
  final List<int> monthRescuedDays;
  final int cookStreakDays;
  final double weeklyAimKg;

  bool get hasData => mealsCooked > 0;

  /// Share of pantry uses that were outside the expiry reminder window.
  double? get stillFreshShare {
    if (usageEvents <= 0) return null;
    final fresh = usageEvents - ingredientsUsedBeforeExpiry;
    if (fresh < 0) return null;
    return fresh / usageEvents;
  }
}

class CookDeduction {
  CookDeduction({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.proposedQuantity,
    required this.maxAvailable,
  });

  final String ingredientId;
  final String name;
  final String unit;
  double proposedQuantity;
  final double maxAvailable;
}
