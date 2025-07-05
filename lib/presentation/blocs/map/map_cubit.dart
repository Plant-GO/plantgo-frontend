import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/models/plant/plant_model.dart';
import 'package:plantgo/presentation/blocs/map/map_state.dart';
import 'package:plantgo/core/services/location_service.dart';
import 'package:plantgo/core/services/image_service.dart';
import 'package:plantgo/core/services/user_service.dart';

@injectable
class MapCubit extends Cubit<MapState> {
  final ApiService _apiService;
  final LocationService _locationService;
  final ImageService _imageService;
  final UserService _userService;
  String? _currentUserId; // Store current user ID

  MapCubit(
    this._apiService,
    this._locationService,
    this._imageService,
    this._userService,
  ) : super(MapInitial());

  // Set current user ID for filtering plants
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  Future<void> initializeMap({String? userId}) async {
    try {
      emit(MapLoading());
      
      // Set user ID if provided, otherwise use UserService
      _currentUserId = userId ?? _userService.currentUserId;
      
      // Check location permission and get current location
      final hasPermission = await _locationService.checkLocationPermission();
      Position? currentLocation;
      
      if (hasPermission) {
        currentLocation = await _locationService.getCurrentLocation();
      }

      // Load user-specific plants from Firestore
      final plants = await _loadUserPlantsFromFirestore(_currentUserId);

      emit(MapLoaded(
        currentLocation: currentLocation,
        plants: plants,
        isLocationPermissionGranted: hasPermission,
      ));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  Future<void> updateLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      
      if (state is MapLoaded) {
        final currentState = state as MapLoaded;
        emit(MapLoaded(
          currentLocation: location,
          plants: currentState.plants,
          isLocationPermissionGranted: currentState.isLocationPermissionGranted,
        ));
      }
      
      emit(MapLocationUpdated(location: location));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  Future<void> addPlant({
    required String name,
    required String imagePath,
    String? userId,
    String? description,
    String? species,
    String? family,
    List<String>? tags,
  }) async {
    try {
      if (state is! MapLoaded) return;
      
      final currentState = state as MapLoaded;
      if (currentState.currentLocation == null) {
        emit(const MapError(message: 'Location not available'));
        return;
      }

      // Use provided userId or current user ID from UserService
      final plantUserId = userId ?? _currentUserId ?? _userService.currentUserId;
      if (plantUserId == null) {
        emit(const MapError(message: 'User ID not available. Please log in first.'));
        return;
      }

      // Process the image
      final imageUrl = await _imageService.processAndUploadImage(imagePath);
      if (imageUrl == null) {
        emit(const MapError(message: 'Failed to process image'));
        return;
      }

      // Create plant model with all fields
      final plant = PlantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        latitude: currentState.currentLocation!.latitude,
        longitude: currentState.currentLocation!.longitude,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: description,
        species: species,
        family: family,
        tags: tags ?? [],
        userId: plantUserId,
      );

      // Save to Firestore
      await _savePlantToFirestore(plant);

      // Update state with new plant
      final updatedPlants = [...currentState.plants, plant];
      emit(MapLoaded(
        currentLocation: currentState.currentLocation,
        plants: updatedPlants,
        isLocationPermissionGranted: currentState.isLocationPermissionGranted,
      ));

      emit(MapPlantAdded(plant: plant));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  Future<void> deletePlant(String plantId) async {
    try {
      if (state is! MapLoaded) return;
      
      final currentState = state as MapLoaded;
      
      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('treasures')
          .doc(plantId)
          .delete();

      // Update state
      final updatedPlants = currentState.plants
          .where((plant) => plant.id != plantId)
          .toList();

      emit(MapLoaded(
        currentLocation: currentState.currentLocation,
        plants: updatedPlants,
        isLocationPermissionGranted: currentState.isLocationPermissionGranted,
      ));
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  Future<List<PlantModel>> _loadUserPlantsFromFirestore(String? userId) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('treasures');
      
      // If userId is provided, filter by userId, otherwise get all plants
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      // Order by creation date, newest first
      query = query.orderBy('createdAt', descending: true);
      
      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlantModelX.fromTreasure(data);
      }).toList();
    } catch (e) {
      print('Error loading plants from Firestore: $e');
      return [];
    }
  }

  Future<void> _savePlantToFirestore(PlantModel plant) async {
    await FirebaseFirestore.instance
        .collection('treasures')
        .add(plant.toTreasureMap());
  }

  void refreshPlants() {
    if (state is MapLoaded) {
      initializeMap(userId: _currentUserId);
    }
  }
}
