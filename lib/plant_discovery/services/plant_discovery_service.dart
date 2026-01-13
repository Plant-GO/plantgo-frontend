import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/plant_counter.dart';

/// Service for managing plant discovery counters and NFT rarity determination
class PlantDiscoveryService {
  static final PlantDiscoveryService _instance = PlantDiscoveryService._internal();
  factory PlantDiscoveryService() => _instance;
  PlantDiscoveryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _plantCountersCollection = 'plant_counters';

  /// Normalize plant name for consistent lookups
  String normalizePlantName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get PlantCounter for a specific plant
  Future<PlantCounter?> getPlantCounter(String plantName) async {
    try {
      final normalized = normalizePlantName(plantName);
      final doc = await _firestore
          .collection(_plantCountersCollection)
          .doc(normalized)
          .get();

      if (doc.exists) {
        return PlantCounter.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting plant counter: $e');
      return null;
    }
  }

  /// Check if a plant species has ever been discovered
  Future<bool> isNewSpecies(String plantName) async {
    final counter = await getPlantCounter(plantName);
    final isNew = counter == null || counter.totalMinted == 0;
    debugPrint('🌱 isNewSpecies("$plantName"): $isNew');
    return isNew;
  }

  /// Determine NFT rarity for a plant discovery
  /// 
  /// Logic:
  /// - isNewSpeciesDiscovery = true → AuroraSeed (Legendary) - First time this species is ever seen
  /// - First discovery of known plant → PrimordialRelic (Legendary)
  /// - Discoveries 1-20 → MythicCrest (Epic)
  /// - Discoveries 21-50 → AstralShard (Rare)
  /// - Discoveries 51+ → GenesisFragment (Common)
  Future<NFTRarity> determineRarity({
    required String plantName,
    required bool isNewSpeciesDiscovery,
  }) async {
    final counter = await getPlantCounter(plantName);
    
    if (counter == null) {
      // Brand new plant - create counter and return highest rarity
      if (isNewSpeciesDiscovery) {
        debugPrint('🌟 New species "$plantName" → Aurora Seed');
        return NFTRarity.auroraSeed;
      } else {
        debugPrint('🏺 First discovery of "$plantName" → Primordial Relic');
        return NFTRarity.primordialRelic;
      }
    }

    // Use counter to determine next available rarity
    final rarity = counter.getNextAvailableRarity(
      isNewSpeciesDiscovery: isNewSpeciesDiscovery,
    );
    
    debugPrint('${rarity.emoji} "$plantName" (count: ${counter.totalMinted}) → ${rarity.displayName}');
    return rarity;
  }

  /// Record a mint and update the plant counter
  /// Returns the updated PlantCounter
  Future<PlantCounter> recordMint({
    required String plantName,
    required NFTRarity rarity,
    required String discoveredBy,
  }) async {
    final normalized = normalizePlantName(plantName);
    final docRef = _firestore.collection(_plantCountersCollection).doc(normalized);

    return await _firestore.runTransaction<PlantCounter>((transaction) async {
      final snapshot = await transaction.get(docRef);

      PlantCounter counter;
      if (snapshot.exists) {
        counter = PlantCounter.fromFirestore(snapshot);
      } else {
        counter = PlantCounter(plantName: plantName);
      }

      // Increment counter for the given rarity
      final updatedCounter = counter.incrementForRarity(rarity, discoveredBy: discoveredBy);
      
      transaction.set(docRef, updatedCounter.toFirestore());
      
      debugPrint('✅ Recorded mint: ${updatedCounter.toString()}');
      return updatedCounter;
    });
  }

  /// Get discovery statistics for a plant
  Future<Map<String, dynamic>> getPlantStats(String plantName) async {
    final counter = await getPlantCounter(plantName);
    
    if (counter == null) {
      return {
        'isDiscovered': false,
        'totalMinted': 0,
        'nextRarity': NFTRarity.auroraSeed.displayName,
        'availableEpic': PlantCounter.maxEpic,
        'availableRare': PlantCounter.maxRare,
      };
    }

    return {
      'isDiscovered': true,
      'totalMinted': counter.totalMinted,
      'nextRarity': counter.getNextAvailableRarity().displayName,
      'firstDiscoveredBy': counter.firstDiscoveredBy,
      'firstDiscoveredAt': counter.firstDiscoveredAt,
      'availableEpic': PlantCounter.maxEpic - counter.epicCount,
      'availableRare': PlantCounter.maxRare - counter.rareCount,
      'seedMinted': counter.seedCount > 0,
      'relicMinted': counter.relicCount > 0,
    };
  }

  /// Get leaderboard of most discovered plants
  Future<List<PlantCounter>> getTopDiscoveredPlants({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_plantCountersCollection)
          .orderBy('totalMinted', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PlantCounter.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting top plants: $e');
      return [];
    }
  }

  /// Get all unique plant species discovered
  Future<int> getTotalUniqueSpecies() async {
    try {
      final snapshot = await _firestore
          .collection(_plantCountersCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error counting species: $e');
      return 0;
    }
  }
}
