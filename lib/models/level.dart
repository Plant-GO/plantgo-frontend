/// Status of a level
enum LevelStatus { locked, active, completed }

/// Level model for course progression
class Level {
  final int id;
  final String name;
  final String subtitle;
  final String riddle;
  final String plantToFindId;
  final LevelStatus status;
  final int stars; // 0-3 stars earned
  final double? targetLatitude;
  final double? targetLongitude;
  final String clueStrength; // "High", "Medium", "Low"
  final int distanceHint; // in meters

  const Level({
    required this.id,
    required this.name,
    this.subtitle = '',
    required this.riddle,
    required this.plantToFindId,
    required this.status,
    this.stars = 0,
    this.targetLatitude,
    this.targetLongitude,
    this.clueStrength = 'High',
    this.distanceHint = 50,
  });

  Level copyWith({
    int? id,
    String? name,
    String? subtitle,
    String? riddle,
    String? plantToFindId,
    LevelStatus? status,
    int? stars,
    double? targetLatitude,
    double? targetLongitude,
    String? clueStrength,
    int? distanceHint,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      riddle: riddle ?? this.riddle,
      plantToFindId: plantToFindId ?? this.plantToFindId,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      targetLatitude: targetLatitude ?? this.targetLatitude,
      targetLongitude: targetLongitude ?? this.targetLongitude,
      clueStrength: clueStrength ?? this.clueStrength,
      distanceHint: distanceHint ?? this.distanceHint,
    );
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      riddle: json['riddle'] ?? '',
      plantToFindId: json['plantToFindId'] ?? '',
      status: LevelStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LevelStatus.locked,
      ),
      stars: json['stars'] ?? 0,
      targetLatitude: json['targetLatitude']?.toDouble(),
      targetLongitude: json['targetLongitude']?.toDouble(),
      clueStrength: json['clueStrength'] ?? 'High',
      distanceHint: json['distanceHint'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'riddle': riddle,
    'plantToFindId': plantToFindId,
    'status': status.name,
    'stars': stars,
    'targetLatitude': targetLatitude,
    'targetLongitude': targetLongitude,
    'clueStrength': clueStrength,
    'distanceHint': distanceHint,
  };

  /// Check if level is playable
  bool get isPlayable =>
      status == LevelStatus.active || status == LevelStatus.completed;
}

/// Sample levels for demo (matching the mockup design)
class SampleLevels {
  static const List<Level> levels = [
    Level(
      id: 1,
      name: 'Level 1',
      subtitle: 'Getting Started',
      riddle: 'Look for the green leaves by the entrance.',
      plantToFindId: 'monstera_deliciosa',
      status: LevelStatus.completed,
      stars: 3,
      targetLatitude: 45.5122,
      targetLongitude: -122.6587,
      clueStrength: 'High',
      distanceHint: 20,
    ),
    Level(
      id: 2,
      name: 'Level 2',
      subtitle: 'First Steps',
      riddle: 'Near the water fountain, a tropical friend awaits.',
      plantToFindId: 'variegated_monstera',
      status: LevelStatus.completed,
      stars: 3,
      targetLatitude: 45.5155,
      targetLongitude: -122.6620,
      clueStrength: 'High',
      distanceHint: 30,
    ),
    Level(
      id: 3,
      name: 'Level 3',
      subtitle: 'Level up yeah fella',
      riddle: 'By the old oak tree, something special grows.',
      plantToFindId: 'pine_tree',
      status: LevelStatus.active,
      stars: 0,
      targetLatitude: 45.5180,
      targetLongitude: -122.6700,
      clueStrength: 'Medium',
      distanceHint: 45,
    ),
    Level(
      id: 4,
      name: 'Level 4',
      subtitle: 'Hidden Treasures',
      riddle: 'Where shadows meet light, look for spotted leaves.',
      plantToFindId: 'monstera_deliciosa',
      status: LevelStatus.locked,
      stars: 0,
      clueStrength: 'Low',
      distanceHint: 60,
    ),
    Level(
      id: 5,
      name: 'Level 5',
      subtitle: 'The Silent Watcher',
      riddle:
          '"I stand tall with needles green, in winter\'s snow I\'m easily seen. Look for me near the old fountain."',
      plantToFindId: 'pine_tree',
      status: LevelStatus.locked,
      stars: 0,
      targetLatitude: 45.5200,
      targetLongitude: -122.6750,
      clueStrength: 'High',
      distanceHint: 50,
    ),
  ];
}
