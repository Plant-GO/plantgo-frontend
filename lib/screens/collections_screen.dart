import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/plant.dart';
import '../models/user_progress.dart';
import '../providers/user_provider.dart';

/// Collections Screen - Displays all plants the user has collected
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final collection = userProvider.collection;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Collection',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${collection.length} plants discovered',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rarity filter chips
                  _buildRarityFilters(context, userProvider),
                ],
              ),
            ),

            // Collection list
            Expanded(
              child: collection.isEmpty
                  ? _buildEmptyState()
                  : _buildCollectionGrid(collection),
            ),

            // Space for FAB
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityFilters(BuildContext context, UserProvider userProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PlantRarity.values.map((rarity) {
          final count = userProvider.getRarityCount(rarity);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _RarityChip(rarity: rarity, count: count),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'No plants yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start exploring to discover plants',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionGrid(List<CollectedPlant> collection) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: collection.length,
      itemBuilder: (context, index) {
        return _CollectionCard(plant: collection[index]);
      },
    );
  }
}

/// Rarity filter chip
class _RarityChip extends StatelessWidget {
  final PlantRarity rarity;
  final int count;

  const _RarityChip({required this.rarity, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRarityColor(rarity).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRarityColor(rarity).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getRarityColor(rarity),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_getRarityName(rarity)} ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getRarityColor(rarity),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collection card for displaying a collected plant
class _CollectionCard extends StatelessWidget {
  final CollectedPlant plant;

  const _CollectionCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant image placeholder with rarity gradient
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getRarityColor(plant.rarity).withValues(alpha: 0.3),
                    _getRarityColor(plant.rarity).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 48,
                      color: _getRarityColor(plant.rarity),
                    ),
                  ),
                  // Rarity badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRarityColor(plant.rarity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRarityName(plant.rarity),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // First find badge
                  if (plant.isFirstFind)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'First!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Plant info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(plant.discoveredAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Helper function to get rarity color
Color _getRarityColor(PlantRarity rarity) {
  switch (rarity) {
    case PlantRarity.common:
      return const Color(0xFF78909C);
    case PlantRarity.uncommon:
      return const Color(0xFF4CAF50);
    case PlantRarity.rare:
      return const Color(0xFF2196F3);
    case PlantRarity.epic:
      return const Color(0xFF9C27B0);
    case PlantRarity.legendary:
      return const Color(0xFFFF9800);
  }
}

/// Helper function to get rarity name
String _getRarityName(PlantRarity rarity) {
  switch (rarity) {
    case PlantRarity.common:
      return 'Common';
    case PlantRarity.uncommon:
      return 'Uncommon';
    case PlantRarity.rare:
      return 'Rare';
    case PlantRarity.epic:
      return 'Epic';
    case PlantRarity.legendary:
      return 'Legendary';
  }
}
