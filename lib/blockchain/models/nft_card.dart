import '../card_rarity.dart';

/// Represents an on-chain NFT card owned by a user.
///
/// This model matches the OwnershipRecord stored in the Solana program.
class NFTCard {
  /// Owner's wallet public key (base58 encoded)
  final String ownerWallet;

  /// Name of the plant this NFT represents
  final String plantName;

  /// Rarity/type of the card
  final CardRarity rarity;

  /// Mint public key of the NFT (base58 encoded)
  final String nftMint;

  /// URL to the plant image
  final String? imageUrl;

  /// When the NFT was minted
  final DateTime? mintedAt;

  /// Transaction signature of the mint
  final String? transactionSignature;

  /// Scientific name of the plant (optional)
  final String? scientificName;

  const NFTCard({
    required this.ownerWallet,
    required this.plantName,
    required this.rarity,
    required this.nftMint,
    this.imageUrl,
    this.mintedAt,
    this.transactionSignature,
    this.scientificName,
  });

  /// Create from JSON (API response)
  factory NFTCard.fromJson(Map<String, dynamic> json) {
    return NFTCard(
      ownerWallet: json['owner_wallet'] ?? json['ownerWallet'] ?? '',
      plantName: json['plant_name'] ?? json['plantName'] ?? '',
      rarity: CardRarityExtension.fromString(
        json['rarity'] ?? json['card_type'] ?? 'genesisFragment',
      ),
      nftMint: json['nft_mint'] ?? json['nftMint'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      mintedAt: json['minted_at'] != null
          ? DateTime.tryParse(json['minted_at'].toString())
          : json['mintedAt'] != null
          ? DateTime.tryParse(json['mintedAt'].toString())
          : null,
      transactionSignature:
          json['transaction_signature'] ??
          json['transactionSignature'] ??
          json['signature'],
      scientificName: json['scientific_name'] ?? json['scientificName'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'owner_wallet': ownerWallet,
    'plant_name': plantName,
    'rarity': rarity.name,
    'nft_mint': nftMint,
    'image_url': imageUrl,
    'minted_at': mintedAt?.toIso8601String(),
    'transaction_signature': transactionSignature,
    'scientific_name': scientificName,
  };

  /// Create a copy with updated fields
  NFTCard copyWith({
    String? ownerWallet,
    String? plantName,
    CardRarity? rarity,
    String? nftMint,
    String? imageUrl,
    DateTime? mintedAt,
    String? transactionSignature,
    String? scientificName,
  }) {
    return NFTCard(
      ownerWallet: ownerWallet ?? this.ownerWallet,
      plantName: plantName ?? this.plantName,
      rarity: rarity ?? this.rarity,
      nftMint: nftMint ?? this.nftMint,
      imageUrl: imageUrl ?? this.imageUrl,
      mintedAt: mintedAt ?? this.mintedAt,
      transactionSignature: transactionSignature ?? this.transactionSignature,
      scientificName: scientificName ?? this.scientificName,
    );
  }

  @override
  String toString() =>
      'NFTCard(plantName: $plantName, rarity: ${rarity.displayName})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NFTCard &&
          runtimeType == other.runtimeType &&
          nftMint == other.nftMint;

  @override
  int get hashCode => nftMint.hashCode;
}
