import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/plant_id_service.dart';
import '../providers/user_provider.dart';
import '../models/user_progress.dart';
import '../models/plant.dart';
import 'collections_screen.dart';
import 'course_map_screen.dart';
import 'map_exploration_screen.dart';

/// Main navigation shell with bottom tab bar and floating map button
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start on Course tab

  final List<Widget> _screens = [
    const _GameScreen(),
    const CourseMapScreen(),
    const CollectionsScreen(),
    const _IdentifyScreen(),
  ];

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

/// Placeholder Game Screen
class _GameScreen extends StatelessWidget {
  const _GameScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              const Text(
                '🌿 Welcome to PlantGo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover plants in your area',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              // Feature cards
              _buildFeatureCard(
                icon: Icons.route_rounded,
                title: 'Course Mode',
                subtitle: 'Follow riddles to find plants',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.explore_rounded,
                title: 'Explore Mode',
                subtitle: 'Discover plants on the map',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.collections_rounded,
                title: 'My Collection',
                subtitle: 'View your discovered plants',
                color: const Color(0xFF9C7CF4),
              ),

              const Spacer(),

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
                        'Tap "Explore Map" to discover plants nearby!',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
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
    final plantName = topMatch.plantName;
    final probability = (topMatch.probability * 100).toStringAsFixed(1);
    final commonNames = topMatch.commonNames.take(3).join(', ');

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
              plantName,
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
            if (commonNames.isNotEmpty) ...[
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
                onPressed: () {
                  // Add to collection
                  final collectedPlant = CollectedPlant(
                    plantId: plantName.toLowerCase().replaceAll(' ', '_'),
                    name: plantName,
                    rarity: PlantRarity.common, // Default rarity
                    discoveredAt: DateTime.now(),
                    latitude: 0, // No location for camera discovery yet
                    longitude: 0,
                    isFirstFind: false,
                  );

                  context.read<UserProvider>().addToCollection(collectedPlant);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$plantName added to your collection!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
                      onPressed: () => _getImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Open Camera'),
                      style: ElevatedButton.styleFrom(
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
