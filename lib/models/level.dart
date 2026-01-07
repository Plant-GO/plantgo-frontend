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

/// Sample levels for demo with 5 common plants
/// Plant names match common_names from Plant.ID API for verification
class SampleLevels {
  static const List<Level> levels = [
    Level(
      id: 1,
      name: 'Level 1',
      subtitle: 'The Queen of Flowers',
      riddle: '🌹 I am the queen of gardens, beloved by all,\n'
          'With petals soft as velvet, standing proud and tall.\n'
          'Red, pink, or white - my colors shine so bright,\n'
          'I\'m gifted on Valentine\'s, a romantic delight.\n'
          'What am I?',
      plantToFindId: 'rose',
      status: LevelStatus.active,
      stars: 0,
      clueStrength: 'High',
      distanceHint: 20,
    ),
    Level(
      id: 2,
      name: 'Level 2',
      subtitle: 'Festival Gold',
      riddle: '🌼 In festivals I shine like the morning sun,\n'
          'Orange and yellow petals, woven into garlands one by one.\n'
          'In temples and weddings, I\'m always found,\n'
          'My fragrance fills the air all around.\n'
          'What flower am I?',
      plantToFindId: 'marigold',
      status: LevelStatus.locked,
      stars: 0,
      clueStrength: 'High',
      distanceHint: 30,
    ),
    Level(
      id: 3,
      name: 'Level 3',
      subtitle: 'Mountain Beauty',
      riddle: '🌺 High in the mountains, I bloom with grace,\n'
          'Nepal\'s national flower, a beloved embrace.\n'
          'Pink and red clusters on woody stems grow,\n'
          'In spring I put on nature\'s greatest show.\n'
          'What am I?',
      plantToFindId: 'rhododendron',
      status: LevelStatus.locked,
      stars: 0,
      clueStrength: 'Medium',
      distanceHint: 45,
    ),
    Level(
      id: 4,
      name: 'Level 4',
      subtitle: 'Tropical Treasure',
      riddle: '🍐 I\'m a tropical fruit with seeds inside,\n'
          'Green skin turning yellow is my ripening guide.\n'
          'Rich in vitamin C, I help you stay strong,\n'
          'My fragrance is sweet, you can\'t go wrong.\n'
          'What fruit tree am I?',
      plantToFindId: 'guava',
      status: LevelStatus.locked,
      stars: 0,
      clueStrength: 'Medium',
      distanceHint: 50,
    ),
    Level(
      id: 5,
      name: 'Level 5',
      subtitle: 'Golden Grains',
      riddle: '🌽 I stand tall in fields, in rows so neat,\n'
          'My golden kernels make a tasty treat.\n'
          'Popcorn and tortillas from me are made,\n'
          'A staple crop, in many lands displayed.\n'
          'What am I?',
      plantToFindId: 'maize',
      status: LevelStatus.locked,
      stars: 0,
      clueStrength: 'Low',
      distanceHint: 60,
    ),
  ];

  /// Alternative common names for matching with Plant.ID API
  static const Map<String, List<String>> plantAliases = {
    'rose': ['rose', 'rosa', 'garden rose', 'wild rose', 'climbing rose'],
    'marigold': ['marigold', 'tagetes', 'african marigold', 'french marigold', 'pot marigold'],
    'rhododendron': ['rhododendron', 'azalea', 'lali gurans', 'alpine rose'],
    'guava': ['guava', 'psidium guajava', 'common guava', 'apple guava', 'lemon guava'],
    'maize': ['maize', 'corn', 'zea mays', 'sweet corn', 'indian corn'],
  };

  /// Check if identified plant matches expected plant
  static bool isPlantMatch(String expectedPlantId, List<String> identifiedNames) {
    final aliases = plantAliases[expectedPlantId.toLowerCase()] ?? [expectedPlantId.toLowerCase()];
    
    for (final identifiedName in identifiedNames) {
      final lowerName = identifiedName.toLowerCase();
      for (final alias in aliases) {
        if (lowerName.contains(alias) || alias.contains(lowerName)) {
          return true;
        }
      }
    }
    return false;
  }
}
