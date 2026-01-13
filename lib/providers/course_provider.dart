import 'package:flutter/foundation.dart';
import '../models/level.dart';
import '../models/plant.dart';
import '../services/user_service.dart';

/// Provider for course/level progression
class CourseProvider extends ChangeNotifier {
  List<Level> _levels = List.from(SampleLevels.levels);
  Level? _selectedLevel;
  bool _isLoading = false;
  final UserService _userService = UserService();

  List<Level> get levels => _levels;
  Level? get selectedLevel => _selectedLevel;
  bool get isLoading => _isLoading;

  /// Get the current active level
  Level? get activeLevel => _levels.firstWhere(
    (l) => l.status == LevelStatus.active,
    orElse: () => _levels.first,
  );

  /// Get completed levels count
  int get completedCount =>
      _levels.where((l) => l.status == LevelStatus.completed).length;

  /// Select a level for detail view
  void selectLevel(Level level) {
    if (level.isPlayable) {
      _selectedLevel = level;
      notifyListeners();
    }
  }

  /// Clear level selection
  void clearSelection() {
    _selectedLevel = null;
    notifyListeners();
  }

  /// Complete a level with stars earned
  void completeLevel(int levelId, int stars) {
    final index = _levels.indexWhere((l) => l.id == levelId);
    if (index == -1) {
      debugPrint('⚠️ CourseProvider: Level $levelId not found');
      return;
    }

    debugPrint(
      '🎯 CourseProvider: Completing level $levelId with $stars stars',
    );

    // Update completed level
    _levels[index] = _levels[index].copyWith(
      status: LevelStatus.completed,
      stars: stars,
    );

    // Unlock next level
    if (index + 1 < _levels.length) {
      _levels[index + 1] = _levels[index + 1].copyWith(
        status: LevelStatus.active,
      );
      debugPrint('🔓 CourseProvider: Unlocked level ${_levels[index + 1].id}');
    }

    debugPrint('✅ CourseProvider: Notifying listeners');
    notifyListeners();
  }

  /// Get plant for a level
  Plant? getPlantForLevel(int levelId) {
    final level = _levels.firstWhere((l) => l.id == levelId);
    return SamplePlants.plants.firstWhere(
      (p) => p.id == level.plantToFindId,
      orElse: () => SamplePlants.plants.first,
    );
  }

  /// Load user progress from Firebase
  Future<void> loadUserProgress(String userId) async {
    debugPrint('🔄 loadUserProgress: Starting for user $userId');
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userService.getUser(userId);
      if (user == null) {
        debugPrint('⚠️ loadUserProgress: User not found in Firebase');
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint(
        '📦 loadUserProgress: User completedLevelIds: ${user.completedLevelIds}',
      );

      // Update level statuses based on completed levels
      for (int i = 0; i < _levels.length; i++) {
        final level = _levels[i];
        final isCompleted = user.completedLevelIds.contains(
          level.id.toString(),
        );

        debugPrint(
          '🔍 Level ${level.id}: isCompleted=$isCompleted (checking "${level.id}" in ${user.completedLevelIds})',
        );

        if (isCompleted) {
          debugPrint('✅ loadUserProgress: Level ${level.id} is completed');
          // Mark level as completed
          _levels[i] = level.copyWith(
            status: LevelStatus.completed,
            stars: 3, // Default to 3 stars for completed levels
          );

          // Unlock next level
          if (i + 1 < _levels.length) {
            _levels[i + 1] = _levels[i + 1].copyWith(
              status: LevelStatus.active,
            );
            debugPrint(
              '🔓 loadUserProgress: Unlocked level ${_levels[i + 1].id}',
            );
          }
        } else if (i == 0 ||
            user.completedLevelIds.contains(_levels[i - 1].id.toString())) {
          // First level or previous level is completed -> make it active
          debugPrint('🟢 loadUserProgress: Level ${level.id} is active');
          _levels[i] = level.copyWith(status: LevelStatus.active);
        } else {
          // Level is locked
          debugPrint('🔒 loadUserProgress: Level ${level.id} is locked');
          _levels[i] = level.copyWith(status: LevelStatus.locked);
        }
      }

      debugPrint(
        '📊 loadUserProgress: Final state: ${_levels.map((l) => "${l.id}:${l.status}").join(", ")}',
      );
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reset to sample data (for testing)
  void reset() {
    _levels = SampleLevels.levels;
    _selectedLevel = null;
    notifyListeners();
  }
}
