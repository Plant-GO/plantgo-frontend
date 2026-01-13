import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/nft_provider.dart';
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
  String? _foundPlantName;
  String? _foundTreasureId;
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
          final isCompleted = await userService.hasCompletedLevel(userId, level.id);
          
          if (isCompleted) {
            // Get the treasure for this level
            final treasures = await treasureService.getUserTreasures(userId);
            final levelTreasure = treasures.where((t) => t.levelId == level.id).firstOrNull;
            
            if (levelTreasure != null && mounted) {
              setState(() {
                _plantFound = true;
                _foundPlantName = levelTreasure.commonName;
                _foundTreasureId = levelTreasure.id;
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
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
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
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.spa_rounded,
            size: 32,
            color: AppColors.secondary,
          ),
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
        onPressed: _isLoading ? null : () {
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
          shadowColor: (_plantFound ? Colors.green : AppColors.primary).withValues(alpha: 0.4),
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
                  Icon(_plantFound ? Icons.explore_rounded : Icons.camera_alt_rounded, size: 28),
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
                child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
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
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            child: const Icon(Icons.eco, size: 40, color: AppColors.primary),
                          );
                        },
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: const Icon(Icons.eco, size: 40, color: AppColors.primary),
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
                        const Icon(Icons.verified, size: 16, color: Colors.green),
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
    return Uri.parse('data:image/jpeg;base64,$cleanBase64').data!.contentAsBytes();
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
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 13,
              ),
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

  Future<void> _saveTreasure(
    BuildContext context,
    Level level,
    String plantName,
    String imagePath,
  ) async {
    setState(() => _isLoading = true);

    try {
      print('🌱 Starting to save treasure for $plantName');
      
      // Convert image to base64 with size limit
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      print('🌱 Image size: ${imageBytes.length} bytes');
      
      // Limit image size to 200KB by checking and warning
      if (imageBytes.length > 200000) {
        print('⚠️ Warning: Image size is large (${imageBytes.length} bytes). This might cause issues.');
      }
      
      final imageBase64 = base64Encode(imageBytes);
      print('🌱 Image converted to base64, length: ${imageBase64.length}');

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

      // Get user info from UserProvider (more reliable than SharedPreferences)
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.deviceId;
      final userName = userProvider.userName.isNotEmpty 
          ? userProvider.userName 
          : 'Anonymous';
      
      print('👤 User from Provider: $userName ($userId)');

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
        debugPrint('📊 Before completeLevel - Levels: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}');
        courseProvider.completeLevel(level.id, 3);
        debugPrint('📊 After completeLevel - Levels: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}');
        
        context.read<UserProvider>().addCoins(50);
        context.read<UserProvider>().addLeaves(1);

        // Mark plant as found and store treasure
        setState(() {
          _plantFound = true;
          _foundPlantName = plantName;
          _foundTreasureId = treasure.id;
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

  void _showSuccessDialog(BuildContext context, String plantName, Level level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SuccessDialogContent(
        plantName: plantName,
        level: level,
        treasure: _foundTreasure,
        onContinue: () {
          debugPrint('🔙 Navigating back to course map');
          final courseProvider = context.read<CourseProvider>();
          debugPrint('📊 CourseProvider state before pop: ${courseProvider.levels.map((l) => "${l.id}:${l.status}").join(", ")}');
          Navigator.of(dialogContext).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to course map
        },
      ),
    );
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Success dialog with NFT minting option
class _SuccessDialogContent extends StatefulWidget {
  final String plantName;
  final Level level;
  final Treasure? treasure;
  final VoidCallback onContinue;

  const _SuccessDialogContent({
    required this.plantName,
    required this.level,
    this.treasure,
    required this.onContinue,
  });

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent> {
  bool _isMinting = false;
  bool _hasMinted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎉 Congratulations!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You found: ${widget.plantName}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Level ${widget.level.id} Complete!',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRewardChip('🪙', '+50 coins'),
              const SizedBox(width: 16),
              _buildRewardChip('🍃', '+1 leaf'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        Column(
          children: [
            // NFT Mint Button
            if (!_hasMinted)
              Consumer<WalletProvider>(
                builder: (context, wallet, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isMinting ? null : () => _handleMintNFT(context, wallet),
                        icon: _isMinting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(
                          _isMinting
                              ? 'Minting...'
                              : wallet.isConnected
                                  ? 'Mint as NFT'
                                  : 'Connect Wallet & Mint',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            
            if (_hasMinted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withAlpha(77)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'NFT Minted! ✨',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMintNFT(BuildContext context, WalletProvider wallet) async {
    // First ensure wallet is connected
    if (!wallet.isConnected) {
      final connected = await wallet.connect();
      if (!connected) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please connect your wallet to mint NFTs'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isMinting = true);

    try {
      final nftProvider = context.read<NFTProvider>();
      
      // Check if user already owns this plant as NFT
      final alreadyOwns = await nftProvider.checkOwnership(
        walletAddress: wallet.walletAddress!,
        plantName: widget.plantName,
      );

      if (alreadyOwns && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already own an NFT for this plant!'),
            backgroundColor: Colors.blue,
          ),
        );
        setState(() => _isMinting = false);
        return;
      }

      // Check if this is a new species (never discovered before in database)
      final isNewSpecies = await NFTMintingService().isNewSpecies(widget.plantName);

      // Create the mint future
      final mintFuture = nftProvider.mintPlantDiscoveryNFT(
        walletAddress: wallet.walletAddress!,
        plantName: widget.plantName,
        isNewSpecies: isNewSpecies,
        scientificName: widget.treasure?.plantName,
      );

      // Show minting dialog
      if (context.mounted) {
        final result = await MintProgressDialog.show(
          context: context,
          plantName: widget.plantName,
          mintFuture: mintFuture,
        );

        if (result?.success == true) {
          setState(() {
            _hasMinted = true;
            _isMinting = false;
          });
          // Reload NFTs
          nftProvider.loadNFTs(wallet.walletAddress!);
        } else {
          setState(() => _isMinting = false);
        }
      }
    } catch (e) {
      debugPrint('Error minting NFT: $e');
      setState(() => _isMinting = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Minting failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

