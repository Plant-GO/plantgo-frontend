import 'plant.dart';

/// User progress and collection data
class UserProgress {
  final String userId;
  final int coins;
  final int leaves;
  final List<String> completedLevelIds;
  final List<CollectedPlant> collection;
  final int totalXp;

  const UserProgress({
    required this.userId,
    this.coins = 0,
    this.leaves = 0,
    this.completedLevelIds = const [],
    this.collection = const [],
    this.totalXp = 0,
  });

  UserProgress copyWith({
    String? userId,
    int? coins,
    int? leaves,
    List<String>? completedLevelIds,
    List<CollectedPlant>? collection,
    int? totalXp,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      leaves: leaves ?? this.leaves,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      collection: collection ?? this.collection,
      totalXp: totalXp ?? this.totalXp,
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      coins: json['coins'] ?? 0,
      leaves: json['leaves'] ?? 0,
      completedLevelIds: List<String>.from(json['completedLevelIds'] ?? []),
      collection:
          (json['collection'] as List<dynamic>?)
              ?.map((e) => CollectedPlant.fromJson(e))
              .toList() ??
          [],
      totalXp: json['totalXp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'coins': coins,
    'leaves': leaves,
    'completedLevelIds': completedLevelIds,
    'collection': collection.map((e) => e.toJson()).toList(),
    'totalXp': totalXp,
  };

  /// Check if a level is completed
  bool isLevelCompleted(int levelId) =>
      completedLevelIds.contains(levelId.toString());

  /// Get collected plant count by rarity
  int getCountByRarity(PlantRarity rarity) =>
      collection.where((p) => p.rarity == rarity).length;
}

/// A plant that has been collected by the user
class CollectedPlant {
  final String plantId;
  final String name;
  final PlantRarity rarity;
  final DateTime discoveredAt;
  final double latitude;
  final double longitude;
  final bool isFirstFind;

  const CollectedPlant({
    required this.plantId,
    required this.name,
    required this.rarity,
    required this.discoveredAt,
    required this.latitude,
    required this.longitude,
    this.isFirstFind = false,
  });

  factory CollectedPlant.fromJson(Map<String, dynamic> json) {
    return CollectedPlant(
      plantId: json['plantId'] ?? '',
      name: json['name'] ?? '',
      rarity: PlantRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => PlantRarity.common,
      ),
      discoveredAt: DateTime.parse(
        json['discoveredAt'] ?? DateTime.now().toIso8601String(),
      ),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      isFirstFind: json['isFirstFind'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'plantId': plantId,
    'name': name,
    'rarity': rarity.name,
    'discoveredAt': discoveredAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'isFirstFind': isFirstFind,
  };
}

/// Sample user for demo
class SampleUser {
  static UserProgress defaultProgress = UserProgress(
    userId: 'demo_user',
    coins: 0,
    leaves: 0,
    completedLevelIds: [],
    collection: [],
    totalXp: 0,
  );
}
