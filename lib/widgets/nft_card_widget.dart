import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../blockchain/blockchain.dart';

/// A beautiful NFT card widget displaying plant card information.
/// 
/// Features rarity-based gradient backgrounds and optional shimmer effects.
class NFTCardWidget extends StatelessWidget {
  final NFTCard nftCard;
  final VoidCallback? onTap;
  final bool showShimmer;
  final bool compact;

  const NFTCardWidget({
    super.key,
    required this.nftCard,
    this.onTap,
    this.showShimmer = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(nftCard.rarity.primaryColor);
    final secondaryColor = Color(nftCard.rarity.secondaryColor);
    
    Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with rarity badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRarityBadge(),
                    if (!compact) _buildMintIndicator(),
                  ],
                ),
                
                // Plant Image
                Expanded(
                  child: Center(
                    child: _buildPlantImage(),
                  ),
                ),
                
                // Bottom section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant name
                    Text(
                      nftCard.plantName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (!compact && nftCard.scientificName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        nftCard.scientificName!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      _buildCardTypeName(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Add shimmer effect for legendary cards
    if (showShimmer && nftCard.rarity.isLegendary) {
      return Stack(
        children: [
          cardContent,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Shimmer.fromColors(
                baseColor: Colors.transparent,
                highlightColor: Colors.white.withOpacity(0.3),
                period: const Duration(seconds: 3),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardContent;
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nftCard.rarity.rarityTier.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMintIndicator() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.verified,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildPlantImage() {
    if (nftCard.imageUrl != null && nftCard.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          nftCard.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        ),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: compact ? 60 : 80,
      height: compact ? 60 : 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_florist,
        color: Colors.white.withOpacity(0.8),
        size: compact ? 32 : 48,
      ),
    );
  }

  Widget _buildCardTypeName() {
    return Row(
      children: [
        Icon(
          _getCardIcon(),
          color: Colors.white.withOpacity(0.9),
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            nftCard.rarity.displayName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getCardIcon() {
    switch (nftCard.rarity) {
      case CardRarity.genesisFragment:
        return Icons.auto_awesome_mosaic;
      case CardRarity.astralShard:
        return Icons.star;
      case CardRarity.mythicCrest:
        return Icons.shield;
      case CardRarity.ascendantSeal:
        return Icons.emoji_events;
      case CardRarity.codexOfInsight:
        return Icons.menu_book;
      case CardRarity.primordialRelic:
        return Icons.diamond;
      case CardRarity.auroraSeed:
        return Icons.auto_awesome;
    }
    // Fallback for safety
    return Icons.help_outline;
  }
}

/// Loading skeleton for NFT cards
class NFTCardSkeleton extends StatelessWidget {
  final bool compact;

  const NFTCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rarity badge skeleton
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              // Image skeleton
              Expanded(
                child: Center(
                  child: Container(
                    width: compact ? 60 : 80,
                    height: compact ? 60 : 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              // Title skeleton
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
