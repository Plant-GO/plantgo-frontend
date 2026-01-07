import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/plant.dart';
import '../models/plant_marker.dart';

/// Bottom sheet preview card for a plant marker
class PlantPreviewCard extends StatelessWidget {
  final PlantMarker marker;
  final VoidCallback? onCollect;
  final VoidCallback? onBookmark;
  final VoidCallback? onInfo;

  const PlantPreviewCard({
    super.key,
    required this.marker,
    this.onCollect,
    this.onBookmark,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side - info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rarity badge
                _buildRarityBadge(),
                const SizedBox(height: 8),

                // Plant name
                Text(
                  marker.plantName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Location & distance
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${marker.locationName ?? "Unknown"} • ${marker.distanceMeters ?? 0}m away',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    _buildCollectButton(),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.bookmark_outline_rounded,
                      onTap: onBookmark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right side - image
          _buildPlantImage(),
        ],
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRarityColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getRarityColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            marker.rarity == PlantRarity.legendary
                ? Icons.auto_awesome_rounded
                : Icons.eco_rounded,
            size: 12,
            color: _getRarityColor(),
          ),
          const SizedBox(width: 4),
          Text(
            marker.rarity.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getRarityColor(),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectButton() {
    final isLegendary = marker.rarity == PlantRarity.legendary;

    return GestureDetector(
      onTap: onCollect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isLegendary ? AppColors.legendary : AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              isLegendary ? 'Collect Rare' : 'Collect',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPlantImage() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Icon(
                Icons.local_florist_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        // Info button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onInfo,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRarityColor() {
    switch (marker.rarity) {
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
}
