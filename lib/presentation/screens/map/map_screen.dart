import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:plantgo/core/constants/app_constants.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    context.read<MapCubit>().initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Go'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => context.read<MapCubit>().updateLocation(),
          ),
        ],
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<MapCubit>().initializeMap(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MapLoaded) {
            return _buildMap(state);
          }

          return const Center(
            child: Text('Unknown state'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPlantCaptureBottomSheet(context);
        },
        tooltip: 'Capture Plant',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildMap(MapLoaded state) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: state.currentLocation != null
            ? LatLng(
                state.currentLocation!.latitude,
                state.currentLocation!.longitude,
              )
            : const LatLng(
                AppConstants.defaultLatitude,
                AppConstants.defaultLongitude,
              ),
        zoom: AppConstants.defaultZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            // Current location marker
            if (state.currentLocation != null)
              Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(
                  state.currentLocation!.latitude,
                  state.currentLocation!.longitude,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            // Plant markers
            ...state.plants.map((plant) {
              return Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(plant.latitude, plant.longitude),
                child: GestureDetector(
                  onTap: () => _showPlantDetails(plant),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  void _showPlantDetails(dynamic plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plant.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // For now, just show text. In the future, we'll show the image
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Location: ${plant.latitude.toStringAsFixed(5)}, ${plant.longitude.toStringAsFixed(5)}",
            ),
            if (plant.description != null) ...[
              const SizedBox(height: 8),
              Text(plant.description!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPlantCaptureBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add a Plant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement camera capture
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera feature coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery selection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery feature coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
