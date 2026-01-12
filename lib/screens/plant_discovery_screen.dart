import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/plant.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../providers/map_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/nft_provider.dart';
import '../models/user_progress.dart';
import '../widgets/care_info_chip.dart';
import '../widgets/mint_progress_dialog.dart';

/// Plant Discovery Screen - Celebration screen when finding a plant
class PlantDiscoveryScreen extends StatefulWidget {
  final Plant plant;
  final int levelId;

  const PlantDiscoveryScreen({
    super.key,
    required this.plant,
    required this.levelId,
  });

  @override
  State<PlantDiscoveryScreen> createState() => _PlantDiscoveryScreenState();
}

class _PlantDiscoveryScreenState extends State<PlantDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGreen, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildDiscoveryBadge(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildPlantImage(),
                      const SizedBox(height: 24),
                      _buildPlantInfo(),
                      const SizedBox(height: 24),
                      _buildCareInfo(),
                      const SizedBox(height: 32),
                      _buildAddButton(context),
                      const SizedBox(height: 16),
                      _buildMintNFTButton(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.eco_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PlantGo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notification
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          // Profile
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'NEW DISCOVERY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'You found a',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Rare Specimen!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantImage() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Plant image container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EBE0),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.local_florist_rounded,
                size: 100,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
          ),

          // First Find badge
          Positioned(
            top: 16,
            right: -20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🏆', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    'FIRST FIND!',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfo() {
    return Column(
      children: [
        // Rarity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRarityColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.plant.rarityDisplay,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getRarityColor(),
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Plant name
        Text(
          widget.plant.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Habitat info
        Text(
          '${widget.plant.habitat} • ${widget.plant.region}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCareInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CareInfoChip.water(widget.plant.careInfo.water),
        const SizedBox(width: 12),
        CareInfoChip.light(widget.plant.careInfo.light),
        const SizedBox(width: 12),
        CareInfoChip.xp(widget.plant.xpReward),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _handleAddToCollection(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Add to Collection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMintNFTButton(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.phantomGradient,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9945FF).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _handleMintNFT(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    wallet.isConnected ? 'Mint as NFT' : 'Connect Wallet & Mint',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMintNFT(BuildContext context) async {
    final walletProvider = context.read<WalletProvider>();
    final nftProvider = context.read<NFTProvider>();
    
    // First ensure wallet is connected
    if (!walletProvider.isConnected) {
      final connected = await walletProvider.connect();
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
    
    // Check if user already owns this plant as NFT
    final alreadyOwns = await nftProvider.checkOwnership(
      walletAddress: walletProvider.walletAddress!,
      plantName: widget.plant.name,
    );
    
    if (alreadyOwns && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already own an NFT for this plant!'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    // Show minting dialog
    if (context.mounted) {
      final mintFuture = nftProvider.mintPlantDiscoveryNFT(
        walletAddress: walletProvider.walletAddress!,
        plantName: widget.plant.name,
        isNewSpecies: widget.plant.rarity == PlantRarity.legendary,
        scientificName: widget.plant.scientificName,
      );
      
      final result = await MintProgressDialog.show(
        context: context,
        plantName: widget.plant.name,
        mintFuture: mintFuture,
      );
      
      if (result?.success == true && context.mounted) {
        // Reload NFTs
        nftProvider.loadNFTs(walletProvider.walletAddress!);
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionIcon(Icons.share_outlined, 'Share'),
        const SizedBox(width: 24),
        _buildActionIcon(Icons.info_outline_rounded, 'Details'),
        const SizedBox(width: 24),
        _buildActionIcon(Icons.camera_alt_outlined, 'Snap'),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Color _getRarityColor() {
    switch (widget.plant.rarity) {
      case PlantRarity.legendary:
        return AppColors.rarityLegendary;
      case PlantRarity.epic:
        return AppColors.rarityEpic;
      case PlantRarity.rare:
        return AppColors.rarityRare;
      case PlantRarity.uncommon:
        return AppColors.rarityUncommon;
      case PlantRarity.common:
        return AppColors.rarityCommon;
    }
  }

  void _handleAddToCollection(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final courseProvider = context.read<CourseProvider>();
    final mapProvider = context.read<MapProvider>();

    // Add to collection
    await userProvider.addToCollection(
      CollectedPlant(
        plantId: widget.plant.id,
        name: widget.plant.name,
        rarity: widget.plant.rarity,
        discoveredAt: DateTime.now(),
        latitude: mapProvider.userLocation.latitude,
        longitude: mapProvider.userLocation.longitude,
        isFirstFind: true,
      ),
    );

    // Complete level
    courseProvider.completeLevel(widget.levelId, 3);
    await userProvider.completeLevel(widget.levelId, 100);

    // Add to global map
    await mapProvider.addPlantDiscovery(
      plantId: widget.plant.id,
      plantName: widget.plant.name,
      rarity: widget.plant.rarity,
      userId: userProvider.progress.userId,
    );

    // Navigate back to course map
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
