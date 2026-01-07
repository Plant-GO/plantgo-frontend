import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:provider/Provider.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/theme/app_colors.dart';
import '../services/plant_id_service.dart';
import '../services/treasure_service.dart';
import '../services/user_service.dart';
import '../providers/user_provider.dart';
import '../providers/course_provider.dart';
import '../models/user_progress.dart';
import '../models/plant.dart';
import 'collections_screen.dart';
import 'course_map_screen.dart';
import 'map_exploration_screen.dart';
import 'animated_scanner_screen.dart';

/// Main navigation shell with bottom tab bar and floating map button
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Start on Game tab (as requested for Hult demo)

  final List<Widget> _screens = [
    const _GameScreen(),
    const CourseMapScreen(),
    const CollectionsScreen(),
    const _IdentifyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('deviceId');
      
      if (userId != null && mounted) {
        // Load course progress
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.loadUserProgress(userId);
        debugPrint('✅ Loaded course progress for $userId');
        
        // Load user coins and leaves from Firebase
        final userService = UserService();
        final user = await userService.getUser(userId);
        if (user != null && mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          // Update the UserProvider with Firebase data
          userProvider.setCoinsAndLeaves(user.coins, user.leaves);
          debugPrint('💰 Loaded ${user.coins} coins and ${user.leaves} leaves for $userId');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
    }
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Instagram-style docked FAB
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MapExplorationScreen()),
            );
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom app bar with notch
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left side items
              _buildNavItem(0, Icons.home_rounded, 'Game'),
              _buildNavItem(1, Icons.route_rounded, 'Course'),

              // Center gap for FAB
              const SizedBox(width: 60),

              // Right side items
              _buildNavItem(
                2,
                Icons.collections_bookmark_rounded,
                'Collection',
              ),
              _buildNavItem(3, Icons.center_focus_strong_rounded, 'Identify'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textTertiary;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game Screen - Main hub with scrollable content
class _GameScreen extends StatelessWidget {
  const _GameScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header
                const Center(
                  child: Text(
                    '🌿 Welcome to PlantGo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Discover plants in your area',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 48),

                // Feature cards - Now tappable and navigable
                _buildFeatureCard(
                  context: context,
                  icon: Icons.route_rounded,
                  title: 'Course Mode',
                  subtitle: 'Follow riddles to find plants',
                  color: AppColors.primary,
                  onTap: () {
                    // Navigate to Course tab
                    final navState = context.findAncestorStateOfType<_MainNavigationState>();
                    navState?._navigateToTab(1);
                  },
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.explore_rounded,
                  title: 'Explore Mode',
                  subtitle: 'Discover plants on the map',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MapExplorationScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.collections_rounded,
                  title: 'My Collection',
                  subtitle: 'View your discovered plants',
                  color: const Color(0xFF9C7CF4),
                  onTap: () {
                    // Navigate to Collections tab
                    final navState = context.findAncestorStateOfType<_MainNavigationState>();
                    navState?._navigateToTab(2);
                  },
                ),

                const SizedBox(height: 32),

                // Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tap "Course Mode" to start finding plants with riddles!',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for FAB and bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder Identify Screen with camera access
/// Placeholder Identify Screen with camera access
class _IdentifyScreen extends StatefulWidget {
  const _IdentifyScreen();

  @override
  State<_IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<_IdentifyScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlantIdService _plantIdService = PlantIdService();
  File? _image;
  bool _isAnalyzing = false;

  /// Compress image to ensure it's under 1MB when base64 encoded
  /// Target: ~500KB compressed = ~670KB base64 (well under 1MB limit)
  Future<Uint8List?> _compressImage(File imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();
      debugPrint('📷 Original image size: ${(originalBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // Compress image - target quality to get ~500KB or less
      var quality = 85;
      Uint8List? compressedBytes;
      
      // Try compression with decreasing quality until we get under 500KB
      while (quality > 20) {
        compressedBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: quality,
          minWidth: 800,
          minHeight: 800,
        );
        
        final compressedSize = compressedBytes.length;
        debugPrint('📦 Compressed to ${(compressedSize / 1024).toStringAsFixed(2)} KB at quality $quality');
        
        // Base64 encoding increases size by ~33%, so we need compressed size < 500KB
        // to ensure base64 size < 670KB (well under 1MB Firestore limit)
        if (compressedSize < 500 * 1024) {
          break;
        }
        
        quality -= 15;
      }
      
      return compressedBytes;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return null;
    }
  }

  Future<void> _openScanner() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _IdentifyScannerScreen(
              onImageCaptured: (File image) async {
                setState(() {
                  _image = image;
                  _isAnalyzing = true;
                });

                // Convert image to base64
                final bytes = await image.readAsBytes();
                final base64Image = base64Encode(bytes);

                try {
                  // Call PlantID API
                  final result = await _plantIdService.identifyPlant(base64Image);

                  if (mounted) {
                    setState(() {
                      _isAnalyzing = false;
                    });
                    _showResultDialog(result);
                  }
                } catch (e) {
                  debugPrint('Identification error: $e');
                  if (mounted) {
                    setState(() {
                      _isAnalyzing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Identification failed: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening scanner: $e')),
      );
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isAnalyzing = true;
        });

        // Convert image to base64
        final bytes = await _image!.readAsBytes();
        final base64Image = base64Encode(bytes);

        try {
          // Call PlantID API
          final result = await _plantIdService.identifyPlant(base64Image);

          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
            _showResultDialog(result);
          }
        } catch (e) {
          debugPrint('Identification error: $e');
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Identification failed: $e')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error accessing camera: $e')));
    }
  }

  void _showResultDialog(PlantIdResult result) {
    if (result.suggestions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No plants identified.')));
      return;
    }

    final topMatch = result.suggestions.first;
    // Use common name if available, otherwise use plantName (scientific name)
    final displayName = topMatch.commonNames.isNotEmpty 
        ? topMatch.commonNames.first 
        : topMatch.plantName;
    final scientificName = topMatch.plantName;
    final probability = (topMatch.probability * 100).toStringAsFixed(1);
    final commonNames = topMatch.commonNames.take(3).join(', ');
    final description = topMatch.description; // Get description from API

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: $probability%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            if (scientificName != displayName) ...[
              const SizedBox(height: 8),
              Text(
                'Scientific: $scientificName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (commonNames.isNotEmpty && displayName != commonNames) ...[
              const SizedBox(height: 8),
              Text(
                'Also known as: $commonNames',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );

                  try {
                    // Get current location - First check/request permissions
                    Position? position;
                    try {
                      // Check location permission status
                      LocationPermission permission = await Geolocator.checkPermission();
                      
                      if (permission == LocationPermission.denied) {
                        // Request permission
                        permission = await Geolocator.requestPermission();
                        debugPrint('🔐 Requested location permission: $permission');
                      }
                      
                      if (permission == LocationPermission.deniedForever) {
                        debugPrint('❌ Location permission denied forever');
                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close result dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location permission is permanently denied. Please enable it in Settings.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                        return;
                      }
                      
                      if (permission == LocationPermission.denied) {
                        debugPrint('❌ Location permission denied');
                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close result dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location permission is required to save plant location.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      
                      // Permission granted, get location
                      position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');
                    } catch (e) {
                      debugPrint('❌ Error getting location: $e');
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close result dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to get location. Please enable location services.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    // Compress and convert image to base64
                    String imageBase64 = '';
                    if (_image != null) {
                      try {
                        // Compress the image to ensure it's under 1MB in Firestore
                        final compressedBytes = await _compressImage(_image!);
                        
                        if (compressedBytes == null) {
                          debugPrint('❌ Failed to compress image');
                          if (mounted) {
                            Navigator.pop(context); // Close loading dialog
                            Navigator.pop(context); // Close result dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to process image.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                        
                        // Convert to base64
                        imageBase64 = base64Encode(compressedBytes);
                        final base64SizeKB = (imageBase64.length / 1024).toStringAsFixed(2);
                        debugPrint('✅ Base64 encoded size: $base64SizeKB KB');
                        
                        // Double check it's under 1MB
                        if (imageBase64.length > 900 * 1024) { // 900KB safety margin
                          debugPrint('⚠️ Image still too large after compression, using placeholder');
                          imageBase64 = 'placeholder';
                        }
                      } catch (e) {
                        debugPrint('❌ Error processing image: $e');
                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close result dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to process image.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    } else {
                      debugPrint('❌ No image available');
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close result dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No image captured.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    // Add to collection (local UserProvider)
                    final collectedPlant = CollectedPlant(
                      plantId: displayName.toLowerCase().replaceAll(' ', '_'),
                      name: displayName,
                      rarity: PlantRarity.common,
                      discoveredAt: DateTime.now(),
                      latitude: position.latitude,
                      longitude: position.longitude,
                      isFirstFind: false,
                    );

                    if (mounted) {
                      context.read<UserProvider>().addToCollection(collectedPlant);
                      debugPrint('✅ Added to local collection');
                    }

                    // Save as treasure to Firebase (this will appear in collections and map)
                    try {
                      final userProvider = context.read<UserProvider>();
                      final treasureService = TreasureService();
                      
                      debugPrint('💾 Saving treasure to Firebase...');
                      debugPrint('   User ID: ${userProvider.deviceId}');
                      debugPrint('   Common Name: $displayName');
                      debugPrint('   Scientific Name: $scientificName');
                      debugPrint('   Location: ${position.latitude}, ${position.longitude}');
                      
                      await treasureService.saveTreasure(
                        plantName: scientificName,
                        commonName: displayName,
                        latitude: position.latitude,
                        longitude: position.longitude,
                        imageBase64: imageBase64,
                        userId: userProvider.deviceId,
                        userName: userProvider.userName.isEmpty ? 'Explorer' : userProvider.userName,
                        levelId: 0, // No riddle level for manual identification
                        confidence: topMatch.probability,
                        description: description,
                      );
                      
                      debugPrint('✅ Treasure saved successfully to Firebase!');
                      
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close result dialog
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$displayName added to your collection and map!'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      debugPrint('❌ Error saving treasure to Firebase: $e');
                      debugPrint('Stack trace: $stackTrace');
                      
                      if (mounted) {
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close result dialog
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('❌ Unexpected error in add to collection: $e');
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unexpected error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Add to Collection'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        _image!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isAnalyzing)
                      Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text('Analyzing plant...'),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _getImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Retake Photo'),
                      ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => _getImage(ImageSource.camera),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Identify Plants',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Take a photo to identify any plant instantly using AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _openScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Open Live Scanner'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _getImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => _getImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose from Gallery'),
                    ),
                  ],
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Identify Scanner Screen - same implementation as AnimatedScannerScreen but for free scanning
class _IdentifyScannerScreen extends StatefulWidget {
  final Function(File image) onImageCaptured;

  const _IdentifyScannerScreen({required this.onImageCaptured});

  @override
  State<_IdentifyScannerScreen> createState() => _IdentifyScannerScreenState();
}

class _IdentifyScannerScreenState extends State<_IdentifyScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final file = File(imageFile.path);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onImageCaptured(file);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview - Full Screen
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 100,
                  height: _cameraController!.value.previewSize?.width ?? 100,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Overlay with scanning frame
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanFramePainter(),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Identify Plant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel with capture button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point camera at the plant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isCapturing ? Colors.grey : AppColors.primary)
                                .withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isCapturing
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isCapturing ? 'Capturing...' : 'Tap to identify',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live Scanner Screen for identify tab with camera preview (OLD - keep for reference if needed)
class _LiveScannerScreen extends StatefulWidget {
  final Function(File image) onImageCaptured;

  const _LiveScannerScreen({required this.onImageCaptured});

  @override
  State<_LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<_LiveScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final file = File(imageFile.path);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onImageCaptured(file);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview - Fill entire screen
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 1,
                    height: 1 / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Overlay with scanning frame - reduced opacity
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanFramePainter(),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Identify Plant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel with capture button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point camera at the plant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isCapturing ? Colors.grey : AppColors.primary)
                                .withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isCapturing
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isCapturing ? 'Capturing...' : 'Tap to identify',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scan frame overlay
class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Scan area dimensions
    final scanAreaWidth = size.width - 80;
    final scanAreaHeight = size.height * 0.5;
    final scanAreaTop = size.height * 0.2;
    final scanAreaLeft = 40.0;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
      const Radius.circular(20),
    );

    // Create path with hole for scan area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw frame corners
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight - cornerLength),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
