import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../data/demo_data.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/impact_service.dart';
import '../services/pantry_service.dart';
import '../services/recipe_service.dart';

enum ChefPhase { idle, loading, swiping, results }

class AppState extends ChangeNotifier {
  AppState({
    PantryService? pantryService,
    RecipeService? recipeService,
    ImpactService? impactService,
    ApiClient? apiClient,
  })  : _pantryService = pantryService ?? PantryService(),
        _recipeService = recipeService ?? RecipeService(),
        _impactService = impactService ?? ImpactService(),
        _api = apiClient ?? ApiClient();

  final PantryService _pantryService;
  final RecipeService _recipeService;
  final ImpactService _impactService;
  final ApiClient _api;

  bool ready = false;
  bool usingDemoPipeline = false;
  String? error;

  List<PantryIngredient> ingredients = [];
  List<Recipe> savedRecipes = [];
  Set<String> savedIds = {};
  ImpactStats impact = const ImpactStats(
    mealsCooked: 0,
    totalIngredientsUsed: 0,
    estimatedValueUtilisedGbp: 0,
    ingredientsUsedBeforeExpiry: 0,
  );

  // Scan / clarification
  File? pendingImage;
  AnalyseImageResult? lastAnalyse;
  Map<String, String> clarificationAnswers = {};

  // Chef / swipe
  ChefPhase chefPhase = ChefPhase.idle;
  List<Recipe> deck = [];
  List<Recipe> shortlist = [];
  List<_SwipeAction> _swipeHistory = [];
  int swipeIndex = 0;

  int shellTabIndex = 0;

  Future<void> init() async {
    await _api.checkHealth();
    usingDemoPipeline = _api.isDemoMode;
    await refreshAll();

    if (ingredients.isEmpty) {
      // Seed demo pantry so "Cook with my pantry" works out of the box.
      for (final item in DemoData.seedPantryIngredients()) {
        await _pantryService.upsertManual(item);
      }
      await refreshAll();
      usingDemoPipeline = true;
    }
    ready = true;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    ingredients = await _pantryService.getAll();
    savedRecipes = await _recipeService.getSavedRecipes();
    savedIds = await _recipeService.getSavedIds();
    impact = await _impactService.compute();
    notifyListeners();
  }

  List<PantryIngredient> get availableIngredients =>
      ingredients.where((i) => i.isAvailable).toList();

  List<PantryIngredient> get previouslyUsedIngredients =>
      ingredients.where((i) => !i.isAvailable).toList();

  List<PantryIngredient> get useSoonIngredients => availableIngredients
      .where((i) => i.isExpiringSoon(AppConfig.expirySoonDays))
      .toList();

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
    final result = await _api.analyseImage(pendingImage!);
    lastAnalyse = result;
    usingDemoPipeline = result.isDemo || _api.isDemoMode;
    clarificationAnswers = {};
    notifyListeners();
    return result;
  }

  void answerClarification(String questionId, String answer) {
    clarificationAnswers[questionId] = answer;
    notifyListeners();
  }

  Future<void> finalizeScanAndGenerate() async {
    chefPhase = ChefPhase.loading;
    shellTabIndex = 0;
    notifyListeners();

    final detected = lastAnalyse?.ingredients ?? [];
    for (final d in detected) {
      var name = d.name;
      // Apply clarification answers that rename ingredients
      for (final entry in clarificationAnswers.entries) {
        if (entry.value.isNotEmpty &&
            (d.needsClarification ||
                name.toLowerCase().contains('spinach') ||
                name.toLowerCase().contains('kale'))) {
          if (entry.key.contains('green') ||
              entry.value.toLowerCase() == 'spinach' ||
              entry.value.toLowerCase() == 'kale') {
            if (d.needsClarification) name = entry.value;
          }
        }
      }
      await _pantryService.mergeIngredient(
        name: name,
        quantity: d.quantity ?? 1,
        unit: d.unit,
      );
    }

    await refreshAll();
    await generateRecipesFromPantry();
  }

  Future<void> generateRecipesFromPantry() async {
    chefPhase = ChefPhase.loading;
    shortlist = [];
    _swipeHistory = [];
    swipeIndex = 0;
    error = null;
    notifyListeners();

    try {
      final recipes = await _api.generateRecipes(
        pantry: availableIngredients,
        clarificationAnswers: clarificationAnswers,
      );
      usingDemoPipeline = _api.isDemoMode || recipes.any((r) => r.isDemo);
      await _recipeService.upsertMany(recipes);
      deck = recipes;
      chefPhase = recipes.isEmpty ? ChefPhase.idle : ChefPhase.swiping;
    } catch (e) {
      error = e.toString();
      deck = DemoData.recipesForPantry(availableIngredients);
      await _recipeService.upsertMany(deck);
      chefPhase = ChefPhase.swiping;
      usingDemoPipeline = true;
    }
    notifyListeners();
  }

  void likeCurrent() {
    if (chefPhase != ChefPhase.swiping || swipeIndex >= deck.length) return;
    final recipe = deck[swipeIndex];
    shortlist = [...shortlist, recipe];
    _swipeHistory.add(_SwipeAction(recipe: recipe, liked: true));
    _advanceSwipe();
  }

  void rejectCurrent() {
    if (chefPhase != ChefPhase.swiping || swipeIndex >= deck.length) return;
    final recipe = deck[swipeIndex];
    _swipeHistory.add(_SwipeAction(recipe: recipe, liked: false));
    _advanceSwipe();
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
  }

  void removeFromShortlist(String recipeId) {
    shortlist = shortlist.where((r) => r.id != recipeId).toList();
    notifyListeners();
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
  }) async {
    await _pantryService.mergeIngredient(
      name: name,
      quantity: quantity,
      unit: unit,
      expiryDate: expiry,
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

  Future<void> confirmCook({
    required Recipe recipe,
    required List<CookDeduction> deductions,
  }) async {
    await _pantryService.cookRecipe(
      recipe: recipe,
      deductions: deductions,
      servings: recipe.servings,
    );
    await refreshAll();
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
}

class _SwipeAction {
  _SwipeAction({required this.recipe, required this.liked});
  final Recipe recipe;
  final bool liked;
}
