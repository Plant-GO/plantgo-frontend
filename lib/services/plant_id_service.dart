import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/env/env_config.dart';

/// PlantID API service for plant identification
/// API Documentation: https://web.plant.id/plant-identification-api/
class PlantIdService {
  static const String _baseUrl = AppConstants.plantIdBaseUrl;

  /// Identify a plant from image data
  /// [imageBase64] - Base64 encoded image string
  /// Returns plant identification results
  Future<PlantIdResult> identifyPlant(String imageBase64) async {
    final apiKey = EnvConfig.plantIdApiKey;

    if (!EnvConfig.hasPlantIdKey) {
      // Return mock result if API key not configured
      return PlantIdResult.mock();
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConstants.plantIdIdentifyEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Api-Key': apiKey},
        body: jsonEncode({
          'images': [imageBase64],
          'similar_images': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PlantIdResult.fromJson(data);
      } else {
        throw PlantIdException('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is PlantIdException) rethrow;
      throw PlantIdException('Network error: $e');
    }
  }

  /// Verify if scanned plant matches expected plant
  Future<VerificationResult> verifyPlant({
    required String imageBase64,
    required String expectedPlantId,
  }) async {
    final result = await identifyPlant(imageBase64);

    if (result.suggestions.isEmpty) {
      return VerificationResult(
        isMatch: false,
        confidence: 0,
        identifiedPlant: null,
        message: 'Could not identify plant',
      );
    }

    final topSuggestion = result.suggestions.first;

    // Simple matching logic - can be enhanced
    final isMatch =
        topSuggestion.plantName.toLowerCase().contains(
          expectedPlantId.toLowerCase(),
        ) ||
        topSuggestion.probability > 0.8;

    return VerificationResult(
      isMatch: isMatch,
      confidence: topSuggestion.probability,
      identifiedPlant: topSuggestion.plantName,
      message: isMatch
          ? 'Plant verified!'
          : 'Not the plant you\'re looking for',
    );
  }
}

/// Result from PlantID API
class PlantIdResult {
  final List<PlantSuggestion> suggestions;
  final bool isPlant;

  PlantIdResult({required this.suggestions, required this.isPlant});

  factory PlantIdResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? json;
    final classification = result['classification'] ?? {};
    final suggestions =
        (classification['suggestions'] as List<dynamic>?)
            ?.map((s) => PlantSuggestion.fromJson(s))
            .toList() ??
        [];

    return PlantIdResult(
      suggestions: suggestions,
      isPlant: result['is_plant']?['binary'] ?? false,
    );
  }

  /// Mock result for testing without API key
  factory PlantIdResult.mock() {
    return PlantIdResult(
      suggestions: [
        PlantSuggestion(
          plantName: 'Monstera Deliciosa',
          probability: 0.95,
          commonNames: ['Swiss Cheese Plant', 'Split-leaf Philodendron'],
        ),
      ],
      isPlant: true,
    );
  }
}

/// A plant suggestion from identification
class PlantSuggestion {
  final String plantName;
  final double probability;
  final List<String> commonNames;

  PlantSuggestion({
    required this.plantName,
    required this.probability,
    this.commonNames = const [],
  });

  factory PlantSuggestion.fromJson(Map<String, dynamic> json) {
    return PlantSuggestion(
      plantName: json['name'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      commonNames: List<String>.from(json['common_names'] ?? []),
    );
  }
}

/// Result of plant verification
class VerificationResult {
  final bool isMatch;
  final double confidence;
  final String? identifiedPlant;
  final String message;

  VerificationResult({
    required this.isMatch,
    required this.confidence,
    this.identifiedPlant,
    required this.message,
  });
}

/// Exception for PlantID API errors
class PlantIdException implements Exception {
  final String message;
  PlantIdException(this.message);

  @override
  String toString() => 'PlantIdException: $message';
}
