import 'package:cloud_firestore/cloud_firestore.dart';

/// PlantCounter tracks the discovery count for each plant species
/// Used to determine NFT rarity based on discovery order
class PlantCounter {
  final String plantName;
  final String normalizedName;
  final int totalMinted;
  final int seedCount; // AuroraSeed (new species) - max 1
  final int relicCount; // PrimordialRelic (first discovery) - max 1
  final int epicCount; // MythicCrest - max 20
  final int rareCount; // AstralShard - max 30 (21-50)
  final int commonCount; // GenesisFragment - unlimited (51+)
  final String? firstDiscoveredBy;
  final DateTime? firstDiscoveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Rarity limits
  static const int maxSeed = 1;
  static const int maxRelic = 1;
  static const int maxEpic = 20;
  static const int maxRare = 30;

  PlantCounter({
    required this.plantName,
    String? normalizedName,
    this.totalMinted = 0,
    this.seedCount = 0,
    this.relicCount = 0,
    this.epicCount = 0,
    this.rareCount = 0,
    this.commonCount = 0,
    this.firstDiscoveredBy,
    this.firstDiscoveredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : normalizedName = normalizedName ?? _normalize(plantName),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Normalize plant name for consistent lookups
  static String _normalize(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Whether this is a brand new species (never discovered)
  bool get isNewSpecies => totalMinted == 0 && seedCount == 0;

  /// Whether this is the first mint for this plant
  bool get isFirstMint => totalMinted == 0;

  /// Whether AuroraSeed is available (new species, first discoverer)
  bool get hasSeedAvailable => seedCount < maxSeed;

  /// Whether PrimordialRelic is available (first discovery of known plant)
  bool get hasRelicAvailable => relicCount < maxRelic && seedCount > 0;

  /// Whether MythicCrest (Epic) is still available
  bool get hasEpicAvailable => epicCount < maxEpic;

  /// Whether AstralShard (Rare) is still available
  bool get hasRareAvailable => rareCount < maxRare;

  /// Get the next available rarity for this plant
  NFTRarity getNextAvailableRarity({bool isNewSpeciesDiscovery = false}) {
    if (isNewSpeciesDiscovery && hasSeedAvailable) {
      return NFTRarity.auroraSeed;
    }
    if (isFirstMint && !isNewSpeciesDiscovery) {
      return NFTRarity.primordialRelic;
    }
    if (hasEpicAvailable) {
      return NFTRarity.mythicCrest;
    }
    if (hasRareAvailable) {
      return NFTRarity.astralShard;
    }
    return NFTRarity.genesisFragment;
  }

  /// Create updated counter after minting
  PlantCounter incrementForRarity(NFTRarity rarity, {String? discoveredBy}) {
    return PlantCounter(
      plantName: plantName,
      normalizedName: normalizedName,
      totalMinted: totalMinted + 1,
      seedCount: rarity == NFTRarity.auroraSeed ? seedCount + 1 : seedCount,
      relicCount: rarity == NFTRarity.primordialRelic
          ? relicCount + 1
          : relicCount,
      epicCount: rarity == NFTRarity.mythicCrest ? epicCount + 1 : epicCount,
      rareCount: rarity == NFTRarity.astralShard ? rareCount + 1 : rareCount,
      commonCount: rarity == NFTRarity.genesisFragment
          ? commonCount + 1
          : commonCount,
      firstDiscoveredBy: firstDiscoveredBy ?? discoveredBy,
      firstDiscoveredAt: firstDiscoveredAt ?? DateTime.now(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'plantName': plantName,
      'normalizedName': normalizedName,
      'totalMinted': totalMinted,
      'seedCount': seedCount,
      'relicCount': relicCount,
      'epicCount': epicCount,
      'rareCount': rareCount,
      'commonCount': commonCount,
      'firstDiscoveredBy': firstDiscoveredBy,
      'firstDiscoveredAt': firstDiscoveredAt != null
          ? Timestamp.fromDate(firstDiscoveredAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory PlantCounter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantCounter(
      plantName: data['plantName'] ?? doc.id,
      normalizedName: data['normalizedName'] ?? doc.id,
      totalMinted: data['totalMinted'] ?? 0,
      seedCount: data['seedCount'] ?? 0,
      relicCount: data['relicCount'] ?? 0,
      epicCount: data['epicCount'] ?? 0,
      rareCount: data['rareCount'] ?? 0,
      commonCount: data['commonCount'] ?? 0,
      firstDiscoveredBy: data['firstDiscoveredBy'],
      firstDiscoveredAt: (data['firstDiscoveredAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PlantCounter($plantName: total=$totalMinted, seed=$seedCount, relic=$relicCount, epic=$epicCount, rare=$rareCount, common=$commonCount)';
  }
}

/// NFT Rarity levels matching Solana program
enum NFTRarity {
  auroraSeed, // Legendary - New species discovery
  primordialRelic, // Legendary - First discovery of known plant
  mythicCrest, // Epic - First 20 discoveries
  astralShard, // Rare - Discoveries 21-50
  genesisFragment, // Common - Discoveries 51+
}

extension NFTRarityExtension on NFTRarity {
  String get displayName {
    switch (this) {
      case NFTRarity.auroraSeed:
        return 'Aurora Seed';
      case NFTRarity.primordialRelic:
        return 'Primordial Relic';
      case NFTRarity.mythicCrest:
        return 'Mythic Crest';
      case NFTRarity.astralShard:
        return 'Astral Shard';
      case NFTRarity.genesisFragment:
        return 'Genesis Fragment';
    }
  }

  String get tier {
    switch (this) {
      case NFTRarity.auroraSeed:
      case NFTRarity.primordialRelic:
        return 'Legendary';
      case NFTRarity.mythicCrest:
        return 'Epic';
      case NFTRarity.astralShard:
        return 'Rare';
      case NFTRarity.genesisFragment:
        return 'Common';
    }
  }

  String get emoji {
    switch (this) {
      case NFTRarity.auroraSeed:
        return '🌟';
      case NFTRarity.primordialRelic:
        return '🏺';
      case NFTRarity.mythicCrest:
        return '💜';
      case NFTRarity.astralShard:
        return '💙';
      case NFTRarity.genesisFragment:
        return '⬜';
    }
  }

  int get colorValue {
    switch (this) {
      case NFTRarity.auroraSeed:
        return 0xFFFFD700; // Gold
      case NFTRarity.primordialRelic:
        return 0xFFFF6B35; // Orange-red
      case NFTRarity.mythicCrest:
        return 0xFF9C27B0; // Purple
      case NFTRarity.astralShard:
        return 0xFF2196F3; // Blue
      case NFTRarity.genesisFragment:
        return 0xFF9E9E9E; // Gray
    }
  }

  /// Hex color string (for Firestore storage)
  String get colorHex {
    switch (this) {
      case NFTRarity.auroraSeed:
        return '#FFD700';
      case NFTRarity.primordialRelic:
        return '#FF6B35';
      case NFTRarity.mythicCrest:
        return '#9C27B0';
      case NFTRarity.astralShard:
        return '#2196F3';
      case NFTRarity.genesisFragment:
        return '#9E9E9E';
    }
  }

  /// Points/XP value for this rarity
  int get pointsValue {
    switch (this) {
      case NFTRarity.auroraSeed:
        return 1000;
      case NFTRarity.primordialRelic:
        return 500;
      case NFTRarity.mythicCrest:
        return 100;
      case NFTRarity.astralShard:
        return 50;
      case NFTRarity.genesisFragment:
        return 10;
    }
  }
}
