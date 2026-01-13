/// Tracks mint counts for a specific plant species.
///
/// This model matches the PlantCounter PDA data stored on-chain.
/// Used to determine rarity distribution for new mints.
class PlantCounter {
  /// Name of the plant this counter tracks
  final String plantName;

  /// Count of AuroraSeed cards minted (new species discovery)
  final int seedCount;

  /// Count of PrimordialRelic cards minted (first discovery)
  final int relicCount;

  /// Count of MythicCrest cards minted (Epic, max 20)
  final int epicCount;

  /// Count of AstralShard cards minted (Rare, max 50)
  final int rareCount;

  /// Count of GenesisFragment cards minted (Common, unlimited)
  final int commonCount;

  /// Count of AscendantSeal cards minted (Quiz Winner)
  final int masteryCount;

  /// Count of CodexOfInsight cards minted (Quiz Participation)
  final int codexCount;

  /// Wallet address of the first person to mint this plant (if any)
  final String? firstMinter;

  const PlantCounter({
    required this.plantName,
    this.seedCount = 0,
    this.relicCount = 0,
    this.epicCount = 0,
    this.rareCount = 0,
    this.commonCount = 0,
    this.masteryCount = 0,
    this.codexCount = 0,
    this.firstMinter,
  });

  /// Total number of NFTs minted for this plant
  int get totalMinted =>
      seedCount +
      relicCount +
      epicCount +
      rareCount +
      commonCount +
      masteryCount +
      codexCount;

  /// Check if this is the first time this plant is being minted
  bool get isFirstMint => totalMinted == 0;

  /// Check if epic cards are still available (< 20)
  bool get hasEpicAvailable => epicCount < 20;

  /// Check if rare cards are still available (< 50)
  bool get hasRareAvailable => rareCount < 50;

  /// Create from JSON (API response)
  factory PlantCounter.fromJson(Map<String, dynamic> json) {
    return PlantCounter(
      plantName: json['plant_name'] ?? json['plantName'] ?? '',
      seedCount: json['seed_count'] ?? json['seedCount'] ?? 0,
      relicCount: json['relic_count'] ?? json['relicCount'] ?? 0,
      epicCount: json['epic_count'] ?? json['epicCount'] ?? 0,
      rareCount: json['rare_count'] ?? json['rareCount'] ?? 0,
      commonCount: json['common_count'] ?? json['commonCount'] ?? 0,
      masteryCount: json['mastery_count'] ?? json['masteryCount'] ?? 0,
      codexCount: json['codex_count'] ?? json['codexCount'] ?? 0,
      firstMinter: json['first_minter'] ?? json['firstMinter'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'plant_name': plantName,
    'seed_count': seedCount,
    'relic_count': relicCount,
    'epic_count': epicCount,
    'rare_count': rareCount,
    'common_count': commonCount,
    'mastery_count': masteryCount,
    'codex_count': codexCount,
    'first_minter': firstMinter,
  };

  @override
  String toString() =>
      'PlantCounter(plantName: $plantName, total: $totalMinted)';
}
