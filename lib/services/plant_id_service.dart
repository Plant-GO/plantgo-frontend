import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/env/env_config.dart';

/// PlantID API service for plant identification
/// API Documentation: https://web.plant.id/plant-identification-api/
class PlantIdService {
  static const String _baseUrl = AppConstants.plantIdBaseUrl;

  /// Identify a plant from image data
  /// [imageBase64] - Base64 encoded image string
  /// Returns plant identification results with common names
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
          'images': [imageBase64], // Don't include data URI prefix
          'latitude': null,
          'longitude': null,
          'similar_images': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = PlantIdResult.fromJson(data);

        // If we have an access token, fetch additional details
        final accessToken = data['access_token'];
        if (accessToken != null && result.suggestions.isNotEmpty) {
          return await _fetchPlantDetails(accessToken, result);
        }

        return result;
      } else {
        debugPrint(
          'Plant.ID API Error ${response.statusCode}: ${response.body}',
        );
        throw PlantIdException(
          'API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is PlantIdException) rethrow;
      throw PlantIdException('Network error: $e');
    }
  }

  /// Fetch additional plant details including common names
  Future<PlantIdResult> _fetchPlantDetails(
    String accessToken,
    PlantIdResult initialResult,
  ) async {
    final apiKey = EnvConfig.plantIdApiKey;

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/identification/$accessToken?details=common_names,taxonomy,description',
        ),
        headers: {'Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlantIdResult.fromDetailedJson(data, initialResult);
      }
    } catch (e) {
      // If details fetch fails, return initial result
      debugPrint('Failed to fetch plant details: $e');
    }

    return initialResult;
  }

  /// Verify if scanned plant matches expected plant using common names
  Future<VerificationResult> verifyPlant({
    required String imageBase64,
    required String expectedPlantId,
    required List<String> expectedAliases,
  }) async {
    final result = await identifyPlant(imageBase64);

    if (result.suggestions.isEmpty) {
      return VerificationResult(
        isMatch: false,
        confidence: 0,
        identifiedPlant: null,
        commonNames: [],
        message: 'Could not identify plant',
      );
    }

    final topSuggestion = result.suggestions.first;
    final allNames = [...topSuggestion.commonNames, topSuggestion.plantName];

    // Check if any identified name matches expected aliases
    bool isMatch = false;
    for (final name in allNames) {
      final lowerName = name.toLowerCase();
      for (final alias in expectedAliases) {
        if (lowerName.contains(alias.toLowerCase()) ||
            alias.toLowerCase().contains(lowerName)) {
          isMatch = true;
          break;
        }
      }
      if (isMatch) break;
    }

    return VerificationResult(
      isMatch: isMatch,
      confidence: topSuggestion.probability,
      identifiedPlant: topSuggestion.plantName,
      commonNames: topSuggestion.commonNames,
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
  final String? accessToken;

  PlantIdResult({
    required this.suggestions,
    required this.isPlant,
    this.accessToken,
  });

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
      accessToken: json['access_token'],
    );
  }

  /// Parse detailed response with common names
  factory PlantIdResult.fromDetailedJson(
    Map<String, dynamic> json,
    PlantIdResult initial,
  ) {
    final result = json['result'] ?? json;
    final classification = result['classification'] ?? {};
    final suggestions =
        (classification['suggestions'] as List<dynamic>?)
            ?.map((s) => PlantSuggestion.fromDetailedJson(s))
            .toList() ??
        initial.suggestions;

    return PlantIdResult(
      suggestions: suggestions.isNotEmpty ? suggestions : initial.suggestions,
      isPlant: result['is_plant']?['binary'] ?? initial.isPlant,
      accessToken: json['access_token'],
    );
  }

  /// Mock result for testing without API key
  factory PlantIdResult.mock() {
    return PlantIdResult(
      suggestions: [
        PlantSuggestion(
          plantName: 'Rosa',
          probability: 0.92,
          commonNames: ['Rose', 'Garden Rose', 'Wild Rose'],
          description: 'A woody perennial flowering plant of the genus Rosa.',
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
  final String? description;
  final String? imageUrl;

  PlantSuggestion({
    required this.plantName,
    required this.probability,
    this.commonNames = const [],
    this.description,
    this.imageUrl,
  });

  factory PlantSuggestion.fromJson(Map<String, dynamic> json) {
    // Extract common names from details if available
    final details = json['details'] ?? {};
    final commonNames = details['common_names'] ?? json['common_names'] ?? [];

    return PlantSuggestion(
      plantName: json['name'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      commonNames: List<String>.from(commonNames),
      description: details['description']?['value'],
      imageUrl: details['image']?['value'],
    );
  }

  factory PlantSuggestion.fromDetailedJson(Map<String, dynamic> json) {
    final details = json['details'] ?? {};

    // Get common_names from details object
    List<String> commonNames = [];
    if (details['common_names'] != null) {
      commonNames = List<String>.from(details['common_names']);
    }

    return PlantSuggestion(
      plantName: json['name'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      commonNames: commonNames,
      description: details['description']?['value'],
      imageUrl: details['image']?['value'],
    );
  }

  /// Get display name (prefer common name over scientific name)
  String get displayName {
    if (commonNames.isNotEmpty) {
      return commonNames.first;
    }
    return plantName;
  }
}

/// Result of plant verification
class VerificationResult {
  final bool isMatch;
  final double confidence;
  final String? identifiedPlant;
  final List<String> commonNames;
  final String message;

  VerificationResult({
    required this.isMatch,
    required this.confidence,
    this.identifiedPlant,
    this.commonNames = const [],
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
