// Firebase sync service - PLACEHOLDER until Firebase is configured
// Uncomment imports and implementation when Firebase project is set up

// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_marker.dart';
import '../models/user_progress.dart';
import '../models/plant.dart';
import '../core/constants/app_constants.dart';

/// Firebase synchronization service for global map state
/// Currently returns mock data - will sync with Firestore when configured
class FirebaseSyncService {
  // final FirebaseFirestore _firestore;

  FirebaseSyncService();

  // ============ Plant Discoveries ============

  /// Stream of all plant discoveries (currently returns sample data)
  Stream<List<PlantMarker>> get plantDiscoveriesStream {
    // Return empty stream for now - will use Firestore when configured
    return Stream.value(SampleMarkers.markers);
  }

  /// Get all plant discoveries once
  Future<List<PlantMarker>> getPlantDiscoveries() async {
    // Return sample data for now
    return SampleMarkers.markers;
  }

  /// Add a new plant discovery to the global map
  Future<String> addPlantDiscovery(PlantMarker marker) async {
    // TODO: Sync to Firestore when configured
    return marker.id;
  }

  // ============ User Progress ============

  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    // Return sample progress for now
    return SampleUser.defaultProgress;
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    // TODO: Save to Firestore when configured
  }

  /// Add plant to user's collection
  Future<void> addToCollection({
    required String userId,
    required CollectedPlant plant,
  }) async {
    // TODO: Sync to Firestore when configured
  }

  int _getXpForRarity(PlantRarity rarity) {
    switch (rarity) {
      case PlantRarity.common:
        return AppConstants.xpPerCommonPlant;
      case PlantRarity.uncommon:
        return AppConstants.xpPerUncommonPlant;
      case PlantRarity.rare:
        return AppConstants.xpPerRarePlant;
      case PlantRarity.epic:
        return AppConstants.xpPerEpicPlant;
      case PlantRarity.legendary:
        return AppConstants.xpPerLegendaryPlant;
    }
  }

  // ============ Level Completion ============

  /// Mark a level as completed
  Future<void> completeLevel({
    required String userId,
    required int levelId,
    required int stars,
    required int coinsEarned,
  }) async {
    // TODO: Sync to Firestore when configured
  }
}
