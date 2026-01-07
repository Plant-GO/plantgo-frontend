import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';
import '../providers/course_provider.dart';
import '../providers/map_provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/riddle_card.dart';
import 'plant_discovery_screen.dart';

/// Level Detail Screen - Shows riddle and map for active level
class LevelDetailScreen extends StatefulWidget {
  const LevelDetailScreen({super.key});

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize map and get current location
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mapProvider = context.read<MapProvider>();
      await mapProvider.initialize();

      // Move map to current location once ready
      if (mounted) {
        setState(() => _mapReady = true);
        _moveToCurrentLocation();
      }
    });
  }

  void _moveToCurrentLocation() {
    if (!_mapReady) return;

    final mapProvider = context.read<MapProvider>();
    try {
      _mapController.move(mapProvider.userLocation, mapProvider.zoom);
    } catch (e) {
      // Map controller might not be ready yet
      debugPrint('Map move delayed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final level = courseProvider.selectedLevel;

    if (level == null) {
      return const Scaffold(body: Center(child: Text('No level selected')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map as background
          _buildMap(context),

          // Content overlay
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, level),
                const Spacer(),
                _buildRiddleCard(level),
                const SizedBox(height: 16),
                _buildScanButton(context, level),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Location button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded),
                color: AppColors.primary,
                onPressed: _moveToCurrentLocation,
              ),
            ),
          ),

          // Target marker representation
          _buildTargetMarker(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Level level) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                context.read<CourseProvider>().clearSelection();
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 16),

          // Level info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL ${level.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  level.subtitle.isNotEmpty ? level.subtitle : level.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Skip button
          TextButton(
            onPressed: () {},
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapProvider.userLocation,
        initialZoom: 16.0, // Closer zoom for level view
        onMapReady: () {
          setState(() => _mapReady = true);
          _moveToCurrentLocation();
        },
      ),
      children: [
        // OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.plantgo.app',
        ),

        // User location marker
        MarkerLayer(
          markers: [
            Marker(
              point: mapProvider.userLocation,
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetMarker(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildRiddleCard(Level level) {
    return RiddleCard(
      riddle: level.riddle,
      clueStrength: level.clueStrength,
      distance: '${level.distanceHint}m',
    );
  }

  Widget _buildScanButton(BuildContext context, Level level) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => _handleScan(context, level),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.camera_alt_rounded, size: 24),
          label: const Text(
            'Scan Plant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _handleScan(BuildContext context, Level level) async {
    final scanProvider = context.read<ScanProvider>();

    // Capture image
    await scanProvider.captureImage();

    if (scanProvider.capturedImagePath != null) {
      // Verify plant
      await scanProvider.verifyPlant(level.plantToFindId);

      if (scanProvider.state == ScanState.success) {
        // Navigate to discovery screen
        if (context.mounted) {
          final plant = context.read<CourseProvider>().getPlantForLevel(
            level.id,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PlantDiscoveryScreen(plant: plant!, levelId: level.id),
            ),
          );
        }
      } else {
        // Show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(scanProvider.errorMessage ?? 'Try again'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
