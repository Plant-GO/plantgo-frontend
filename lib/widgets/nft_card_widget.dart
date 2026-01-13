import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../blockchain/blockchain.dart';

/// A beautiful NFT card widget displaying plant card information.
///
/// Features rarity-based gradient backgrounds, animated halos, and image display.
class NFTCardWidget extends StatefulWidget {
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
  State<NFTCardWidget> createState() => _NFTCardWidgetState();
}

class _NFTCardWidgetState extends State<NFTCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for halo effect
    _pulseController = AnimationController(
      duration: _getPulseDuration(),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for legendary cards
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotateController);

    // Start animations based on rarity
    if (widget.nftCard.rarity.isLegendary) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
    } else if (widget.nftCard.rarity == CardRarity.mythicCrest ||
        widget.nftCard.rarity == CardRarity.ascendantSeal) {
      _pulseController.repeat(reverse: true);
    }
  }

  Duration _getPulseDuration() {
    switch (widget.nftCard.rarity) {
      case CardRarity.auroraSeed:
      case CardRarity.primordialRelic:
        return const Duration(milliseconds: 1500);
      case CardRarity.mythicCrest:
      case CardRarity.ascendantSeal:
        return const Duration(milliseconds: 2000);
      default:
        return const Duration(milliseconds: 2500);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(widget.nftCard.rarity.primaryColor);
    final secondaryColor = Color(widget.nftCard.rarity.secondaryColor);
    final isLegendary = widget.nftCard.rarity.isLegendary;
    final isEpic =
        widget.nftCard.rarity == CardRarity.mythicCrest ||
        widget.nftCard.rarity == CardRarity.ascendantSeal;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              // Outer card glow - doesn't overlap adjacent cards
              BoxShadow(
                color: primaryColor.withOpacity(0.15 + (pulseValue * 0.1)),
                blurRadius: 8 + (pulseValue * 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background gradient
                _buildGradientBackground(primaryColor, secondaryColor),
                // Rotating sweep gradient for legendary
                if (isLegendary) _buildRotatingGradient(),
                // Card content
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(widget.compact ? 12.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: rarity badge + sparkles
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRarityBadge(),
                              if (isLegendary || isEpic) _buildSparkles(),
                            ],
                          ),
                          // Center: circular image with halo
                          Expanded(
                            child: Center(
                              child: _buildImageWithHalo(
                                primaryColor,
                                secondaryColor,
                                pulseValue,
                              ),
                            ),
                          ),
                          // Bottom: plant name and rarity
                          _buildBottomSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Shimmer overlay for legendary
                if (widget.showShimmer && isLegendary) _buildShimmerOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientBackground(Color primary, Color secondary) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, secondary],
          ),
        ),
      ),
    );
  }

  Widget _buildRotatingGradient() {
    return Positioned.fill(
      child: Transform.rotate(
        angle: _rotateAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithHalo(Color primary, Color secondary, double pulse) {
    final isLegendary = widget.nftCard.rarity.isLegendary;
    final isEpic =
        widget.nftCard.rarity == CardRarity.mythicCrest ||
        widget.nftCard.rarity == CardRarity.ascendantSeal;

    // Circle sizes based on compact mode
    final circleSize = widget.compact ? 70.0 : 100.0;
    final haloSize = circleSize + (isLegendary ? 30 : (isEpic ? 20 : 12));

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated pulsing halo for legendary/epic
        if (isLegendary || isEpic)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: haloSize + (pulse * 8),
            height: haloSize + (pulse * 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.3 + (pulse * 0.2)),
                  primary.withOpacity(0.2 + (pulse * 0.1)),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        // Outer ring
        Container(
          width: haloSize - 5,
          height: haloSize - 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: isLegendary ? 2 : 1,
            ),
          ),
        ),
        // Main circular image container
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(child: _buildImage()),
        ),
      ],
    );
  }

  Widget _buildImage() {
    // Try network image URL if available
    if (widget.nftCard.imageUrl != null &&
        widget.nftCard.imageUrl!.isNotEmpty &&
        widget.nftCard.imageUrl!.startsWith('http')) {
      return Image.network(
        widget.nftCard.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
      );
    }

    // Fallback to placeholder
    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.eco_rounded,
        color: Colors.white.withOpacity(0.8),
        size: widget.compact ? 36 : 48,
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        widget.nftCard.rarity.rarityTier,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.compact ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSparkles() {
    return Icon(
      Icons.auto_awesome,
      color: Colors.yellow[300],
      size: widget.compact ? 16 : 20,
    );
  }

  Widget _buildBottomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.nftCard.plantName,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.compact ? 14 : 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.nftCard.rarity.displayName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: widget.compact ? 11 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Shimmer.fromColors(
          baseColor: Colors.transparent,
          highlightColor: Colors.white.withOpacity(0.25),
          period: const Duration(seconds: 2),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
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
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rarity badge placeholder
              Container(
                width: 60,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              // Image circle placeholder
              Expanded(
                child: Center(
                  child: Container(
                    width: compact ? 70 : 100,
                    height: compact ? 70 : 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Title placeholder
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle placeholder
              Container(
                width: 80,
                height: 14,
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
