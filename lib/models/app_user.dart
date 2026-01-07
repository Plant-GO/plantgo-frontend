import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for PlantGo app
class AppUser {
  final String userId; // Device ID
  final String userName;
  final int coins;
  final int leaves; // Number of plants found
  final List<String> completedLevelIds;
  final List<String> treasureIds; // IDs of treasures found by this user
  final DateTime createdAt;
  final DateTime lastActive;

  AppUser({
    required this.userId,
    required this.userName,
    this.coins = 0,
    this.leaves = 0,
    this.completedLevelIds = const [],
    this.treasureIds = const [],
    DateTime? createdAt,
    DateTime? lastActive,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      userId: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      coins: data['coins'] ?? 0,
      leaves: data['leaves'] ?? 0,
      completedLevelIds: List<String>.from(data['completedLevelIds'] ?? []),
      treasureIds: List<String>.from(data['treasureIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'coins': coins,
      'leaves': leaves,
      'completedLevelIds': completedLevelIds,
      'treasureIds': treasureIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  AppUser copyWith({
    String? userId,
    String? userName,
    int? coins,
    int? leaves,
    List<String>? completedLevelIds,
    List<String>? treasureIds,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      coins: coins ?? this.coins,
      leaves: leaves ?? this.leaves,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      treasureIds: treasureIds ?? this.treasureIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
