import 'package:flutter/material.dart';

/// PlantGo App Color Palette
/// Based on the design mockups featuring fresh greens, warm accents, and clean backgrounds
class AppColors {
  AppColors._();

  // Primary Green - The main brand color (bright, fresh green)
  static const Color primary = Color(0xFF6BC84D);
  static const Color primaryLight = Color(0xFF8FD974);
  static const Color primaryDark = Color(0xFF4CAF36);

  // Secondary - Golden/Legendary accent
  static const Color secondary = Color(0xFFFFB800);
  static const Color secondaryLight = Color(0xFFFFD54F);
  static const Color legendary = Color(0xFFFFB800);

  // Background colors
  static const Color background = Color(0xFFF8FAF5);
  static const Color backgroundGreen = Color(0xFFE8F5E1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7F2);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // State colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Level states
  static const Color levelLocked = Color(0xFFD1D5DB);
  static const Color levelActive = Color(0xFF6BC84D);
  static const Color levelCompleted = Color(0xFF22C55E);

  // Rarity colors
  static const Color rarityCommon = Color(0xFF9CA3AF);
  static const Color rarityUncommon = Color(0xFF22C55E);
  static const Color rarityRare = Color(0xFF3B82F6);
  static const Color rarityEpic = Color(0xFF8B5CF6);
  static const Color rarityLegendary = Color(0xFFFFB800);

  // UI Elements
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color shadow = Color(0x1A000000);

  // Gradient for backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGreen, background],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceVariant],
  );

  // NFT Card Rarity Colors (matching Solana program)
  static const Color nftCommon = Color(0xFF4A5568); // GenesisFragment
  static const Color nftRare = Color(0xFF2B6CB0); // AstralShard
  static const Color nftEpic = Color(0xFF805AD5); // MythicCrest
  static const Color nftMastery = Color(0xFFD69E2E); // AscendantSeal
  static const Color nftKnowledge = Color(0xFF319795); // CodexOfInsight
  static const Color nftLegendaryRed = Color(0xFFC53030); // PrimordialRelic
  static const Color nftLegendaryPink = Color(0xFFD53F8C); // AuroraSeed

  // Phantom Wallet Gradient
  static const LinearGradient phantomGradient = LinearGradient(
    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
  );
}
