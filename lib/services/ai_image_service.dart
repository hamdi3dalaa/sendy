// lib/services/ai_image_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AiImageService {
  static final AiImageService _instance = AiImageService._internal();
  factory AiImageService() => _instance;
  AiImageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _apiKey;

  /// Load OpenAI API key from Firestore config
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

  /// Analyze a dish photo with GPT-4 Vision and get improvement tips
  /// Returns suggestions in the user's language
  Future<String?> analyzeDishPhoto(File imageFile, String dishName, {String language = 'fr'}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final langPrompt = language == 'ar'
          ? 'أجب باللغة العربية.'
          : 'Réponds en français.';

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
                  'Tu es un expert en photographie culinaire pour restaurants. '
                  'Analyse la photo du plat et donne des conseils courts et pratiques '
                  'pour améliorer la présentation et la qualité de la photo. '
                  'Sois concis (max 4 points). $langPrompt',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyse cette photo du plat "$dishName" et donne des conseils pour l\'améliorer.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'low',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        print('OpenAI Vision error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error analyzing image: $e');
      return null;
    }
  }

  /// Analyze a restaurant logo with GPT-4 Vision
  Future<String?> analyzeLogoPhoto(File imageFile, String restaurantName, {String language = 'fr'}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final langPrompt = language == 'ar'
          ? 'أجب باللغة العربية.'
          : 'Réponds en français.';

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
                  'Tu es un expert en branding de restaurant. '
                  'Analyse le logo/photo de profil du restaurant et donne des conseils '
                  'pour améliorer l\'image de marque. '
                  'Sois concis (max 4 points). $langPrompt',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyse cette photo/logo du restaurant "$restaurantName" et donne des conseils pour l\'améliorer.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'low',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        print('OpenAI Vision error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error analyzing logo: $e');
      return null;
    }
  }

  /// Generate a dish image using DALL-E 3
  /// Returns a File with the generated image
  Future<File?> generateDishImage(String dishName, String description, {String language = 'fr'}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'dall-e-3',
          'prompt':
              'Professional food photography of a Moroccan restaurant dish called "$dishName". '
              'Description: $description. '
              'Style: appetizing, well-lit, warm colors, top-down or 45-degree angle, '
              'clean plate presentation, restaurant quality, soft natural lighting, '
              'shallow depth of field. No text or watermarks.',
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'b64_json',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final b64 = data['data'][0]['b64_json'] as String;
        final bytes = base64Decode(b64);
        return _saveToTempFile(bytes, 'dish_${DateTime.now().millisecondsSinceEpoch}.png');
      } else {
        print('DALL-E error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating dish image: $e');
      return null;
    }
  }

  /// Generate a restaurant logo using DALL-E 3
  Future<File?> generateLogoImage(String restaurantName, String prompt) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'dall-e-3',
          'prompt':
              'Professional restaurant logo for "$restaurantName". '
              '$prompt. '
              'Style: modern, clean, minimalist, suitable for a food delivery app. '
              'Circular or square format, high contrast, no complex text. '
              'Moroccan restaurant branding style.',
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'b64_json',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final b64 = data['data'][0]['b64_json'] as String;
        final bytes = base64Decode(b64);
        return _saveToTempFile(bytes, 'logo_${DateTime.now().millisecondsSinceEpoch}.png');
      } else {
        print('DALL-E error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating logo: $e');
      return null;
    }
  }

  /// Generate dish image from custom prompt
  Future<File?> generateFromPrompt(String prompt) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'dall-e-3',
          'prompt': '$prompt. Professional food photography style, appetizing, well-lit, no text or watermarks.',
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'b64_json',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final b64 = data['data'][0]['b64_json'] as String;
        final bytes = base64Decode(b64);
        return _saveToTempFile(bytes, 'gen_${DateTime.now().millisecondsSinceEpoch}.png');
      } else {
        print('DALL-E error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating image from prompt: $e');
      return null;
    }
  }

  Future<File> _saveToTempFile(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
