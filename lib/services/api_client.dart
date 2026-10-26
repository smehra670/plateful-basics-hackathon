import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../data/demo_data.dart';
import '../models/meal_plan.dart';
import '../models/models.dart';
import '../models/user_preferences.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _preferredBaseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _preferredBaseUrl;

  String? _resolvedBaseUrl;
  bool _liveAvailable = false;
  bool _openaiConfigured = false;

  String get baseUrl => _resolvedBaseUrl ?? _preferredBaseUrl;

  bool get isDemoMode => AppConfig.forceDemoMode || !_liveAvailable;

  bool get isServerReachable => _liveAvailable;

  bool get openaiConfigured => _openaiConfigured;

  static const unreachableMessage =
      'Cannot reach Plateful server. On your PC run: .\\start-plateful.ps1 '
      '(starts the API + USB tunnel). Keep the phone plugged in, then tap Retry.';

  static String _readApiError(String body, String fallback) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final error = json['error'] as String?;
        final detail = json['detail'] as String?;
        if (error != null && error.trim().isNotEmpty) return error;
        if (detail != null && detail.trim().isNotEmpty) return detail;
      }
    } catch (_) {}
    final lower = body.toLowerCase();
    if (lower.contains('insufficient_quota') ||
        lower.contains('exceeded your current quota')) {
      return 'OpenAI credits ran out. Add billing credit at platform.openai.com, then try again.';
    }
    return fallback;
  }

  Iterable<String> get _candidates sync* {
    yield _preferredBaseUrl;
    for (final url in AppConfig.apiBaseUrlFallbacks) {
      if (url != _preferredBaseUrl) yield url;
    }
  }

  Future<bool> checkHealth() async {
    if (AppConfig.forceDemoMode) {
      _liveAvailable = false;
      _openaiConfigured = false;
      return false;
    }

    for (final candidate in _candidates) {
      try {
        final res = await _client
            .get(Uri.parse('$candidate/api/health'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _resolvedBaseUrl = candidate;
        _liveAvailable = true;
        _openaiConfigured = json['openaiConfigured'] as bool? ?? false;
        return true;
      } catch (_) {
        // try next candidate
      }
    }

    _liveAvailable = false;
    _openaiConfigured = false;
    return false;
  }

  Future<AnalyseImageResult> analyseImage(
    File imageFile, {
    bool skipHealthCheck = false,
  }) async {
    if (!skipHealthCheck || !_liveAvailable) {
      await checkHealth();
    }
    if (AppConfig.forceDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return DemoData.analyseDemo();
    }
    if (!_liveAvailable) {
      throw StateError(unreachableMessage);
    }
    if (!_openaiConfigured) {
      throw StateError(
        'OpenAI is not configured on the server. Add OPENAI_API_KEY to server/.env',
      );
    }

    final uri = Uri.parse('$baseUrl/api/analyse-image');
    final request = http.MultipartRequest('POST', uri);
    final lower = imageFile.path.toLowerCase();
    final mediaType = lower.endsWith('.png')
        ? MediaType('image', 'png')
        : lower.endsWith('.webp')
            ? MediaType('image', 'webp')
            : MediaType('image', 'jpeg');
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: mediaType,
      ),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 400) {
      throw StateError(_readApiError(body, 'Could not read this photo.'));
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final result = AnalyseImageResult.fromJson(json);
    if (result.ingredients.isEmpty) {
      throw StateError('No ingredients detected in this photo.');
    }
    if (result.isDemo) {
      throw StateError(
        'Server returned demo ingredients. Check OpenAI configuration.',
      );
    }
    return AnalyseImageResult(
      ingredients: result.ingredients,
      questions: result.questions.take(3).toList(),
      isDemo: false,
    );
  }

  Future<List<Recipe>> generateRecipes({
    required List<PantryIngredient> pantry,
    Map<String, String> clarificationAnswers = const {},
    List<String> focusIngredients = const [],
    String? mealType,
    UserPreferences? preferences,
    int? recipeCount,
  }) async {
    await checkHealth();
    if (AppConfig.forceDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return DemoData.recipesForPantry(pantry);
    }
    if (!_liveAvailable) {
      throw StateError(unreachableMessage);
    }
    if (!_openaiConfigured) {
      throw StateError(
        'OpenAI is not configured on the server. Add OPENAI_API_KEY to server/.env',
      );
    }

    final uri = Uri.parse('$baseUrl/api/generate-recipes');
    final payload = {
      'ingredients': pantry
          .where((p) => p.isAvailable)
          .map(
            (p) => {
              'name': p.name,
              'quantity': p.quantityRemaining,
              'unit': p.unit,
              'expiryDate': p.expiryDate?.toIso8601String(),
            },
          )
          .toList(),
      'answers': clarificationAnswers,
      'focusIngredients': focusIngredients,
      if (mealType != null && mealType.isNotEmpty) 'mealType': mealType,
      if (preferences != null) 'preferences': preferences.toRecipePayload(),
      'recipeCount': ?recipeCount,
    };
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 70));
    if (res.statusCode >= 400) {
      throw StateError(_readApiError(res.body, 'Recipe generation failed.'));
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    var recipes = (json['recipes'] as List<dynamic>)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    final keep = recipeCount ?? 5;
    final focused = recipes.where((r) => r.missingCount <= 2).toList();
    if (focused.length >= keep) {
      recipes = focused.take(keep).toList();
    } else {
      recipes = recipes.take(keep).toList();
    }

    if (recipes.isEmpty) {
      throw StateError('No recipes returned for this pantry.');
    }
    if (recipes.any((r) => r.isDemo)) {
      throw StateError('Server returned demo recipes. Check OpenAI configuration.');
    }
    return recipes;
  }

  Future<MealPlan> generateMealPlan(MealPlanRequest request) async {
    await checkHealth();
    if (!_liveAvailable || !_openaiConfigured) {
      throw StateError(
        'Meal planner needs the server. Run .\\start-plateful.ps1 on your PC, '
        'keep USB connected, then tap Retry in the app.',
      );
    }
    final uri = Uri.parse('$baseUrl/api/generate-meal-plan');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 120));
    if (res.statusCode >= 400) {
      throw StateError(_readApiError(res.body, 'Meal plan failed.'));
    }
    return MealPlan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<String> refreshRecipeImage(
    String query, {
    String? mealType,
    List<String> exclude = const [],
  }) async {
    await checkHealth();
    if (!_liveAvailable) return '';
    final uri = Uri.parse('$baseUrl/api/recipe-image').replace(
      queryParameters: {
        'q': query,
        if (mealType != null && mealType.isNotEmpty) 'mealType': mealType,
        if (exclude.isNotEmpty) 'exclude': exclude.join('|'),
      },
    );
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode >= 400) return '';
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['imageUrl'] as String? ?? '';
  }
}
