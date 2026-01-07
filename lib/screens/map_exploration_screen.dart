import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../models/plant_marker.dart';
import '../models/user_progress.dart';
import '../providers/map_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/plant_marker_widget.dart';
import '../widgets/plant_preview_card.dart';

/// Map Exploration Screen - Full map with plant markers
class MapExplorationScreen extends StatefulWidget {
  const MapExplorationScreen({super.key});

  @override
  State<MapExplorationScreen> createState() => _MapExplorationScreenState();
}

class _MapExplorationScreenState extends State<MapExplorationScreen> {
  final MapController _mapController = MapController();
  bool _hasInitializedPosition = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Wait for widget to build
    if (!mounted) return;

    await context.read<MapProvider>().initialize();

    // Center on user location after initialization
    if (mounted) {
      final mapProvider = context.read<MapProvider>();
      try {
        _mapController.move(mapProvider.userLocation, mapProvider.zoom);
      } catch (e) {
        // Map controller might not be ready yet, ignore
        debugPrint('Map move failed: $e');
      }
      setState(() {
        _hasInitializedPosition = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map
          _buildMap(context, mapProvider),

          // Loading overlay while fetching location
          if (mapProvider.isLoading || !_hasInitializedPosition)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Finding your location...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // App bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAppBar(context),
            ),
          ),

          // Location button
          Positioned(
            right: 16,
            bottom: mapProvider.selectedMarker != null ? 220 : 100,
            child: _buildLocationButton(context, mapProvider),
          ),

          // Plant filter button
          Positioned(
            right: 16,
            bottom: mapProvider.selectedMarker != null ? 280 : 160,
            child: _buildFilterButton(context),
          ),

          // Plant preview card
          if (mapProvider.selectedMarker != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PlantPreviewCard(
                marker: mapProvider.selectedMarker!,
                onCollect: () =>
                    _handleCollect(context, mapProvider.selectedMarker!),
                onBookmark: () {},
                onInfo: () {},
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Map Exploration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.layers_rounded),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildMap(BuildContext context, MapProvider mapProvider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapProvider.mapCenter,
        initialZoom: mapProvider.zoom,
        onTap: (_, __) {
          mapProvider.clearSelection();
        },
      ),
      children: [
        // OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.plantgo.app',
        ),

        // Plant markers
        MarkerLayer(
          markers: [
            // User location
            Marker(
              point: mapProvider.userLocation,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Plant markers
            ...mapProvider.markers.map(
              (marker) => Marker(
                point: marker.position,
                width: 60,
                height: 70,
                child: PlantMarkerWidget(
                  marker: marker,
                  isSelected: mapProvider.selectedMarker?.id == marker.id,
                  onTap: () => mapProvider.selectMarker(marker),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationButton(BuildContext context, MapProvider mapProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location_rounded),
        color: AppColors.textSecondary,
        onPressed: () {
          mapProvider.centerOnUser();
          _mapController.move(mapProvider.userLocation, mapProvider.zoom);
        },
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
      ),
    );
  }

  void _handleCollect(BuildContext context, PlantMarker marker) {
    final userProvider = context.read<UserProvider>();

    // Check if already collected
    if (userProvider.hasPlant(marker.plantId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${marker.plantName} is already in your collection!'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    // Add to collection
    final collectedPlant = CollectedPlant(
      plantId: marker.plantId,
      name: marker.plantName,
      rarity: marker.rarity,
      discoveredAt: DateTime.now(),
      latitude: marker.position.latitude,
      longitude: marker.position.longitude,
      isFirstFind: true, // TODO: Check if first global find
    );

    userProvider.addToCollection(collectedPlant);

    // Clear selection and show success
    context.read<MapProvider>().clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${marker.plantName} added to collection!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
