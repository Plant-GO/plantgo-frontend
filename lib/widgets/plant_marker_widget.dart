import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/plant.dart';
import '../models/plant_marker.dart';

/// Custom map marker widget for different plant types
class PlantMarkerWidget extends StatelessWidget {
  final PlantMarker marker;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlantMarkerWidget({
    super.key,
    required this.marker,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: _buildMarker());
  }

  Widget _buildMarker() {
    switch (marker.type) {
      case MarkerType.legendary:
        return _buildLegendaryMarker();
      case MarkerType.user:
        return _buildUserMarker();
      case MarkerType.target:
        return _buildTargetMarker();
      default:
        return _buildPlantMarker();
    }
  }

  Widget _buildPlantMarker() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getRarityColor().withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: _getRarityColor().withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Icon(Icons.eco_rounded, color: _getRarityColor(), size: 24),
      ),
    );
  }

  Widget _buildLegendaryMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glow effect
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.legendary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.legendary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.legendary.withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        // Pin
        CustomPaint(
          size: const Size(20, 12),
          painter: _PinPainter(color: AppColors.legendary),
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8),
        ],
      ),
    );
  }

  Widget _buildTargetMarker() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12),
        ],
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, color: Colors.white, size: 28),
      ),
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

/// Painter for marker pin
class _PinPainter extends CustomPainter {
  final Color color;

  _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
