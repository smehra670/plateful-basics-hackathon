import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/chef_showcase_recipes.dart';
import '../data/demo_data.dart';
import '../models/meal_plan.dart';
import '../models/models.dart';
import '../models/user_preferences.dart';
import '../utils/expiry.dart';
import '../utils/pantry_match.dart';
import '../utils/plan_allocation.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/impact_service.dart';
import '../services/pantry_service.dart';
import '../services/recipe_service.dart';
import '../services/settings_service.dart';

enum ChefPhase { idle, loading, swiping, results }

class AppState extends ChangeNotifier {
  AppState({
    PantryService? pantryService,
    RecipeService? recipeService,
    ImpactService? impactService,
    ApiClient? apiClient,
    SettingsService? settingsService,
  })  : _pantryService = pantryService ?? PantryService(),
        _recipeService = recipeService ?? RecipeService(),
        _impactService = impactService ?? ImpactService(),
        _api = apiClient ?? ApiClient(),
        _settings = settingsService ?? SettingsService();

  final PantryService _pantryService;
  final RecipeService _recipeService;
  final ImpactService _impactService;
  final ApiClient _api;
  final SettingsService _settings;

  bool ready = false;
  bool usingDemoPipeline = false;
  bool reconnecting = false;
  String? error;

  bool get serverReachable => _api.isServerReachable;

  List<PantryIngredient> ingredients = [];
  List<Recipe> savedRecipes = [];
  Set<String> savedIds = {};
  List<EatenLogEntry> eatenLog = [];
  ImpactStats impact = const ImpactStats(
    mealsCooked: 0,
    totalIngredientsUsed: 0,
    estimatedValueUtilisedGbp: 0,
    ingredientsUsedBeforeExpiry: 0,
  );
  ImpactRescueFlash? lastRescueFlash;

  // Scan / clarification
  File? pendingImage;
  AnalyseImageResult? lastAnalyse;
  Map<String, String> clarificationAnswers = {};
  String? selectedCourse;

  // Chef / swipe
  ChefPhase chefPhase = ChefPhase.idle;
  List<Recipe> deck = [];
  List<Recipe> shortlist = [];
  List<_SwipeAction> _swipeHistory = [];
  int swipeIndex = 0;

  int shellTabIndex = 0;
  UserPreferences preferences = const UserPreferences();
  MealPlan? mealPlan;
  bool plannerLoading = false;
  String? plannerError;
  bool welcomeSeen = false;
  bool onboardingSeen = false;

  Future<void> init() async {
    await _api.checkHealth();
    usingDemoPipeline = _api.isDemoMode || !_api.openaiConfigured;
    preferences = await _settings.load();
    welcomeSeen = (await _settings.loadJson('welcome_v1'))?['seen'] == true;
    onboardingSeen = (await _settings.loadJson('onboarding_v1'))?['seen'] == true;
    final savedPlan = await _settings.loadJson('meal_plan');
    if (savedPlan != null) {
      try {
        mealPlan = MealPlan.fromJson(savedPlan);
      } catch (_) {}
    }
    final graphsReset = await _settings.loadJson('graphs_reset_v3');
    if (graphsReset?['done'] != true) {
      await _clearNutritionAndCarbon();
      await _settings.saveJson('graphs_reset_v3', {'done': true});
    }
    await refreshAll();
    if (mealPlan != null) {
      unawaited(_hydratePlanImages());
    }
    final savedShortlist = await _settings.loadJson('shortlist_v1');
    final rawShort = savedShortlist?['recipes'];
    if (rawShort is List && rawShort.isNotEmpty) {
      shortlist = [
        for (final item in rawShort)
          if (item is Map) Recipe.fromJson(Map<String, dynamic>.from(item)),
      ];
    }

    // Only seed demo pantry when live OpenAI is unavailable.
    if (ingredients.isEmpty && usingDemoPipeline) {
      for (final item in DemoData.seedPantryIngredients()) {
        await _pantryService.upsertManual(item);
      }
      await refreshAll();
    }
    ready = true;
    notifyListeners();
  }

  /// Re-probe the API after starting the server / USB tunnel.
  Future<bool> reconnectServer() async {
    reconnecting = true;
    error = null;
    notifyListeners();
    final ok = await _api.checkHealth();
    usingDemoPipeline = _api.isDemoMode || !_api.openaiConfigured;
    reconnecting = false;
    if (!ok) {
      error = ApiClient.unreachableMessage;
    }
    notifyListeners();
    return ok && _api.openaiConfigured;
  }

  Future<void> refreshAll() async {
    ingredients = await _pantryService.getAll();
    savedRecipes = await _recipeService.getSavedRecipes();
    savedIds = await _recipeService.getSavedIds();
    impact = await _impactService.compute();
    eatenLog = await _pantryService.eatenLog();
    notifyListeners();
    unawaited(
      NotificationService.instance.sync(
        preferences: preferences,
        ingredients: ingredients,
        plan: mealPlan,
      ),
    );
  }

  List<PantryIngredient> get availableIngredients =>
      ingredients.where((i) => i.isAvailable).toList();

  List<PantryIngredient> get previouslyUsedIngredients =>
      ingredients.where((i) => !i.isAvailable).toList();

  int get expirySoonDays => preferences.expiryReminderDays;

  Future<void> markWelcomeSeen() async {
    welcomeSeen = true;
    notifyListeners();
    await _settings.saveJson('welcome_v1', {'seen': true});
  }

  Future<void> markOnboardingSeen() async {
    onboardingSeen = true;
    notifyListeners();
    await _settings.saveJson('onboarding_v1', {'seen': true});
  }

  Future<void> updatePreferences(UserPreferences next) async {
    preferences = next;
    notifyListeners();
    await _settings.save(next);
    unawaited(
      NotificationService.instance.sync(
        preferences: preferences,
        ingredients: ingredients,
        plan: mealPlan,
      ),
    );
  }

  List<PantryIngredient> get useSoonIngredients {
    final items = availableIngredients
        .where((i) => i.isExpiringSoon(expirySoonDays))
        .toList()
      ..sort(_byExpiry);
    return items;
  }

  List<PantryIngredient> get expiredIngredients {
    final items = availableIngredients
        .where((i) => ExpiryInfo.urgency(i) == ExpiryUrgency.expired)
        .toList()
      ..sort(_byExpiry);
    return items;
  }

  List<PantryIngredient> get cookableIngredients {
    final items = availableIngredients
        .where((i) => ExpiryInfo.urgency(i) != ExpiryUrgency.expired)
        .toList()
      ..sort(_byExpiry);
    return items;
  }

  List<PantryIngredient> expiredItemsUsedBy(Recipe recipe) {
    return expiredIngredients
        .where(
          (p) => recipe.ingredients.any(
            (i) => i.inPantry && pantryNamesMatch(i.name, p.name),
          ),
        )
        .toList();
  }

  String? cookBlockReason(Recipe recipe) {
    final expired = expiredItemsUsedBy(recipe);
    if (expired.isEmpty) return null;
    final names = expired.map((e) => e.name).join(', ');
    return 'You cannot cook this while it uses expired $names. Bin or replace those items first.';
  }

  List<PantryIngredient> get urgentIngredients {
    final items = availableIngredients
        .where((i) => ExpiryInfo.urgency(i) == ExpiryUrgency.day)
        .toList()
      ..sort(_byExpiry);
    return items;
  }

  List<PantryIngredient> get weekIngredients {
    final items = availableIngredients
        .where(
          (i) =>
              ExpiryInfo.urgency(i, soonDays: expirySoonDays) ==
              ExpiryUrgency.week,
        )
        .toList()
      ..sort(_byExpiry);
    return items;
  }

  List<PantryIngredient> get stableIngredients {
    final items = availableIngredients
        .where(
          (i) =>
              ExpiryInfo.urgency(i, soonDays: expirySoonDays) ==
              ExpiryUrgency.none,
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  static int _byExpiry(PantryIngredient a, PantryIngredient b) {
    final da = ExpiryInfo.daysLeft(a) ?? 9999;
    final db = ExpiryInfo.daysLeft(b) ?? 9999;
    final c = da.compareTo(db);
    if (c != 0) return c;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Future<AnalyseImageResult> analyseImageFile(
    File file, {
    bool skipHealthCheck = false,
  }) async {
    error = null;
    notifyListeners();
    try {
      return await _api.analyseImage(file, skipHealthCheck: skipHealthCheck);
    } catch (e) {
      if (skipHealthCheck) {
        try {
          return await _api.analyseImage(file, skipHealthCheck: false);
        } catch (retry) {
          error = 'Could not analyse this photo. ${retry.toString()}';
          notifyListeners();
          rethrow;
        }
      }
      error = 'Could not analyse this photo. ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void setShellTab(int index) {
    shellTabIndex = index;
    notifyListeners();
  }

  void setPendingImage(File? file) {
    pendingImage = file;
    notifyListeners();
  }

  Future<AnalyseImageResult> analysePendingImage() async {
    if (pendingImage == null) {
      throw StateError('No image selected');
    }
    error = null;
    notifyListeners();
    try {
      final result = await _api.analyseImage(pendingImage!);
      lastAnalyse = result;
      usingDemoPipeline = result.isDemo || _api.isDemoMode;
      clarificationAnswers = {};
      notifyListeners();
      return result;
    } catch (e) {
      error = 'Could not analyse this photo. ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void answerClarification(String questionId, String answer) {
    clarificationAnswers[questionId] = answer;
    notifyListeners();
  }

  void setDetectedIngredients(List<DetectedIngredient> items) {
    lastAnalyse = AnalyseImageResult(
      ingredients: items,
      questions: lastAnalyse?.questions ?? const [],
      isDemo: lastAnalyse?.isDemo ?? false,
    );
    notifyListeners();
  }

  void setSelectedCourse(String course) {
    selectedCourse = course;
    notifyListeners();
  }

  Future<void> finalizeScanAndGenerate({
    bool fromPantryOnly = false,
    List<String>? pantryFocus,
  }) async {
    chefPhase = ChefPhase.loading;
    notifyListeners();

    final focusNames = <String>[];
    if (!fromPantryOnly) {
      final detected = lastAnalyse?.ingredients ?? [];
      final questions = lastAnalyse?.questions ?? [];
      for (final d in detected) {
        var name = d.name;
        if (d.needsClarification) {
          for (final q in questions) {
            final answer = clarificationAnswers[q.id]?.trim();
            if (answer == null || answer.isEmpty) continue;
            final mentionsIngredient = q.prompt.toLowerCase().contains(
                  d.name.toLowerCase().split(' ').first,
                );
            if (mentionsIngredient || clarificationAnswers.length == 1) {
              name = answer;
              break;
            }
          }
        }
        focusNames.add(name);
        await _pantryService.mergeIngredient(
          name: name,
          quantity: d.quantity ?? 1,
          unit: d.unit,
        );
      }
      await refreshAll();
    }

    await generateRecipesFromPantry(
      focusIngredients: fromPantryOnly
          ? (pantryFocus != null && pantryFocus.isNotEmpty
              ? pantryFocus
              : cookableIngredients.map((i) => i.name).toList())
          : focusNames,
    );
  }

  Future<void> generateRecipesFromPantry({
    List<String> focusIngredients = const [],
  }) async {
    chefPhase = ChefPhase.loading;
    shortlist = [];
    unawaited(_persistShortlist());
    _swipeHistory = [];
    swipeIndex = 0;
    error = null;
    notifyListeners();

    try {
      final cookable = cookableIngredients;
      if (cookable.isEmpty) {
        throw Exception(
          'Nothing in the pantry is still edible. Expired food cannot be cooked — add fresh items first.',
        );
      }
      // Recipe generator (swipe deck) always uses the five plated meals.
      // Weekly planner generation is a separate path and is not changed.
      final recipes = ChefShowcaseRecipes.forPantry(cookable);
      usingDemoPipeline = false;
      await _recipeService.upsertMany(recipes);
      deck = recipes;
      chefPhase = recipes.isEmpty ? ChefPhase.idle : ChefPhase.swiping;
      notifyListeners();
      if (recipes.any((recipe) => (recipe.assetImage ?? '').isEmpty)) {
        unawaited(_hydrateDeckImages());
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
      deck = [];
      chefPhase = ChefPhase.idle;
      usingDemoPipeline = AppConfig.forceDemoMode;
    }
    notifyListeners();
  }

  void likeCurrent() {
    if (chefPhase != ChefPhase.swiping || swipeIndex >= deck.length) return;
    final recipe = deck[swipeIndex];
    shortlist = [...shortlist, recipe];
    _swipeHistory.add(_SwipeAction(recipe: recipe, liked: true));
    _advanceSwipe();
    unawaited(_persistShortlist());
  }

  void rejectCurrent() {
    if (chefPhase != ChefPhase.swiping || swipeIndex >= deck.length) return;
    final recipe = deck[swipeIndex];
    _swipeHistory.add(_SwipeAction(recipe: recipe, liked: false));
    _advanceSwipe();
    unawaited(_persistShortlist());
  }

  void _advanceSwipe() {
    swipeIndex += 1;
    if (swipeIndex >= deck.length) {
      chefPhase = ChefPhase.results;
    }
    notifyListeners();
  }

  void undoSwipe() {
    if (_swipeHistory.isEmpty) return;
    final last = _swipeHistory.removeLast();
    if (last.liked) {
      shortlist = shortlist.where((r) => r.id != last.recipe.id).toList();
    }
    swipeIndex = (swipeIndex - 1).clamp(0, deck.length);
    chefPhase = ChefPhase.swiping;
    notifyListeners();
    unawaited(_persistShortlist());
  }

  void removeFromShortlist(String recipeId) {
    shortlist = shortlist.where((r) => r.id != recipeId).toList();
    notifyListeners();
    unawaited(_persistShortlist());
  }

  Future<void> _persistShortlist() async {
    await _settings.saveJson('shortlist_v1', {
      'recipes': [
        for (final recipe in shortlist)
          {
            'id': recipe.id,
            'name': recipe.title,
            'description': recipe.description,
            'imageUrl': recipe.imageUrl,
            'cookingTime': recipe.cookingTimeMinutes,
            'difficulty': recipe.difficulty,
            'calories': recipe.calories,
            'protein': recipe.protein,
            'carbohydrates': recipe.carbohydrates,
            'fat': recipe.fat,
            'sugar': recipe.sugar,
            'fibre': recipe.fibre,
            'assetImage': recipe.assetImage,
            'servings': recipe.servings,
            'ingredients': recipe.ingredients.map((e) => e.toJson()).toList(),
            'instructions': recipe.instructions,
            'estimatedAdditionalCost': recipe.estimatedAdditionalCostGbp,
            'rescueLine': recipe.rescueLine,
            'plating': recipe.plating,
            'wasteTip': recipe.wasteTip,
          },
      ],
    });
  }

  Future<void> toggleSave(Recipe recipe) async {
    if (savedIds.contains(recipe.id)) {
      await _recipeService.unsaveRecipe(recipe.id);
    } else {
      await _recipeService.saveRecipe(recipe);
    }
    savedIds = await _recipeService.getSavedIds();
    savedRecipes = await _recipeService.getSavedRecipes();
    notifyListeners();
  }

  Future<void> addIngredient({
    required String name,
    required double quantity,
    required String unit,
    DateTime? expiry,
    String? imageUrl,
    String? storagePlace,
    double? estimatedUnitValueGbp,
  }) async {
    await _pantryService.mergeIngredient(
      name: name,
      quantity: quantity,
      unit: unit,
      expiryDate: expiry,
      imageUrl: imageUrl,
      storagePlace: storagePlace,
      estimatedUnitValueGbp: estimatedUnitValueGbp,
    );
    await refreshAll();
  }

  Future<void> editIngredient(PantryIngredient item) async {
    await _pantryService.upsertManual(item.copyWith(updatedAt: DateTime.now()));
    await refreshAll();
  }

  Future<void> removeIngredient(String id) async {
    await _pantryService.remove(id);
    await refreshAll();
  }

  List<CookDeduction> proposedCookDeductions(Recipe recipe) {
    return _pantryService.proposedDeductions(recipe, ingredients);
  }

  Future<CookRescueSummary> confirmCook({
    required Recipe recipe,
    required List<CookDeduction> deductions,
    String? planDate,
    String? planSlot,
  }) async {
    final blocked = cookBlockReason(recipe);
    if (blocked != null) {
      throw Exception(blocked);
    }
    final previousKg = impact.estimatedWasteAvoidedKg ?? 0;
    final planId = mealPlan?.id ?? '';
    final planKey = (planDate != null && planSlot != null)
        ? (planId.isEmpty
            ? '$planDate|$planSlot'
            : '$planId|$planDate|$planSlot')
        : null;
    var summary = const CookRescueSummary();
    try {
      summary = await _pantryService.cookRecipe(
        recipe: recipe,
        deductions: deductions,
        servings: recipe.servings,
        planKey: planKey,
        soonDays: preferences.expiryReminderDays,
      );
    } catch (e) {
      final message = e.toString();
      if (!message.contains('already marked as eaten')) rethrow;
    }
    if (planKey != null) {
      mealPlan = mealPlan?.markingCompleted(planDate!, planSlot!, completed: true);
      await _persistPlan();
    }
    await refreshAll();
    if (summary.hasRescue) {
      lastRescueFlash = ImpactRescueFlash(
        previousKg: previousKg,
        rescuedKg: summary.rescuedKg,
        highlightFood: summary.highlightFood!,
      );
      notifyListeners();
    }
    return summary;
  }

  void clearLastRescueFlash() {
    if (lastRescueFlash == null) return;
    lastRescueFlash = null;
    notifyListeners();
  }

  Future<void> loadDemoImpactWeek() async {
    await _pantryService.seedDemoImpactWeek();
    await refreshAll();
  }

  Future<void> resetNutrientGraphs() async {
    await _clearNutritionAndCarbon();
    await refreshAll();
  }

  /// Zeros calorie, nutrient, and carbon graphs, and takes the meal that
  /// created the carbon saving off the plan.
  Future<void> _clearNutritionAndCarbon() async {
    lastRescueFlash = null;
    final rescueKeys = await _pantryService.rescuePlanKeys();
    await _pantryService.clearAllGraphHistory();
    final plan = mealPlan;
    if (plan == null) return;
    mealPlan = plan.withoutRescuedMeals(rescueKeys);
    await _persistPlan();
  }

  bool isPlannedMealCompleted(String date, String slot) {
    return mealPlan?.mealAt(date, slot)?.completed ?? false;
  }

  Future<void> completePlannedMeal(PlannedMeal meal) async {
    if (meal.completed) return;
    final deductions = proposedCookDeductions(meal.recipe);
    await confirmCook(
      recipe: meal.recipe,
      deductions: deductions,
      planDate: meal.date,
      planSlot: meal.slot,
    );
  }

  Future<List<IngredientUsageEvent>> usageFor(String ingredientId) {
    return _pantryService.usageHistory(ingredientId);
  }

  Future<List<Recipe>> recipesForIngredient(String ingredientId) async {
    final ids = await _pantryService.recipeIdsUsingIngredient(ingredientId);
    final recipes = <Recipe>[];
    for (final id in ids) {
      final r = await _recipeService.getById(id);
      if (r != null) recipes.add(r);
    }
    return recipes;
  }

  Future<void> _persistPlan() async {
    final plan = mealPlan;
    if (plan == null) return;
    await _settings.saveJson('meal_plan', plan.toJson());
  }

  Future<void> generateMealPlan(MealPlanRequest request) async {
    plannerLoading = true;
    plannerError = null;
    notifyListeners();
    try {
      final cookableIds = cookableIngredients.map((i) => i.id).toSet();
      final pantry = request.pantry
          .where((i) => cookableIds.contains(i.id))
          .toList();
      final generated = await _api.generateMealPlan(
        MealPlanRequest(
          durationDays: request.durationDays,
          meals: request.meals,
          people: request.people,
          goals: request.goals,
          spiceTolerance: request.spiceTolerance,
          favouriteCuisines: request.favouriteCuisines,
          avoidIngredients: request.avoidIngredients,
          maxCookMinutes: request.maxCookMinutes,
          weeklyBudgetGbp: request.weeklyBudgetGbp,
          pantryMode: request.pantryMode,
          pantry: pantry,
          focusIngredients: request.focusIngredients
              .where(
                (name) => pantry.any((i) => pantryNamesMatch(i.name, name)),
              )
              .toList(),
          preferences: request.preferences,
        ),
      );
      mealPlan = MealPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        days: generated.days,
        shoppingList: generated.shoppingList,
        pantryUsage: generated.pantryUsage,
        allergyWarning: generated.allergyWarning,
      );
      await _persistPlan();
      plannerLoading = false;
      notifyListeners();
      // Fill any missing photos in the background so the plan appears quickly.
      unawaited(_hydratePlanImages());
    } catch (e) {
      plannerError = e.toString().replaceFirst('Exception: ', '');
      plannerLoading = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateDeckImages() async {
    final snapshot = [...deck];
    for (final recipe in snapshot) {
      if ((recipe.assetImage ?? '').isNotEmpty) continue;
      final query = recipe.title;
      final url = await _api.refreshRecipeImage(
        query,
        mealType: selectedCourse,
      );
      if (url.isEmpty || url == recipe.imageUrl) continue;
      deck = [
        for (final r in deck)
          if (r.id == recipe.id) r.copyWith(imageUrl: url) else r,
      ];
      notifyListeners();
    }
  }

  Future<void> _hydratePlanImages() async {
    final plan = mealPlan;
    if (plan == null) return;
    final missing = <PlannedMeal>[
      for (final day in plan.days)
        for (final meal in day.meals) meal,
    ];
    if (missing.isEmpty) return;

    final claimed = <String>{};
    var changed = false;
    for (final meal in missing) {
      final current = meal.recipe.imageUrl;
      if (current.startsWith('http') && claimed.add(current)) continue;
      final primary = await _api.refreshRecipeImage(
        meal.recipe.title,
        mealType: meal.slot,
        exclude: claimed.toList(),
      );
      var url = primary;
      if (url.isEmpty || claimed.contains(url)) {
        final words = meal.recipe.title
            .split(RegExp(r'\s+'))
            .where((w) => w.length > 2)
            .take(3)
            .join(' ');
        url = await _api.refreshRecipeImage(
          words.isEmpty ? meal.slot : '$words plated ${meal.slot}',
          mealType: meal.slot,
          exclude: [...claimed, if (url.isNotEmpty) url],
        );
      }
      if (url.isEmpty || claimed.contains(url)) continue;
      claimed.add(url);
      mealPlan = mealPlan?.replacingMeal(
        meal.date,
        meal.slot,
        meal.recipe.copyWith(imageUrl: url),
      );
      changed = true;
      notifyListeners();
    }
    if (changed) await _persistPlan();
  }

  Future<void> swapPlannedMeal({
    required String date,
    required String slot,
    List<PantryIngredient>? pantry,
  }) async {
    plannerLoading = true;
    notifyListeners();
    try {
      final recipes = await _api.generateRecipes(
        pantry: pantry ?? availableIngredients,
        mealType: slot,
        preferences: preferences,
        recipeCount: 1,
        focusIngredients: mealPlan == null
            ? const []
            : [for (final d in mealPlan!.days)
                if (d.date == date)
                  for (final m in d.meals)
                    if (m.slot == slot) m.recipe.title],
      );
      if (recipes.isEmpty) throw StateError('Could not swap this meal.');
      mealPlan = mealPlan
          ?.replacingMeal(date, slot, recipes.first)
          .markingCompleted(date, slot, completed: false);
      _reallocate();
      await _persistPlan();
    } catch (e) {
      plannerError = e.toString().replaceFirst('Exception: ', '');
    }
    plannerLoading = false;
    notifyListeners();
  }

  Future<void> replacePlannedMealWithSaved({
    required String date,
    required String slot,
    required Recipe recipe,
  }) async {
    mealPlan = mealPlan
        ?.replacingMeal(date, slot, recipe)
        .markingCompleted(date, slot, completed: false);
    _reallocate();
    await _persistPlan();
    notifyListeners();
  }

  Future<void> placeOnPlan({
    required String date,
    required String slot,
    required Recipe recipe,
  }) async {
    if (mealPlan == null) return;
    mealPlan = mealPlan!
        .replacingMeal(date, slot, recipe)
        .markingCompleted(date, slot, completed: false);
    _reallocate();
    await _persistPlan();
    notifyListeners();
  }

  Future<void> toggleShoppingItem(String name) async {
    final plan = mealPlan;
    if (plan == null) return;
    mealPlan = MealPlan(
      id: plan.id,
      days: plan.days,
      shoppingList: [
        for (final item in plan.shoppingList)
          if (pantryNamesMatch(item.name, name))
            item.copyWith(checked: !item.checked)
          else
            item,
      ],
      pantryUsage: plan.pantryUsage,
      allergyWarning: plan.allergyWarning,
    );
    await _persistPlan();
    notifyListeners();
  }

  void _reallocate() {
    final plan = mealPlan;
    if (plan == null) return;
    mealPlan = reallocatePlan(plan, cookableIngredients);
  }

  Future<void> removePlannedMeal({
    required String date,
    required String slot,
  }) async {
    if (mealPlan == null) return;
    mealPlan = MealPlan(
      id: mealPlan!.id,
      days: mealPlan!.days
          .map(
            (d) => d.date != date
                ? d
                : PlanDay(
                    date: d.date,
                    meals: d.meals.where((m) => m.slot != slot).toList(),
                  ),
          )
          .toList(),
      shoppingList: mealPlan!.shoppingList,
      pantryUsage: mealPlan!.pantryUsage,
      allergyWarning: mealPlan!.allergyWarning,
    );
    _reallocate();
    await _persistPlan();
    notifyListeners();
  }

  Future<void> refreshPlannedImage({
    required String date,
    required String slot,
  }) async {
    final plan = mealPlan;
    if (plan == null) return;
    PlannedMeal? meal;
    for (final d in plan.days) {
      if (d.date != date) continue;
      for (final m in d.meals) {
        if (m.slot == slot) meal = m;
      }
    }
    if (meal == null) return;
    final url = await _api.refreshRecipeImage(
      '${meal.recipe.title} ${meal.slot} plated food photography',
    );
    if (url.isEmpty) return;
    mealPlan = plan.replacingMeal(
      date,
      slot,
      meal.recipe.copyWith(imageUrl: url),
    );
    await _persistPlan();
    notifyListeners();
  }
}

class _SwipeAction {
  _SwipeAction({required this.recipe, required this.liked});
  final Recipe recipe;
  final bool liked;
}
