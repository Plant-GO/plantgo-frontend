import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/models/plant/plant_model.dart';
import 'package:plantgo/presentation/blocs/map/map_state.dart';
import 'package:plantgo/core/services/location_service.dart';
import 'package:plantgo/core/services/image_service.dart';

@injectable
class MapCubit extends Cubit<MapState> {
  final ApiService _apiService;
  final LocationService _locationService;
  final ImageService _imageService;

  MapCubit(
    this._apiService,
    this._locationService,
    this._imageService,
  ) : super(MapInitial());

  Future<void> initializeMap() async {
    try {
      emit(MapLoading());
      
      // Check location permission and get current location
      final hasPermission = await _locationService.checkLocationPermission();
      Position? currentLocation;
      
      if (hasPermission) {
        currentLocation = await _locationService.getCurrentLocation();
      }

      // Load plants from Firestore (for now) - later from API
      final plants = await _loadPlantsFromFirestore();

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
  }) async {
    try {
      if (state is! MapLoaded) return;
      
      final currentState = state as MapLoaded;
      if (currentState.currentLocation == null) {
        emit(const MapError(message: 'Location not available'));
        return;
      }

      // Process the image
      final imageUrl = await _imageService.processAndUploadImage(imagePath);
      if (imageUrl == null) {
        emit(const MapError(message: 'Failed to process image'));
        return;
      }

      // Create plant model
      final plant = PlantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        latitude: currentState.currentLocation!.latitude,
        longitude: currentState.currentLocation!.longitude,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Save to Firestore (for now) - later to API
      await _savePlantToFirestore(plant);

      // Update state
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

  Future<List<PlantModel>> _loadPlantsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('treasures')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PlantModelX.fromTreasure(data);
      }).toList();
    } catch (e) {
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
      initializeMap();
    }
  }
}
