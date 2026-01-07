import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';
import '../providers/map_provider.dart';
import '../services/treasure_service.dart';
import '../services/plant_id_service.dart';

/// Map Exploration Screen - Shows user's discovered treasures on map
class MapExplorationScreen extends StatefulWidget {
  final String? highlightTreasureId;
  
  const MapExplorationScreen({super.key, this.highlightTreasureId});

  @override
  State<MapExplorationScreen> createState() => _MapExplorationScreenState();
}

class _MapExplorationScreenState extends State<MapExplorationScreen> {
  final MapController _mapController = MapController();
  bool _hasInitializedPosition = false;
  List<Treasure> _treasures = [];
  bool _isLoadingTreasures = true;
  Treasure? _selectedTreasure;
  String _searchQuery = '';
  List<String> _matchingTreasureIds = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadTreasures().then((_) {
      // If a treasure should be highlighted, select it and zoom to it
      if (widget.highlightTreasureId != null && _treasures.isNotEmpty) {
        final treasure = _treasures.firstWhere(
          (t) => t.id == widget.highlightTreasureId,
          orElse: () => _treasures.first,
        );
        
        if (mounted) {
          setState(() {
            _selectedTreasure = treasure;
          });
          
          // Zoom to the treasure location
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _mapController.move(
                LatLng(treasure.latitude, treasure.longitude),
                15.0, // Zoom level
              );
            }
          });
        }
      }
    });
  }

  Future<void> _initializeMap() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await context.read<MapProvider>().initialize();

    if (mounted) {
      final mapProvider = context.read<MapProvider>();
      try {
        _mapController.move(mapProvider.userLocation, mapProvider.zoom);
      } catch (e) {
        debugPrint('Map move failed: $e');
      }
      setState(() {
        _hasInitializedPosition = true;
      });
    }
  }

  Future<void> _loadTreasures() async {
    try {
      final treasureService = TreasureService();
      // Load ALL treasures from all users
      final treasures = await treasureService.getAllTreasures();
      
      debugPrint('📍 Loaded ${treasures.length} treasures from Firebase');
      for (var treasure in treasures) {
        debugPrint('  - ${treasure.commonName} at (${treasure.latitude}, ${treasure.longitude}) by ${treasure.userName}');
      }
      
      if (mounted) {
        setState(() {
          _treasures = treasures;
          _isLoadingTreasures = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading treasures: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingTreasures = false;
        });
      }
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
            bottom: _selectedTreasure != null ? 260 : 100,
            child: _buildLocationButton(context, mapProvider),
          ),

          // Treasure count badge
          Positioned(
            right: 16,
            bottom: _selectedTreasure != null ? 320 : 160,
            child: _buildTreasureCountBadge(),
          ),

          // Treasure preview card
          if (_selectedTreasure != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildTreasureCard(_selectedTreasure!),
            ),
            
          // Empty state message
          if (!_isLoadingTreasures && _treasures.isEmpty && _hasInitializedPosition)
            Positioned(
              left: 24,
              right: 24,
              bottom: 100,
              child: _buildEmptyState(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'No Treasures Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete riddles in Course Mode to discover plants and add them to your treasure map!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasureCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 6),
          Text(
            '${_treasures.length}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasureCard(Treasure treasure) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Plant image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: treasure.imageBase64.isNotEmpty
                    ? Image.memory(
                        const Base64Decoder().convert(
                          treasure.imageBase64.replaceAll(RegExp(r'^data:image\/[a-zA-Z]+;base64,'), '')
                        ),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 40),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              
              // Plant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treasure.commonName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discovered by ${treasure.userName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(treasure.discoveredAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level ${treasure.levelId}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlantDetailPage(treasure: treasure),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Full View'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedTreasure = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
            onPressed: _showSearchDialog,
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
          setState(() => _selectedTreasure = null);
        },
      ),
      children: [
        // OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.plantgo.app',
        ),

        // Treasure markers
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

            // Treasure markers from Firebase (non-matches first)
            ..._treasures
                .where((treasure) => !_matchingTreasureIds.contains(treasure.id))
                .map(
              (treasure) => Marker(
                point: LatLng(treasure.latitude, treasure.longitude),
                width: 60,
                height: 70,
                child: _buildTreasureMarker(treasure),
              ),
            ),
            
            // Search match markers on top (rendered last)
            ..._treasures
                .where((treasure) => _matchingTreasureIds.contains(treasure.id))
                .map(
              (treasure) => Marker(
                point: LatLng(treasure.latitude, treasure.longitude),
                width: 60,
                height: 70,
                child: _buildTreasureMarker(treasure),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTreasureMarker(Treasure treasure) {
    final isSelected = _selectedTreasure?.id == treasure.id;
    final isSearchMatch = _matchingTreasureIds.contains(treasure.id);
    final markerColor = isSearchMatch ? Colors.red : AppColors.primary;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTreasure = treasure),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Treasure icon container
          Container(
            width: isSelected ? 50 : 44,
            height: isSelected ? 50 : 44,
            decoration: BoxDecoration(
              color: isSearchMatch ? Colors.red : (isSelected ? markerColor : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: markerColor,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(isSelected ? 0.4 : 0.2),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '🌿',
                style: TextStyle(fontSize: isSelected ? 24 : 20),
              ),
            ),
          ),
          // Pointer triangle
          CustomPaint(
            size: const Size(12, 8),
            painter: _MarkerPointerPainter(
              color: isSearchMatch ? Colors.red : (isSelected ? markerColor : Colors.white),
              borderColor: markerColor,
            ),
          ),
        ],
      ),
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
}

// Custom painter for marker pointer triangle
class _MarkerPointerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _MarkerPointerPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add search dialog method in _MapExplorationScreenState class
extension SearchFunctionality on _MapExplorationScreenState {
  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(text: _searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Plants'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter plant name',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _performSearch(value);
          },
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performSearch(searchController.text);
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _searchQuery = query;
      // Use regex to match plant names (case insensitive)
      final regex = RegExp(query, caseSensitive: false);
      _matchingTreasureIds = _treasures
          .where((treasure) => 
              regex.hasMatch(treasure.commonName) || 
              regex.hasMatch(treasure.plantName))
          .map((treasure) => treasure.id)
          .toList();
      
      // Debug: Print matching treasures
      debugPrint('🔍 Search for "$query" found ${_matchingTreasureIds.length} matches');
      for (var id in _matchingTreasureIds) {
        final treasure = _treasures.firstWhere((t) => t.id == id);
        debugPrint('  ✅ ${treasure.commonName} at (${treasure.latitude}, ${treasure.longitude})');
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _matchingTreasureIds = [];
    });
  }
}

/// Plant Detail Page - Full view of a discovered plant
class PlantDetailPage extends StatefulWidget {
  final Treasure treasure;

  const PlantDetailPage({super.key, required this.treasure});

  @override
  State<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends State<PlantDetailPage> {
  String? _plantDescription;
  bool _isLoadingDescription = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantDescription();
  }

  Future<void> _fetchPlantDescription() async {
    // If description already exists in treasure, use it
    if (widget.treasure.description != null && widget.treasure.description!.isNotEmpty) {
      setState(() {
        _plantDescription = widget.treasure.description;
        _isLoadingDescription = false;
      });
      return;
    }

    // Otherwise, fetch from API using the stored image
    try {
      final plantIdService = PlantIdService();
      // Remove data URI prefix if present
      final imageData = widget.treasure.imageBase64
          .replaceAll(RegExp(r'^data:image\/[a-zA-Z]+;base64,'), '');
      
      final result = await plantIdService.identifyPlant(imageData);
      
      if (result.suggestions.isNotEmpty) {
        final topSuggestion = result.suggestions.first;
        if (mounted) {
          setState(() {
            _plantDescription = topSuggestion.description ?? 
                'No detailed description available for this plant.';
            _isLoadingDescription = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _plantDescription = 'No detailed description available for this plant.';
            _isLoadingDescription = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching plant description: $e');
      if (mounted) {
        setState(() {
          _plantDescription = 'Failed to load plant description.';
          _isLoadingDescription = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.treasure.imageBase64.isNotEmpty
                  ? Image.memory(
                      const Base64Decoder().convert(
                        widget.treasure.imageBase64.replaceAll(RegExp(r'^data:image\/[a-zA-Z]+;base64,'), '')
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.eco_rounded, size: 80, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.eco_rounded, size: 80, color: Colors.white),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Common Name',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.treasure.commonName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Scientific Name',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.treasure.plantName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Discovery info section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discovery Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.person, 'Discovered by', widget.treasure.userName),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.calendar_today, 'Discovery date', _formatDate(widget.treasure.discoveredAt)),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, 'Location', '${widget.treasure.latitude.toStringAsFixed(4)}, ${widget.treasure.longitude.toStringAsFixed(4)}'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.layers, 'Level', 'Level ${widget.treasure.levelId}'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.verified, 'Confidence', '${(widget.treasure.confidence * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Plant information section (placeholder for API data)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'About This Plant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _isLoadingDescription
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Text(
                                _plantDescription ?? 'No description available for this plant.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
