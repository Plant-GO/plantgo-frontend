import 'package:latlong2/latlong.dart';
import 'plant.dart';

/// Marker type for the map
enum MarkerType { plant, legendary, user, target }

/// Plant marker on the map
class PlantMarker {
  final String id;
  final LatLng position;
  final String plantId;
  final String plantName;
  final PlantRarity rarity;
  final MarkerType type;
  final String? locationName;
  final int? distanceMeters;
  final String? discoveredByUserId;
  final DateTime? discoveredAt;

  const PlantMarker({
    required this.id,
    required this.position,
    required this.plantId,
    required this.plantName,
    required this.rarity,
    this.type = MarkerType.plant,
    this.locationName,
    this.distanceMeters,
    this.discoveredByUserId,
    this.discoveredAt,
  });

  factory PlantMarker.fromJson(Map<String, dynamic> json) {
    return PlantMarker(
      id: json['id'] ?? '',
      position: LatLng(
        json['latitude']?.toDouble() ?? 0.0,
        json['longitude']?.toDouble() ?? 0.0,
      ),
      plantId: json['plantId'] ?? '',
      plantName: json['plantName'] ?? '',
      rarity: PlantRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => PlantRarity.common,
      ),
      type: MarkerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MarkerType.plant,
      ),
      locationName: json['locationName'],
      distanceMeters: json['distanceMeters'],
      discoveredByUserId: json['discoveredByUserId'],
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.parse(json['discoveredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'plantId': plantId,
    'plantName': plantName,
    'rarity': rarity.name,
    'type': type.name,
    'locationName': locationName,
    'distanceMeters': distanceMeters,
    'discoveredByUserId': discoveredByUserId,
    'discoveredAt': discoveredAt?.toIso8601String(),
  };
}

/// Sample markers for demo
class SampleMarkers {
  static final List<PlantMarker> markers = [
    PlantMarker(
      id: 'marker_1',
      position: const LatLng(45.5155, -122.6620),
      plantId: 'variegated_monstera',
      plantName: 'Variegated Monstera',
      rarity: PlantRarity.legendary,
      type: MarkerType.legendary,
      locationName: 'Secret Garden',
      distanceMeters: 5,
    ),
    PlantMarker(
      id: 'marker_2',
      position: const LatLng(45.5170, -122.6650),
      plantId: 'monstera_deliciosa',
      plantName: 'Monstera Deliciosa',
      rarity: PlantRarity.rare,
      type: MarkerType.plant,
      locationName: 'Rose City Park',
      distanceMeters: 120,
    ),
    PlantMarker(
      id: 'marker_3',
      position: const LatLng(45.5130, -122.6580),
      plantId: 'pine_tree',
      plantName: 'The Silent Watcher',
      rarity: PlantRarity.epic,
      type: MarkerType.plant,
      locationName: 'Mt. Tabor Park',
      distanceMeters: 250,
    ),
  ];
}
