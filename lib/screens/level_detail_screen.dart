import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../blockchain/blockchain.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../services/treasure_service.dart';
import '../services/user_service.dart';
import '../services/nft_minting_service.dart';
import '../widgets/mint_progress_dialog.dart';
import 'animated_scanner_screen.dart';
import 'map_exploration_screen.dart';

/// Level Detail Screen - Shows riddle and scan button (no map)
class LevelDetailScreen extends StatefulWidget {
  const LevelDetailScreen({super.key});

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = false;
  bool _plantFound = false;
  Treasure? _foundTreasure;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);

    // Check if level is already completed
    _checkLevelCompletion();
  }

  Future<void> _checkLevelCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('deviceId') ?? 'unknown';

      if (userId != 'unknown') {
        final userService = UserService();
        final treasureService = TreasureService();

        // Get the level from context (need to wait for build)
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        final courseProvider = context.read<CourseProvider>();
        final level = courseProvider.selectedLevel;

        if (level != null) {
          // Check if level is completed
          final isCompleted = await userService.hasCompletedLevel(
            userId,
            level.id,
          );

          if (isCompleted) {
            // Get the treasure for this level
            final treasures = await treasureService.getUserTreasures(userId);
            final levelTreasure = treasures
                .where((t) => t.levelId == level.id)
                .firstOrNull;

            if (levelTreasure != null && mounted) {
              setState(() {
                _plantFound = true;
                _foundTreasure = levelTreasure;
              });
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error checking level completion: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAppBar(context, level),
                const SizedBox(height: 24),
                _buildLevelHeader(level),
                const SizedBox(height: 32),
                _buildRiddleCard(level),
                const SizedBox(height: 32),
                _buildPlantHint(level),
                const SizedBox(height: 40),
                _buildScanButton(context, level),
                const SizedBox(height: 24),
                if (_plantFound && _foundTreasure != null)
                  _buildFoundPlantInfo(),
                if (_plantFound && _foundTreasure != null)
                  const SizedBox(height: 24),
                _buildTip(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Level level) {
    return Row(
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
        const Spacer(),
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Level ${level.id}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelHeader(Level level) {
    return Column(
      children: [
        // Level icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 48)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          level.subtitle.isNotEmpty ? level.subtitle : level.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Solve the riddle and find the plant!',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRiddleCard(Level level) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'The Riddle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            level.riddle,
            style: const TextStyle(
              fontSize: 18,
              height: 1.6,
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          // Difficulty indicator
          Row(
            children: [
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: 16,
                color: _getDifficultyColor(level.clueStrength),
              ),
              const SizedBox(width: 6),
              Text(
                'Difficulty: ${level.clueStrength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getDifficultyColor(level.clueStrength),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildPlantHint(Level level) {
    final scientificName = _getScientificName(level.plantToFindId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.spa_rounded, size: 32, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scientificName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScientificName(String plantId) {
    switch (plantId.toLowerCase()) {
      case 'rose':
        return 'Rosa spp.';
      case 'marigold':
        return 'Tagetes erecta';
      case 'rhododendron':
        return 'Rhododendron arboreum';
      case 'guava':
        return 'Psidium guajava';
      case 'maize':
        return 'Zea mays';
      default:
        return 'Unknown species';
    }
  }

  String _getPlantEmoji(String plantId) {
    switch (plantId.toLowerCase()) {
      case 'rose':
        return '🌹';
      case 'marigold':
        return '🌼';
      case 'rhododendron':
        return '🌺';
      case 'guava':
        return '🍐';
      case 'maize':
        return '🌽';
      default:
        return '🌿';
    }
  }

  Widget _buildScanButton(BuildContext context, Level level) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_plantFound && _foundTreasure != null) {
                  // Navigate to map exploration screen with the found treasure
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapExplorationScreen(
                        highlightTreasureId: _foundTreasure!.id,
                      ),
                    ),
                  );
                } else {
                  _openScanner(context, level);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _plantFound ? Colors.green : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: (_plantFound ? Colors.green : AppColors.primary)
              .withValues(alpha: 0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _plantFound
                        ? Icons.explore_rounded
                        : Icons.camera_alt_rounded,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _plantFound ? 'Explore on Map' : 'Scan Plant',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFoundPlantInfo() {
    if (_foundTreasure == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Plant Discovered!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Plant image and info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _foundTreasure!.imageBase64.isNotEmpty
                    ? Image.memory(
                        _decodeBase64(_foundTreasure!.imageBase64),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.eco,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Plant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Common Name:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _foundTreasure!.commonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scientific Name:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _foundTreasure!.plantName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_foundTreasure!.confidence * 100).toStringAsFixed(0)}% confidence',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  dynamic _decodeBase64(String base64String) {
    // Remove data:image prefix if present
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',').last;
    }
    return Uri.parse(
      'data:image/jpeg;base64,$cleanBase64',
    ).data!.contentAsBytes();
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Point your camera at the plant and hold steady for best results!',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context, Level level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimatedScannerScreen(
          level: level,
          onScanComplete: (success, plantName, imagePath) async {
            if (success && imagePath != null) {
              await _saveTreasure(context, level, plantName!, imagePath);
            }
          },
        ),
      ),
    );
  }

  /// Compress image to ensure it's under Firestore's 1MB document limit
  Future<Uint8List?> _compressImage(File imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();
      print(
        '📷 Original image size: ${(originalBytes.length / 1024).toStringAsFixed(2)} KB',
      );

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
        print(
          '📦 Compressed to ${(compressedSize / 1024).toStringAsFixed(2)} KB at quality $quality',
        );

        // Base64 encoding increases size by ~33%, so we need compressed size < 500KB
        // to ensure base64 size < 670KB (well under 1MB Firestore limit)
        if (compressedSize < 500 * 1024) {
          break;
        }

        quality -= 15;
      }

      return compressedBytes;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  Future<void> _saveTreasure(
    BuildContext context,
    Level level,
    String plantName,
    String imagePath,
  ) async {
    setState(() => _isLoading = true);

    try {
      print('🌱 Starting to save treasure for $plantName');

      // Compress image to stay under Firestore's 1MB document limit
      final imageFile = File(imagePath);
      final compressedBytes = await _compressImage(imageFile);

      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      final imageBase64 = base64Encode(compressedBytes);
      print(
        '✅ Base64 encoded size: ${(imageBase64.length / 1024).toStringAsFixed(2)} KB',
      );

      // Get current location
      Position? position;
      try {
        print('📍 Getting current location...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('📍 Got location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('⚠️ Location error: $e');
        // Use default location if location fails
        position = null;
      }

      // Get user info - generate deviceId if not exists
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('deviceId');
      if (userId == null || userId.isEmpty) {
        userId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('deviceId', userId);
        print('🆔 Generated new deviceId: $userId');
      }
      final userName = prefs.getString('userName') ?? 'Anonymous';

      print('👤 User: $userName ($userId)');

      // Save treasure
      final treasureService = TreasureService();
      final userService = UserService();
      print('💾 Calling treasureService.saveTreasure...');

      final result = await treasureService.saveTreasure(
        plantName: plantName,
        commonName: plantName,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        imageBase64: imageBase64,
        userId: userId,
        userName: userName,
        levelId: level.id,
        confidence: 0.9,
        walletAddress:
            'device_$userId', // Use device-based wallet for NFT minting
      );

      final treasure = result.treasure;
      print('✅ Treasure saved successfully!');

      // Update user data in Firestore
      await userService.getOrCreateUser(userId, userName);
      await userService.addCoins(userId, 50);
      await userService.addLeaves(userId, 1);
      await userService.completeLevel(userId, level.id);
      await userService.addTreasureToUser(userId, treasure.id);
      print('✅ User data updated in Firestore');

      // Complete the level
      if (context.mounted) {
        print('🎯 Completing level ${level.id}');
        final courseProvider = context.read<CourseProvider>();
        debugPrint(
          '📊 Before completeLevel - Levels: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}',
        );
        courseProvider.completeLevel(level.id, 3);
        debugPrint(
          '📊 After completeLevel - Levels: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}',
        );

        context.read<UserProvider>().addCoins(50);
        context.read<UserProvider>().addLeaves(1);

        // Mark plant as found and store treasure
        setState(() {
          _plantFound = true;
          _foundTreasure = treasure;
        });

        // Show success dialog
        _showSuccessDialog(context, plantName, level);
      }
    } catch (e, stackTrace) {
      print('❌ Error saving treasure: $e');
      print('Stack trace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving treasure: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    String plantName,
    Level level,
  ) async {
    // Show the fancy MintProgressDialog with halo effect
    // Create a completed future since NFT was already minted during saveTreasure
    final completedMintFuture = Future<MintResult>.value(
      MintResult(
        success: true,
        nftCard: NFTCard(
          ownerWallet: 'device_${context.read<UserProvider>().deviceId}',
          plantName: plantName,
          rarity: CardRarity.auroraSeed, // Will show as legendary
          nftMint: 'auto_minted',
          mintedAt: DateTime.now(),
        ),
        message: 'NFT auto-minted!',
      ),
    );

    await MintProgressDialog.show(
      context: context,
      plantName: plantName,
      scientificName: null, // Level doesn't have this property
      imageBase64: _foundTreasure?.imageBase64,
      habitat: null, // Level doesn't have this property
      region: null, // Level doesn't have this property
      waterCare: null, // Level doesn't have this property
      lightCare: null, // Level doesn't have this property
      xpReward: 50, // Default XP reward
      isNewDiscovery: true,
      mintFuture: completedMintFuture,
    );

    if (context.mounted) {
      debugPrint('🔙 Navigating back to course map');
      final courseProvider = context.read<CourseProvider>();
      debugPrint(
        '📊 CourseProvider state before pop: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}',
      );
      Navigator.of(context).pop(); // Go back to course map
    }
  }

  Widget _buildRewardChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
