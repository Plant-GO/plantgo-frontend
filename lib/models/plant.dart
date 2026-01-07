import 'package:latlong2/latlong.dart';

/// Rarity levels for plants
enum PlantRarity { common, uncommon, rare, epic, legendary }

/// Plant care information
class PlantCareInfo {
  final String water; // e.g., "Low", "Med", "High"
  final String light; // e.g., "Low", "Bright", "Indirect"
  final String temperature; // e.g., "65-80°F"
  final String humidity; // e.g., "High", "Moderate"

  const PlantCareInfo({
    required this.water,
    required this.light,
    this.temperature = '',
    this.humidity = '',
  });

  factory PlantCareInfo.fromJson(Map<String, dynamic> json) {
    return PlantCareInfo(
      water: json['water'] ?? 'Med',
      light: json['light'] ?? 'Bright',
      temperature: json['temperature'] ?? '',
      humidity: json['humidity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'water': water,
    'light': light,
    'temperature': temperature,
    'humidity': humidity,
  };
}

/// Plant model
class Plant {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final PlantRarity rarity;
  final String habitat; // e.g., "Tropical Forests"
  final String region; // e.g., "Central America"
  final PlantCareInfo careInfo;
  final String imageUrl;
  final int xpReward;
  final LatLng? location;

  const Plant({
    required this.id,
    required this.name,
    this.scientificName = '',
    this.description = '',
    required this.rarity,
    this.habitat = '',
    this.region = '',
    required this.careInfo,
    this.imageUrl = '',
    required this.xpReward,
    this.location,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      rarity: PlantRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => PlantRarity.common,
      ),
      habitat: json['habitat'] ?? '',
      region: json['region'] ?? '',
      careInfo: PlantCareInfo.fromJson(json['careInfo'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
      xpReward: json['xpReward'] ?? 50,
      location: json['latitude'] != null && json['longitude'] != null
          ? LatLng(json['latitude'], json['longitude'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scientificName': scientificName,
    'description': description,
    'rarity': rarity.name,
    'habitat': habitat,
    'region': region,
    'careInfo': careInfo.toJson(),
    'imageUrl': imageUrl,
    'xpReward': xpReward,
    'latitude': location?.latitude,
    'longitude': location?.longitude,
  };

  /// Get rarity display string
  String get rarityDisplay => rarity.name.toUpperCase();
}

// Sample plants for demo
class SamplePlants {
  static const List<Plant> plants = [
    Plant(
      id: 'monstera_deliciosa',
      name: 'Monstera Deliciosa',
      scientificName: 'Monstera deliciosa',
      description:
          'A popular houseplant known for its distinctive split leaves.',
      rarity: PlantRarity.legendary,
      habitat: 'Tropical Forests',
      region: 'Central America',
      careInfo: PlantCareInfo(water: 'Med', light: 'Bright'),
      xpReward: 150,
    ),
    Plant(
      id: 'variegated_monstera',
      name: 'Variegated Monstera',
      scientificName: 'Monstera deliciosa variegata',
      description: 'A rare variegated form with stunning white patterns.',
      rarity: PlantRarity.legendary,
      habitat: 'Secret Garden',
      region: 'Central America',
      careInfo: PlantCareInfo(water: 'Med', light: 'Bright'),
      xpReward: 250,
    ),
    Plant(
      id: 'pine_tree',
      name: 'The Silent Watcher',
      scientificName: 'Pinus',
      description: 'A tall evergreen conifer standing guard near the fountain.',
      rarity: PlantRarity.rare,
      habitat: 'Mountain Forest',
      region: 'North America',
      careInfo: PlantCareInfo(water: 'Low', light: 'Bright'),
      xpReward: 100,
    ),
  ];
}
