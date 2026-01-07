import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Care info chip showing water, light, XP requirements
class CareInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const CareInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  /// Factory for water info
  factory CareInfoChip.water(String value) {
    return CareInfoChip(
      icon: Icons.water_drop_rounded,
      label: 'WATER',
      value: value,
      iconColor: Colors.blue,
    );
  }

  /// Factory for light info
  factory CareInfoChip.light(String value) {
    return CareInfoChip(
      icon: Icons.wb_sunny_rounded,
      label: 'LIGHT',
      value: value,
      iconColor: Colors.orange,
    );
  }

  /// Factory for XP reward
  factory CareInfoChip.xp(int value) {
    return CareInfoChip(
      icon: Icons.emoji_events_rounded,
      label: 'XP',
      value: '+$value',
      iconColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
