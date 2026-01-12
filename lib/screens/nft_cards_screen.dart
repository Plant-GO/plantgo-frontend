import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../blockchain/blockchain.dart';
import '../providers/wallet_provider.dart';
import '../providers/nft_provider.dart';
import '../providers/user_provider.dart';

/// NFT Cards Screen - Displays user's NFT collection
class NFTCardsScreen extends StatefulWidget {
  const NFTCardsScreen({super.key});

  @override
  State<NFTCardsScreen> createState() => _NFTCardsScreenState();
}

class _NFTCardsScreenState extends State<NFTCardsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNFTs();
  }

  Future<void> _loadNFTs() async {
    final walletProvider = context.read<WalletProvider>();
    final userProvider = context.read<UserProvider>();
    final nftProvider = context.read<NFTProvider>();

    // Use wallet address or device ID
    final address = walletProvider.walletAddress ?? 'device_${userProvider.deviceId}';
    await nftProvider.loadNFTs(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My NFT Cards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNFTs,
          ),
        ],
      ),
      body: Consumer<NFTProvider>(
        builder: (context, nftProvider, child) {
          if (nftProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (nftProvider.nfts.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNFTGrid(nftProvider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_bookmark_outlined,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No NFT Cards Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Discover plants to earn NFT cards!\nEach verified discovery mints a unique collectible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFTGrid(NFTProvider nftProvider) {
    return CustomScrollView(
      slivers: [
        // Stats Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.collections,
                  value: '${nftProvider.totalNFTs}',
                  label: 'Total NFTs',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.eco,
                  value: '${nftProvider.uniquePlants}',
                  label: 'Unique Plants',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.star,
                  value: '${nftProvider.legendaryCount}',
                  label: 'Legendary',
                ),
              ],
            ),
          ),
        ),

        // Rarity filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: CardRarity.values.map((rarity) {
                final count = nftProvider.nftsByRarity[rarity]?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Chip(
                  avatar: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(rarity.primaryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text('${rarity.displayName} ($count)'),
                  backgroundColor: Color(rarity.primaryColor).withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // NFT Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNFTCard(nftProvider.nfts[index]),
              childCount: nftProvider.nfts.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNFTCard(NFTCard nft) {
    return GestureDetector(
      onTap: () => _showNFTDetails(nft),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(nft.rarity.primaryColor),
              Color(nft.rarity.secondaryColor),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(nft.rarity.primaryColor).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _CardPatternPainter(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rarity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nft.rarity.rarityTier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Plant icon
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Plant name
                  Text(
                    nft.plantName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nft.rarity.displayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Legendary indicator
            if (nft.rarity.isLegendary)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.amber[300],
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNFTDetails(NFTCard nft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card preview
                    Center(
                      child: Container(
                        width: 200,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(nft.rarity.primaryColor),
                              Color(nft.rarity.secondaryColor),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(nft.rarity.primaryColor).withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (nft.rarity.isLegendary)
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber[300],
                                size: 40,
                              ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 50,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              nft.rarity.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Plant name
                    Text(
                      nft.plantName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    if (nft.scientificName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        nft.scientificName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Details
                    _buildDetailRow('Rarity', nft.rarity.displayName),
                    _buildDetailRow('Tier', nft.rarity.rarityTier),
                    if (nft.mintedAt != null)
                      _buildDetailRow(
                        'Minted',
                        '${nft.mintedAt!.day}/${nft.mintedAt!.month}/${nft.mintedAt!.year}',
                      ),
                    _buildDetailRow(
                      'NFT ID',
                      nft.nftMint.length > 16
                          ? '${nft.nftMint.substring(0, 8)}...${nft.nftMint.substring(nft.nftMint.length - 8)}'
                          : nft.nftMint,
                    ),

                    const SizedBox(height: 24),

                    // Rarity explanation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(nft.rarity.primaryColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRarityDescription(nft.rarity),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRarityDescription(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.genesisFragment:
        return 'Common card awarded for plant discoveries. The foundation of every collection!';
      case CardRarity.astralShard:
        return 'Rare card! Only 50 can be minted per plant species. You\'re among the first 50 discoverers!';
      case CardRarity.mythicCrest:
        return 'Epic card! Only 20 can be minted per plant species. A true collector\'s prize!';
      case CardRarity.primordialRelic:
        return 'Legendary! You were the first person to discover this known plant species on-chain!';
      case CardRarity.auroraSeed:
        return 'Ultra Legendary! You discovered a completely NEW species never seen before!';
      case CardRarity.ascendantSeal:
        return 'Mastery card awarded for winning a plant quiz. Proof of your botanical expertise!';
      case CardRarity.codexOfInsight:
        return 'Knowledge card awarded for quiz participation. Every bit of learning counts!';
    }
  }
}

/// Custom painter for card background pattern
class _CardPatternPainter extends CustomPainter {
  final Color color;

  _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.1),
      size.width * 0.3,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.9),
      size.width * 0.25,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
