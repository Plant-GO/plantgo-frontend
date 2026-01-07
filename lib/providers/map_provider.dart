import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/plant_marker.dart';
import '../models/plant.dart';
import '../services/firebase_sync_service.dart';
import '../services/location_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for map state and plant markers
class MapProvider extends ChangeNotifier {
  final FirebaseSyncService? _firebaseService;
  final LocationService _locationService = LocationService();

  List<PlantMarker> _markers = [];
  LatLng _userLocation = const LatLng(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );
  LatLng _mapCenter = const LatLng(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );
  double _zoom = AppConstants.defaultMapZoom;
  PlantMarker? _selectedMarker;
  bool _isLoading = false;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _markersSubscription;

  MapProvider({FirebaseSyncService? firebaseService})
    : _firebaseService = firebaseService;

  List<PlantMarker> get markers => _markers;
  LatLng get userLocation => _userLocation;
  LatLng get mapCenter => _mapCenter;
  double get zoom => _zoom;
  PlantMarker? get selectedMarker => _selectedMarker;
  bool get isLoading => _isLoading;

  /// Initialize map with user location and Firebase sync
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Get initial location
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      _userLocation = location;
      _mapCenter = location;

      // Generate sample markers around user's actual location
      _markers = _generateMarkersAroundLocation(location);
    }

    // Start location updates
    _locationSubscription = _locationService.getLocationStream().listen((
      location,
    ) {
      _userLocation = location;
      notifyListeners();
    });

    // Start Firebase sync if available
    if (_firebaseService != null) {
      _markersSubscription = _firebaseService!.plantDiscoveriesStream.listen((
        markers,
      ) {
        _markers = [..._markers, ...markers];
        notifyListeners();
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Generate sample plant markers around a given location
  List<PlantMarker> _generateMarkersAroundLocation(LatLng center) {
    final random = Random();

    // Sample plant data
    final samplePlants = [
      {
        'id': 'monstera_variegata',
        'name': 'Variegated Monstera',
        'rarity': PlantRarity.legendary,
      },
      {
        'id': 'monstera_deliciosa',
        'name': 'Monstera Deliciosa',
        'rarity': PlantRarity.rare,
      },
      {
        'id': 'silent_watcher',
        'name': 'The Silent Watcher',
        'rarity': PlantRarity.epic,
      },
      {
        'id': 'golden_pothos',
        'name': 'Golden Pothos',
        'rarity': PlantRarity.common,
      },
      {
        'id': 'snake_plant',
        'name': 'Snake Plant',
        'rarity': PlantRarity.uncommon,
      },
    ];

    return samplePlants.asMap().entries.map((entry) {
      final index = entry.key;
      final plant = entry.value;

      // Generate random offset (within ~500m radius)
      final latOffset = (random.nextDouble() - 0.5) * 0.008;
      final lngOffset = (random.nextDouble() - 0.5) * 0.008;

      final rarity = plant['rarity'] as PlantRarity;

      return PlantMarker(
        id: 'marker_$index',
        position: LatLng(
          center.latitude + latOffset,
          center.longitude + lngOffset,
        ),
        plantId: plant['id'] as String,
        plantName: plant['name'] as String,
        rarity: rarity,
        type: rarity == PlantRarity.legendary
            ? MarkerType.legendary
            : MarkerType.plant,
        locationName: 'Nearby',
        distanceMeters: (random.nextDouble() * 500).toInt(),
      );
    }).toList();
  }

  /// Select a marker
  void selectMarker(PlantMarker marker) {
    _selectedMarker = marker;
    notifyListeners();
  }

  /// Clear marker selection
  void clearSelection() {
    _selectedMarker = null;
    notifyListeners();
  }

  /// Update map center
  void setMapCenter(LatLng center) {
    _mapCenter = center;
    notifyListeners();
  }

  /// Update zoom level
  void setZoom(double zoom) {
    _zoom = zoom.clamp(AppConstants.minMapZoom, AppConstants.maxMapZoom);
    notifyListeners();
  }

  /// Center map on user location
  void centerOnUser() {
    _mapCenter = _userLocation;
    notifyListeners();
  }

  /// Add a new plant discovery to the map
  Future<void> addPlantDiscovery({
    required String plantId,
    required String plantName,
    required PlantRarity rarity,
    required String userId,
  }) async {
    final marker = PlantMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: _userLocation,
      plantId: plantId,
      plantName: plantName,
      rarity: rarity,
      type: rarity == PlantRarity.legendary
          ? MarkerType.legendary
          : MarkerType.plant,
      discoveredByUserId: userId,
      discoveredAt: DateTime.now(),
    );

    // Add locally first
    _markers = [..._markers, marker];
    notifyListeners();

    // Sync to Firebase
    if (_firebaseService != null) {
      await _firebaseService!.addPlantDiscovery(marker);
    }
  }

  /// Calculate distance from user to a point
  String distanceToMarker(PlantMarker marker) {
    final distance = _locationService.calculateDistance(
      _userLocation,
      marker.position,
    );
    return _locationService.formatDistance(distance);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _markersSubscription?.cancel();
    super.dispose();
  }
}
