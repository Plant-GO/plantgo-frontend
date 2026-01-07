import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Pill-shaped stat display (coins, leaves, XP)
class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor,
    this.backgroundColor,
  });

  /// Factory for coin display (golden coin icon)
  factory StatPill.coins(int amount) {
    return StatPill(
      icon: Icons.monetization_on_rounded,
      value: _formatNumber(amount),
      iconColor: const Color(0xFFFFD700),
    );
  }

  /// Factory for leaf display (green leaf icon)
  factory StatPill.leaves(int amount) {
    return StatPill(
      icon: Icons.eco_rounded,
      value: _formatNumber(amount),
      iconColor: AppColors.primary,
    );
  }

  static String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
