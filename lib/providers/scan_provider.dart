import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant.dart';
import '../services/plant_id_service.dart';

/// State of the scanning process
enum ScanState { idle, capturing, processing, success, failed }

/// Provider for plant scanning and verification
class ScanProvider extends ChangeNotifier {
  final PlantIdService _plantIdService = PlantIdService();
  final ImagePicker _imagePicker = ImagePicker();

  ScanState _state = ScanState.idle;
  String? _capturedImagePath;
  Plant? _identifiedPlant;
  VerificationResult? _verificationResult;
  String? _errorMessage;

  ScanState get state => _state;
  String? get capturedImagePath => _capturedImagePath;
  Plant? get identifiedPlant => _identifiedPlant;
  VerificationResult? get verificationResult => _verificationResult;
  String? get errorMessage => _errorMessage;

  /// Capture image from camera
  Future<void> captureImage() async {
    _state = ScanState.capturing;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _capturedImagePath = image.path;
        _state = ScanState.idle;
      } else {
        _state = ScanState.idle;
      }
    } catch (e) {
      _state = ScanState.failed;
      _errorMessage = 'Failed to capture image: $e';
    }

    notifyListeners();
  }

  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    _state = ScanState.capturing;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _capturedImagePath = image.path;
        _state = ScanState.idle;
      } else {
        _state = ScanState.idle;
      }
    } catch (e) {
      _state = ScanState.failed;
      _errorMessage = 'Failed to pick image: $e';
    }

    notifyListeners();
  }

  /// Process captured image for plant identification
  Future<void> identifyPlant() async {
    if (_capturedImagePath == null) {
      _errorMessage = 'No image captured';
      _state = ScanState.failed;
      notifyListeners();
      return;
    }

    _state = ScanState.processing;
    notifyListeners();

    try {
      // Convert image to base64
      final bytes = await File(_capturedImagePath!).readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _plantIdService.identifyPlant(base64Image);

      if (result.suggestions.isNotEmpty) {
        final topMatch = result.suggestions.first;

        // Create a plant from identification
        _identifiedPlant = Plant(
          id: topMatch.plantName.toLowerCase().replaceAll(' ', '_'),
          name: topMatch.plantName,
          rarity: _estimateRarity(topMatch.probability),
          careInfo: const PlantCareInfo(water: 'Med', light: 'Bright'),
          xpReward: 100,
        );

        _state = ScanState.success;
      } else {
        _state = ScanState.failed;
        _errorMessage = 'Could not identify plant';
      }
    } catch (e) {
      _state = ScanState.failed;
      _errorMessage = 'Identification failed: $e';
    }

    notifyListeners();
  }

  /// Verify if scanned plant matches expected plant (for level completion)
  Future<void> verifyPlant(String expectedPlantId) async {
    if (_capturedImagePath == null) {
      _errorMessage = 'No image captured';
      _state = ScanState.failed;
      notifyListeners();
      return;
    }

    _state = ScanState.processing;
    notifyListeners();

    try {
      final bytes = await File(_capturedImagePath!).readAsBytes();
      final base64Image = base64Encode(bytes);

      _verificationResult = await _plantIdService.verifyPlant(
        imageBase64: base64Image,
        expectedPlantId: expectedPlantId,
        expectedAliases: [expectedPlantId], // Use plantId as alias for now
      );

      _state = _verificationResult!.isMatch
          ? ScanState.success
          : ScanState.failed;

      if (!_verificationResult!.isMatch) {
        _errorMessage = _verificationResult!.message;
      }
    } catch (e) {
      _state = ScanState.failed;
      _errorMessage = 'Verification failed: $e';
    }

    notifyListeners();
  }

  /// Reset scan state
  void reset() {
    _state = ScanState.idle;
    _capturedImagePath = null;
    _identifiedPlant = null;
    _verificationResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  PlantRarity _estimateRarity(double confidence) {
    if (confidence > 0.95) return PlantRarity.legendary;
    if (confidence > 0.85) return PlantRarity.epic;
    if (confidence > 0.70) return PlantRarity.rare;
    if (confidence > 0.50) return PlantRarity.uncommon;
    return PlantRarity.common;
  }
}
