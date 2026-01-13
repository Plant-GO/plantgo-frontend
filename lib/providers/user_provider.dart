import 'package:flutter/foundation.dart';
import '../models/user_progress.dart';
import '../models/plant.dart';
import '../services/firebase_sync_service.dart';

/// Provider for user profile and collection
class UserProvider extends ChangeNotifier {
  final FirebaseSyncService? _firebaseService;

  UserProgress _progress = SampleUser.defaultProgress;
  bool _isLoading = false;
  String _userName = '';
  String _deviceId = '';
  String? _email;
  bool _isGuest = true;

  UserProvider({FirebaseSyncService? firebaseService})
    : _firebaseService = firebaseService;

  UserProgress get progress => _progress;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get deviceId => _deviceId;
  String? get email => _email;
  bool get isGuest => _isGuest;

  int get coins => _progress.coins;
  int get leaves => _progress.leaves;
  int get totalXp => _progress.totalXp;
  List<CollectedPlant> get collection => _progress.collection;

  /// Set user name
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  /// Set device ID (or Firebase UID for registered users)
  void setDeviceId(String id) {
    _deviceId = id;
    notifyListeners();
  }

  /// Set email for registered users
  void setEmail(String? email) {
    _email = email;
    notifyListeners();
  }

  /// Set guest status
  void setIsGuest(bool isGuest) {
    _isGuest = isGuest;
    notifyListeners();
  }

  /// Reset user state (call when switching users)
  void reset() {
    _progress = SampleUser.defaultProgress;
    _isLoading = false;
    _userName = '';
    _deviceId = '';
    _email = null;
    _isGuest = true;
    notifyListeners();
  }

  /// Set coins and leaves from Firebase
  void setCoinsAndLeaves(int coins, int leaves) {
    _progress = _progress.copyWith(coins: coins, leaves: leaves);
    notifyListeners();
  }

  /// Initialize user from Firebase
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    if (_firebaseService != null) {
      final savedProgress = await _firebaseService!.getUserProgress(userId);
      if (savedProgress != null) {
        _progress = savedProgress;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add coins
  void addCoins(int amount) {
    _progress = _progress.copyWith(coins: _progress.coins + amount);
    _syncToFirebase();
    notifyListeners();
  }

  /// Add leaves
  void addLeaves(int amount) {
    _progress = _progress.copyWith(leaves: _progress.leaves + amount);
    _syncToFirebase();
    notifyListeners();
  }

  /// Add plant to collection
  Future<void> addToCollection(CollectedPlant plant) async {
    final updatedCollection = [..._progress.collection, plant];

    // Calculate XP based on rarity
    final xpGain = _getXpForRarity(plant.rarity);

    _progress = _progress.copyWith(
      collection: updatedCollection,
      totalXp: _progress.totalXp + xpGain,
      leaves: _progress.leaves + 1,
    );

    if (_firebaseService != null) {
      await _firebaseService!.addToCollection(
        userId: _progress.userId,
        plant: plant,
      );
    }

    notifyListeners();
  }

  /// Complete a level
  Future<void> completeLevel(int levelId, int coinsEarned) async {
    final completedIds = [..._progress.completedLevelIds, levelId.toString()];

    _progress = _progress.copyWith(
      completedLevelIds: completedIds,
      coins: _progress.coins + coinsEarned,
    );

    if (_firebaseService != null) {
      await _firebaseService!.completeLevel(
        userId: _progress.userId,
        levelId: levelId,
        stars: 3,
        coinsEarned: coinsEarned,
      );
    }

    notifyListeners();
  }

  /// Check if plant is in collection
  bool hasPlant(String plantId) {
    return _progress.collection.any((p) => p.plantId == plantId);
  }

  /// Get rarity count
  int getRarityCount(PlantRarity rarity) {
    return _progress.getCountByRarity(rarity);
  }

  int _getXpForRarity(PlantRarity rarity) {
    switch (rarity) {
      case PlantRarity.common:
        return 50;
      case PlantRarity.uncommon:
        return 100;
      case PlantRarity.rare:
        return 150;
      case PlantRarity.epic:
        return 200;
      case PlantRarity.legendary:
        return 250;
    }
  }

  void _syncToFirebase() {
    if (_firebaseService != null) {
      _firebaseService!.saveUserProgress(_progress);
    }
  }
}
