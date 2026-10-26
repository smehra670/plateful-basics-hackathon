class UserPreferences {
  const UserPreferences({
    this.allergies = const [],
    this.diets = const ['Omnivore'],
    this.displayName = '',
    this.avoidIngredients = const [],
    this.favouriteCuisines = const [],
    this.spiceTolerance = 'Medium',
    this.householdSize = 2,
    this.defaultServings = 2,
    this.maxCookMinutes = 30,
    this.cookingSkill = 'Beginner',
    this.mealGoal = 'Balanced',
    this.equipment = const ['Oven', 'Hob', 'Microwave'],
    this.units = 'metric',
    this.expiryReminderDays = 7,
    this.weeklyRescueAimKg = 0.5,
    this.askBeforeDeducting = true,
    this.notifyExpiry = true,
    this.notifyMealPlan = false,
    this.notifyShopping = false,
    this.notifyPrep = false,
  });

  final List<String> allergies;
  final List<String> diets;
  final String displayName;
  final List<String> avoidIngredients;

  /// Joined label kept for older call sites and the API.
  String get dietType => diets.isEmpty ? 'Omnivore' : diets.join(' + ');

  static const styleDiets = ['Omnivore', 'Vegetarian', 'Vegan', 'Pescatarian'];
  static const practiceDiets = ['Halal', 'Kosher'];

  /// Eating styles replace each other. Halal and Kosher can sit alongside one style.
  static List<String> toggleDiet(List<String> current, String value) {
    final next = [...current];
    if (next.contains(value)) {
      next.remove(value);
      if (!next.any(styleDiets.contains)) next.insert(0, 'Omnivore');
      return next;
    }
    if (styleDiets.contains(value)) {
      next.removeWhere(styleDiets.contains);
    }
    next.add(value);
    return next;
  }

  String get recipePreview {
    final parts = <String>[
      for (final allergy in allergies) 'no ${allergy.toLowerCase()}',
      for (final diet in diets)
        if (diet != 'Omnivore') diet.toLowerCase(),
      if (favouriteCuisines.isNotEmpty) '${favouriteCuisines.first}-leaning',
    ];
    if (parts.isEmpty) return 'Your recipes: no hard rules yet';
    return 'Your recipes: ${parts.join(' · ')}';
  }
  final List<String> favouriteCuisines;
  final String spiceTolerance;
  final int householdSize;
  final int defaultServings;
  final int maxCookMinutes;
  final String cookingSkill;
  final String mealGoal;
  final List<String> equipment;
  final String units;
  final int expiryReminderDays;

  /// The only target on Impact: rescued kilograms for the current week.
  final double weeklyRescueAimKg;
  final bool askBeforeDeducting;
  final bool notifyExpiry;
  final bool notifyMealPlan;
  final bool notifyShopping;
  final bool notifyPrep;

  static const allergyOptions = [
    'Peanuts',
    'Tree nuts',
    'Dairy',
    'Eggs',
    'Gluten',
    'Soy',
    'Shellfish',
    'Fish',
    'Sesame',
  ];

  static const dietOptions = [
    'Omnivore',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Kosher',
  ];

  static const cuisineOptions = [
    'Italian',
    'Indian',
    'Japanese',
    'Mexican',
    'British',
    'Chinese',
    'Mediterranean',
    'Thai',
  ];

  static const spiceOptions = ['Mild', 'Medium', 'Spicy'];
  static const skillOptions = ['Beginner', 'Intermediate', 'Advanced'];
  static const goalOptions = [
    'High protein',
    'Weight gain',
    'Weight loss',
    'Balanced',
    'Budget-friendly',
    'Quick and easy',
  ];

  bool get tracksIntake =>
      mealGoal.toLowerCase().contains('gain') ||
      mealGoal.toLowerCase().contains('protein') ||
      mealGoal.toLowerCase().contains('loss');
  static const equipmentOptions = [
    'Oven',
    'Hob',
    'Microwave',
    'Air fryer',
    'Blender',
    'Slow cooker',
  ];
  static const cookMinuteOptions = [15, 30, 45, 60];

  UserPreferences copyWith({
    List<String>? allergies,
    List<String>? diets,
    String? displayName,
    List<String>? avoidIngredients,
    List<String>? favouriteCuisines,
    String? spiceTolerance,
    int? householdSize,
    int? defaultServings,
    int? maxCookMinutes,
    String? cookingSkill,
    String? mealGoal,
    List<String>? equipment,
    String? units,
    int? expiryReminderDays,
    double? weeklyRescueAimKg,
    bool? askBeforeDeducting,
    bool? notifyExpiry,
    bool? notifyMealPlan,
    bool? notifyShopping,
    bool? notifyPrep,
  }) {
    return UserPreferences(
      allergies: allergies ?? this.allergies,
      diets: diets ?? this.diets,
      displayName: displayName ?? this.displayName,
      avoidIngredients: avoidIngredients ?? this.avoidIngredients,
      favouriteCuisines: favouriteCuisines ?? this.favouriteCuisines,
      spiceTolerance: spiceTolerance ?? this.spiceTolerance,
      householdSize: householdSize ?? this.householdSize,
      defaultServings: defaultServings ?? this.defaultServings,
      maxCookMinutes: maxCookMinutes ?? this.maxCookMinutes,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      mealGoal: mealGoal ?? this.mealGoal,
      equipment: equipment ?? this.equipment,
      units: units ?? this.units,
      expiryReminderDays: expiryReminderDays ?? this.expiryReminderDays,
      weeklyRescueAimKg: weeklyRescueAimKg ?? this.weeklyRescueAimKg,
      askBeforeDeducting: askBeforeDeducting ?? this.askBeforeDeducting,
      notifyExpiry: notifyExpiry ?? this.notifyExpiry,
      notifyMealPlan: notifyMealPlan ?? this.notifyMealPlan,
      notifyShopping: notifyShopping ?? this.notifyShopping,
      notifyPrep: notifyPrep ?? this.notifyPrep,
    );
  }

  Map<String, dynamic> toJson() => {
        'allergies': allergies,
        'diets': diets,
        'dietType': dietType,
        'displayName': displayName,
        'avoidIngredients': avoidIngredients,
        'favouriteCuisines': favouriteCuisines,
        'spiceTolerance': spiceTolerance,
        'householdSize': householdSize,
        'defaultServings': defaultServings,
        'maxCookMinutes': maxCookMinutes,
        'cookingSkill': cookingSkill,
        'mealGoal': mealGoal,
        'equipment': equipment,
        'units': units,
        'expiryReminderDays': expiryReminderDays,
        'weeklyRescueAimKg': weeklyRescueAimKg,
        'askBeforeDeducting': askBeforeDeducting,
        'notifyExpiry': notifyExpiry,
        'notifyMealPlan': notifyMealPlan,
        'notifyShopping': notifyShopping,
        'notifyPrep': notifyPrep,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList();

    final storedDiets = strings('diets');
    final legacy = json['dietType'] as String?;
    final diets = storedDiets.isNotEmpty
        ? storedDiets
        : (legacy == null || legacy.trim().isEmpty)
            ? const ['Omnivore']
            : legacy
                .split(RegExp(r'\s*\+\s*'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

    return UserPreferences(
      allergies: strings('allergies'),
      diets: diets,
      displayName: json['displayName'] as String? ?? '',
      avoidIngredients: strings('avoidIngredients'),
      favouriteCuisines: strings('favouriteCuisines'),
      spiceTolerance: json['spiceTolerance'] as String? ?? 'Medium',
      householdSize: (json['householdSize'] as num?)?.toInt() ?? 2,
      defaultServings: (json['defaultServings'] as num?)?.toInt() ?? 2,
      maxCookMinutes: (json['maxCookMinutes'] as num?)?.toInt() ?? 30,
      cookingSkill: json['cookingSkill'] as String? ?? 'Beginner',
      mealGoal: json['mealGoal'] as String? ?? 'Balanced',
      equipment: strings('equipment').isEmpty
          ? const ['Oven', 'Hob', 'Microwave']
          : strings('equipment'),
      units: json['units'] as String? ?? 'metric',
      expiryReminderDays: (json['expiryReminderDays'] as num?)?.toInt() ?? 7,
      weeklyRescueAimKg: (json['weeklyRescueAimKg'] as num?)?.toDouble() ?? 0.5,
      askBeforeDeducting: json['askBeforeDeducting'] as bool? ?? true,
      notifyExpiry: json['notifyExpiry'] as bool? ?? true,
      notifyMealPlan: json['notifyMealPlan'] as bool? ?? false,
      notifyShopping: json['notifyShopping'] as bool? ?? false,
      notifyPrep: json['notifyPrep'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toRecipePayload() => {
        'allergies': allergies,
        'diets': diets,
        'dietType': dietType,
        'avoidIngredients': avoidIngredients,
        'favouriteCuisines': favouriteCuisines,
        'spiceTolerance': spiceTolerance,
        'servings': defaultServings,
        'householdSize': householdSize,
        'maxCookMinutes': maxCookMinutes,
        'cookingSkill': cookingSkill,
        'mealGoal': mealGoal,
        'equipment': equipment,
        'units': units,
      };
}
