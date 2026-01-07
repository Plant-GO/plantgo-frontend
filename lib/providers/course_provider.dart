import 'package:flutter/foundation.dart';
import '../models/level.dart';
import '../models/plant.dart';

/// Provider for course/level progression
class CourseProvider extends ChangeNotifier {
  List<Level> _levels = SampleLevels.levels;
  Level? _selectedLevel;
  bool _isLoading = false;

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
    if (index == -1) return;

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
    }

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

  /// Reset to sample data (for testing)
  void reset() {
    _levels = SampleLevels.levels;
    _selectedLevel = null;
    notifyListeners();
  }
}
