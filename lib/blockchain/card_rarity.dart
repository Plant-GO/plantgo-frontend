/// Card Rarity types matching the Solana program's CardRarityInstruction enum.
///
/// These must match the backend exactly for proper NFT minting.
/// Each card type has a corresponding u8 value (0-6) used in Borsh serialization.
enum CardRarity {
  /// Common card - default rarity
  genesisFragment,

  /// Rare card - awarded when rare count < 50
  astralShard,

  /// Epic card - awarded when epic count < 20
  mythicCrest,

  /// Mastery card - Quiz Winner reward
  ascendantSeal,

  /// Knowledge card - Quiz Participation reward
  codexOfInsight,

  /// First discovery of a known species on-chain
  primordialRelic,

  /// First ever discovery of a new species on-chain
  auroraSeed,
}

/// Extension methods for CardRarity
extension CardRarityExtension on CardRarity {
  /// Returns the u8 value for Borsh serialization (0-6)
  int toU8() => index;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case CardRarity.genesisFragment:
        return 'Genesis Fragment';
      case CardRarity.astralShard:
        return 'Astral Shard';
      case CardRarity.mythicCrest:
        return 'Mythic Crest';
      case CardRarity.ascendantSeal:
        return 'Ascendant Seal';
      case CardRarity.codexOfInsight:
        return 'Codex of Insight';
      case CardRarity.primordialRelic:
        return 'Primordial Relic';
      case CardRarity.auroraSeed:
        return 'Aurora Seed';
    }
  }

  /// Rarity tier for grouping (Common, Rare, Epic, Legendary, Mastery, Knowledge)
  String get rarityTier {
    switch (this) {
      case CardRarity.genesisFragment:
        return 'Common';
      case CardRarity.astralShard:
        return 'Rare';
      case CardRarity.mythicCrest:
        return 'Epic';
      case CardRarity.ascendantSeal:
        return 'Mastery';
      case CardRarity.codexOfInsight:
        return 'Knowledge';
      case CardRarity.primordialRelic:
      case CardRarity.auroraSeed:
        return 'Legendary';
    }
  }

  /// Primary gradient color for UI
  int get primaryColor {
    switch (this) {
      case CardRarity.genesisFragment:
        return 0xFF4A5568;
      case CardRarity.astralShard:
        return 0xFF2B6CB0;
      case CardRarity.mythicCrest:
        return 0xFF805AD5;
      case CardRarity.ascendantSeal:
        return 0xFFD69E2E;
      case CardRarity.codexOfInsight:
        return 0xFF319795;
      case CardRarity.primordialRelic:
        return 0xFFC53030;
      case CardRarity.auroraSeed:
        return 0xFFD53F8C;
    }
  }

  /// Secondary gradient color for UI
  int get secondaryColor {
    switch (this) {
      case CardRarity.genesisFragment:
        return 0xFF718096;
      case CardRarity.astralShard:
        return 0xFF4299E1;
      case CardRarity.mythicCrest:
        return 0xFF9F7AEA;
      case CardRarity.ascendantSeal:
        return 0xFFECC94B;
      case CardRarity.codexOfInsight:
        return 0xFF4FD1C5;
      case CardRarity.primordialRelic:
        return 0xFFFC8181;
      case CardRarity.auroraSeed:
        return 0xFFF687B3;
    }
  }

  /// Returns true if this is a legendary tier card
  bool get isLegendary =>
      this == CardRarity.primordialRelic || this == CardRarity.auroraSeed;

  /// Returns true if this is a quiz-related card
  bool get isQuizCard =>
      this == CardRarity.ascendantSeal || this == CardRarity.codexOfInsight;

  /// Parse from string (e.g., from API response)
  static CardRarity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'genesisfragment':
      case 'genesis_fragment':
        return CardRarity.genesisFragment;
      case 'astralshard':
      case 'astral_shard':
        return CardRarity.astralShard;
      case 'mythiccrest':
      case 'mythic_crest':
        return CardRarity.mythicCrest;
      case 'ascendantseal':
      case 'ascendant_seal':
        return CardRarity.ascendantSeal;
      case 'codexofinsight':
      case 'codex_of_insight':
        return CardRarity.codexOfInsight;
      case 'primordialrelic':
      case 'primordial_relic':
        return CardRarity.primordialRelic;
      case 'auroraseed':
      case 'aurora_seed':
        return CardRarity.auroraSeed;
      default:
        return CardRarity.genesisFragment;
    }
  }
}
