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
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => quantityRemaining > 0;

  bool isExpiringSoon(int withinDays) {
    if (expiryDate == null || !isAvailable) return false;
    final days = expiryDate!.difference(DateTime.now()).inDays;
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
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.estimatedAdditionalCostGbp,
    this.isDemo = false,
    this.assetImage,
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
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final double estimatedAdditionalCostGbp;
  final bool isDemo;
  final String? assetImage;

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
      servings: map['servings'] as int,
      estimatedAdditionalCostGbp:
          (map['estimated_additional_cost'] as num).toDouble(),
      instructions: instructionsJson.map((e) => e as String).toList(),
      ingredients: ingredientsJson
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      servings: json['servings'] as int? ?? 2,
      ingredients: ingredients,
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      estimatedAdditionalCostGbp:
          (json['estimatedAdditionalCost'] as num?)?.toDouble() ??
              (json['estimatedAdditionalCostGbp'] as num?)?.toDouble() ??
              0,
      isDemo: json['isDemo'] as bool? ?? false,
      assetImage: json['assetImage'] as String?,
    );
  }

  Recipe copyWith({bool? isDemo, String? assetImage}) {
    return Recipe(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      cookingTimeMinutes: cookingTimeMinutes,
      difficulty: difficulty,
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions,
      estimatedAdditionalCostGbp: estimatedAdditionalCostGbp,
      isDemo: isDemo ?? this.isDemo,
      assetImage: assetImage ?? this.assetImage,
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

class DetectedIngredient {
  const DetectedIngredient({
    required this.name,
    this.quantity,
    this.unit = 'pcs',
    this.confidence = 1,
    this.needsClarification = false,
  });

  final String name;
  final double? quantity;
  final String unit;
  final double confidence;
  final bool needsClarification;

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
      needsClarification: json['needsClarification'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'confidence': confidence,
        'needsClarification': needsClarification,
      };
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
  });

  final String id;
  final String recipeId;
  final DateTime timestamp;
  final int servingsPrepared;

  Map<String, Object?> toMap() => {
        'id': id,
        'recipe_id': recipeId,
        'timestamp': timestamp.toIso8601String(),
        'servings_prepared': servingsPrepared,
      };

  factory CookingEvent.fromMap(Map<String, Object?> map) {
    return CookingEvent(
      id: map['id']! as String,
      recipeId: map['recipe_id']! as String,
      timestamp: DateTime.parse(map['timestamp']! as String),
      servingsPrepared: map['servings_prepared'] as int,
    );
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

class ImpactStats {
  const ImpactStats({
    required this.mealsCooked,
    required this.totalIngredientsUsed,
    required this.estimatedValueUtilisedGbp,
    required this.ingredientsUsedBeforeExpiry,
    this.estimatedWasteAvoidedKg,
  });

  final int mealsCooked;
  final double totalIngredientsUsed;
  final double estimatedValueUtilisedGbp;
  final int ingredientsUsedBeforeExpiry;
  final double? estimatedWasteAvoidedKg;

  bool get hasData => mealsCooked > 0;
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
