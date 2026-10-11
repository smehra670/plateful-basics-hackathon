import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../data/demo_data.dart';
import '../models/models.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String baseUrl;

  bool _liveAvailable = true;
  bool get isDemoMode => AppConfig.forceDemoMode || !_liveAvailable;

  Future<bool> checkHealth() async {
    if (AppConfig.forceDemoMode) {
      _liveAvailable = false;
      return false;
    }
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      _liveAvailable = res.statusCode == 200;
      return _liveAvailable;
    } catch (_) {
      _liveAvailable = false;
      return false;
    }
  }

  Future<AnalyseImageResult> analyseImage(File imageFile) async {
    await checkHealth();
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return DemoData.analyseDemo();
    }

    try {
      final uri = Uri.parse('$baseUrl/api/analyse-image');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        throw HttpException('Analysis failed (${streamed.statusCode}): $body');
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final result = AnalyseImageResult.fromJson(json);
      // Enforce max 3 questions client-side as well.
      return AnalyseImageResult(
        ingredients: result.ingredients,
        questions: result.questions.take(3).toList(),
        isDemo: result.isDemo,
      );
    } catch (_) {
      _liveAvailable = false;
      return DemoData.analyseDemo();
    }
  }

  Future<List<Recipe>> generateRecipes({
    required List<PantryIngredient> pantry,
    Map<String, String> clarificationAnswers = const {},
  }) async {
    await checkHealth();
    if (isDemoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return DemoData.recipesForPantry(pantry);
    }

    try {
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
      };
      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode >= 400) {
        throw HttpException('Recipe generation failed: ${res.body}');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final recipes = (json['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .where((r) => r.missingCount <= 2)
          .take(5)
          .toList();
      if (recipes.length < 5) {
        final demo = DemoData.recipesForPantry(pantry);
        while (recipes.length < 5 && demo.isNotEmpty) {
          recipes.add(demo[recipes.length % demo.length]);
        }
      }
      return recipes;
    } catch (_) {
      _liveAvailable = false;
      return DemoData.recipesForPantry(pantry);
    }
  }
}
