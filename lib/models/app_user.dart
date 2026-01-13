import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for PlantGo app
class AppUser {
  final String userId; // Device ID or Firebase UID
  final String userName;
  final String? email; // Email for registered users, null for guests
  final bool isGuest; // True for device-based login, false for email login
  final int coins;
  final int leaves; // Number of plants found
  final List<String> completedLevelIds;
  final List<String> treasureIds; // IDs of treasures found by this user
  final DateTime createdAt;
  final DateTime lastActive;

  AppUser({
    required this.userId,
    required this.userName,
    this.email,
    this.isGuest = true,
    this.coins = 0,
    this.leaves = 0,
    this.completedLevelIds = const [],
    this.treasureIds = const [],
    DateTime? createdAt,
    DateTime? lastActive,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActive = lastActive ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      userId: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      email: data['email'],
      isGuest: data['isGuest'] ?? true,
      coins: data['coins'] ?? 0,
      leaves: data['leaves'] ?? 0,
      completedLevelIds: List<String>.from(data['completedLevelIds'] ?? []),
      treasureIds: List<String>.from(data['treasureIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive:
          (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'email': email,
      'isGuest': isGuest,
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
    String? email,
    bool? isGuest,
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
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
      coins: coins ?? this.coins,
      leaves: leaves ?? this.leaves,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      treasureIds: treasureIds ?? this.treasureIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
