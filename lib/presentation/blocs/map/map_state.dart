import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plantgo/models/plant/plant_model.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final Position? currentLocation;
  final List<PlantModel> plants;
  final bool isLocationPermissionGranted;

  const MapLoaded({
    this.currentLocation,
    required this.plants,
    required this.isLocationPermissionGranted,
  });

  @override
  List<Object?> get props => [currentLocation, plants, isLocationPermissionGranted];
}

class MapLocationUpdated extends MapState {
  final Position location;

  const MapLocationUpdated({required this.location});

  @override
  List<Object?> get props => [location];
}

class MapPlantAdded extends MapState {
  final PlantModel plant;

  const MapPlantAdded({required this.plant});

  @override
  List<Object?> get props => [plant];
}

class MapError extends MapState {
  final String message;

  const MapError({required this.message});

  @override
  List<Object?> get props => [message];
}
