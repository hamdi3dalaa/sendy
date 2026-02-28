// lib/services/ai_recommendation_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiRecommendation {
  final String dishName;
  final String reason;
  final String? category;

  AiRecommendation({
    required this.dishName,
    required this.reason,
    this.category,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      dishName: json['dish'] ?? '',
      reason: json['reason'] ?? '',
      category: json['category'],
    );
  }
}

class AiRecommendationService {
  static final AiRecommendationService _instance =
      AiRecommendationService._internal();
  factory AiRecommendationService() => _instance;
  AiRecommendationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _apiKey;

  // Cache: avoid calling the API too often
  List<AiRecommendation>? _cachedRecommendations;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 1);

  Future<String?> _getApiKey() async {
    if (_apiKey != null) return _apiKey;
    try {
      final doc =
          await _firestore.collection('app_config').doc('openai_config').get();
      if (doc.exists) {
        _apiKey = doc.data()?['apiKey'] as String?;
      }
    } catch (e) {
      print('Error loading OpenAI config: $e');
    }
    return _apiKey;
  }

  /// Get AI-powered food recommendations based on the user's order history
  Future<List<AiRecommendation>> getRecommendations({
    required String userId,
    required List<Map<String, dynamic>> availableMenuItems,
    String language = 'fr',
  }) async {
    // Return cache if still valid
    if (_cachedRecommendations != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRecommendations!;
    }

    final apiKey = await _getApiKey();
    if (apiKey == null) return [];

    try {
      // 1. Fetch the user's last delivered orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('clientId', isEqualTo: userId)
          .where('status', isEqualTo: 3) // delivered
          .orderBy('createdAt', descending: true)
          .limit(15)
          .get();

      if (ordersSnapshot.docs.isEmpty) return [];

      // 2. Build a summary of past orders
      final orderHistory = <String>[];
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final items = (data['items'] as List? ?? []);
        for (final item in items) {
          final name = item['name'] ?? '';
          final qty = item['quantity'] ?? 1;
          if (name.isNotEmpty) {
            orderHistory.add('$name (x$qty)');
          }
        }
      }

      if (orderHistory.isEmpty) return [];

      // 3. Build available menu items list
      final menuSummary = availableMenuItems.map((item) {
        final name = item['name'] ?? '';
        final category = item['category'] ?? '';
        final price = item['price'] ?? 0;
        return '$name ($category, ${price} DHs)';
      }).take(50).join(', ');

      // 4. Call OpenAI API
      final langPrompt = language == 'ar'
          ? 'أجب باللغة العربية فقط.'
          : 'Reponds en francais uniquement.';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Tu es un assistant de recommandation culinaire pour une app de livraison de repas. '
                  'Analyse l\'historique de commandes du client et suggere 3 plats parmi le menu disponible '
                  'qui correspondent a ses gouts. '
                  'Reponds UNIQUEMENT en JSON valide, sans markdown, sans bloc de code. '
                  'Format: [{"dish": "nom du plat", "reason": "raison courte en 1 phrase", "category": "categorie"}] '
                  '$langPrompt',
            },
            {
              'role': 'user',
              'content':
                  'Historique de commandes du client (les plus recentes en premier):\n'
                  '${orderHistory.join(", ")}\n\n'
                  'Menu disponible actuellement:\n'
                  '$menuSummary\n\n'
                  'Suggere 3 plats du menu disponible qui plairaient a ce client, en expliquant pourquoi.',
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content =
            data['choices'][0]['message']['content'] as String? ?? '';

        // Parse JSON response - handle potential markdown wrapping
        String jsonStr = content.trim();
        if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
          jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
          jsonStr = jsonStr.trim();
        }

        final List<dynamic> recommendations = json.decode(jsonStr);
        _cachedRecommendations = recommendations
            .map((r) => AiRecommendation.fromJson(r as Map<String, dynamic>))
            .toList();
        _cacheTime = DateTime.now();

        // Save to local prefs for offline fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ai_recommendations', jsonStr);
        await prefs.setString(
            'ai_recommendations_time', DateTime.now().toIso8601String());

        return _cachedRecommendations!;
      } else {
        print('OpenAI recommendation error: ${response.statusCode}');
        return _loadCachedRecommendations();
      }
    } catch (e) {
      print('Error getting AI recommendations: $e');
      return _loadCachedRecommendations();
    }
  }

  /// Load previously cached recommendations from SharedPreferences
  Future<List<AiRecommendation>> _loadCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('ai_recommendations');
      if (cached != null) {
        final List<dynamic> data = json.decode(cached);
        return data
            .map((r) => AiRecommendation.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Clear the cache (e.g., after a new order is placed)
  void clearCache() {
    _cachedRecommendations = null;
    _cacheTime = null;
  }
}
