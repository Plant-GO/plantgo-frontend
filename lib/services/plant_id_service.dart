import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/env/env_config.dart';
import 'backend_config_service.dart';

/// PlantID API service for plant identification
/// API Documentation: https://web.plant.id/plant-identification-api/
class PlantIdService {
  static const String _baseUrl = AppConstants.plantIdBaseUrl;

  /// Get custom model URL dynamically from backend config (same IP, port 8000)
  static Future<String> _getCustomModelUrl() async {
    final nftBackendUrl = await BackendConfigService.getBackendUrl();
    // Replace port 3001 with 8000 for custom model backend
    return nftBackendUrl.replaceAll(':3001', ':8000');
  }

  /// Identify a plant from image data using Plant.id API
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

  /// Identify a plant using custom VGG16 model backend
  /// [imageBase64] - Base64 encoded image string
  /// Returns plant identification results with cached metadata
  Future<PlantIdResult> identifyFromCustomModel(String imageBase64) async {
    try {
      final customModelUrl = await _getCustomModelUrl();
      final response = await http.post(
        Uri.parse('$customModelUrl${AppConstants.customModelEndpoint}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'image_base64': imageBase64},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlantIdResult.fromJson(data);
      } else {
        debugPrint(
          'Custom Model API Error ${response.statusCode}: ${response.body}',
        );
        throw PlantIdException(
          'Custom model error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is PlantIdException) rethrow;
      throw PlantIdException('Custom model network error: $e');
    }
  }

  /// Identify plant using both Plant.id API and custom model in parallel
  /// Always returns Plant.id result, but includes custom model match info
  /// [imageBase64] - Base64 encoded image string
  /// Returns: (PlantIdResult, bool customModelMatched, bool customModelIdentified)
  Future<ParallelIdentificationResult> identifyParallel(String imageBase64) async {
    try {
      // Run both identification methods in parallel
      final results = await Future.wait([
        identifyPlant(imageBase64).catchError((e) {
          debugPrint('Plant.id API failed: $e');
          return PlantIdResult(suggestions: [], isPlant: false);
        }),
        _identifyFromCustomModelRaw(imageBase64).catchError((e) {
          debugPrint('Custom model failed: $e');
          return <String, dynamic>{};
        }),
      ]);

      final plantIdResult = results[0] as PlantIdResult;
      final customModelData = results[1] as Map<String, dynamic>;

      // Check if custom model identified the plant
      final customModelStatus = customModelData['status'] as String? ?? 'unidentified';
      final customModelIdentified = customModelStatus == 'identified';
      
      // Get custom model prediction name
      String? customModelPlant;
      if (customModelIdentified) {
        final customResult = customModelData['result'] as Map<String, dynamic>?;
        final suggestions = (customResult?['classification']?['suggestions'] as List?)?.cast<Map<String, dynamic>>();
        if (suggestions != null && suggestions.isNotEmpty) {
          customModelPlant = suggestions.first['name'] as String?;
        }
      }

      // Get Plant.id prediction name
      String? plantIdPlant;
      if (plantIdResult.suggestions.isNotEmpty) {
        plantIdPlant = plantIdResult.suggestions.first.plantName;
      }

      // Check if both match (case-insensitive comparison)
      final customModelMatched = customModelIdentified &&
          customModelPlant != null &&
          plantIdPlant != null &&
          (customModelPlant.toLowerCase() == plantIdPlant.toLowerCase() ||
           _namesMatch(customModelPlant, plantIdPlant));

      debugPrint(
        'Parallel: Plant.id=$plantIdPlant, Custom=$customModelPlant, Matched=$customModelMatched, Identified=$customModelIdentified',
      );

      return ParallelIdentificationResult(
        result: plantIdResult,
        customModelMatched: customModelMatched,
        customModelIdentified: customModelIdentified,
      );
    } catch (e) {
      throw PlantIdException('Parallel identification error: $e');
    }
  }

  /// Check if plant names match (handles scientific vs common names)
  bool _namesMatch(String name1, String name2) {
    final n1 = name1.toLowerCase().replaceAll(' ', '');
    final n2 = name2.toLowerCase().replaceAll(' ', '');
    return n1.contains(n2) || n2.contains(n1);
  }

  /// Raw custom model call that returns the full response map
  Future<Map<String, dynamic>> _identifyFromCustomModelRaw(String imageBase64) async {
    try {
      final customModelUrl = await _getCustomModelUrl();
      final response = await http.post(
        Uri.parse('$customModelUrl${AppConstants.customModelEndpoint}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'image_base64': imageBase64},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Custom model raw error: $e');
      return {};
    }
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

/// Result of parallel identification (Plant.id + custom model)
class ParallelIdentificationResult {
  final PlantIdResult result;
  final bool customModelMatched;
  final bool customModelIdentified;

  ParallelIdentificationResult({
    required this.result,
    required this.customModelMatched,
    required this.customModelIdentified,
  });
}
