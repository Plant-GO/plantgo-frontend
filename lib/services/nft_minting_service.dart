import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../blockchain/blockchain.dart';
import 'backend_url_provider.dart';

/// NFT Minting Service
///
/// This service handles:
/// 1. Local Firestore storage for NFT records (always)
/// 2. Real on-chain minting via backend server (when available)
/// 3. Fallback to simulated minting if backend unavailable
///
/// Flow:
/// 1. Determine rarity based on plant discovery order
/// 2. Call backend to mint real NFT on Solana
/// 3. Store NFT record in Firestore for app display
class NFTMintingService {
  static final NFTMintingService _instance = NFTMintingService._internal();
  factory NFTMintingService() => _instance;
  NFTMintingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _httpClient = http.Client();
  final _uuid = const Uuid();

  /// Whether to use real blockchain minting (true) or Firestore-only (false)
  static bool useRealBlockchain = true;

  // Collection names
  static const String _plantCountersCollection = 'plant_counters';
  static const String _nftCardsCollection = 'nft_cards';
  static const String _mintHistoryCollection = 'mint_history';

  // Rarity limits matching the Solana program
  static const int epicLimit = 20; // MythicCrest max per plant
  static const int rareLimit = 50; // AstralShard max per plant

  // ============ PlantCounter Operations ============

  /// Get or create PlantCounter for a plant
  Future<PlantCounter> getOrCreatePlantCounter(String plantName) async {
    final normalized = _normalizePlantName(plantName);
    final docRef = _firestore
        .collection(_plantCountersCollection)
        .doc(normalized);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        return PlantCounter.fromJson(snapshot.data()!);
      }

      // Create new counter
      final newCounter = PlantCounter(plantName: normalized);
      transaction.set(docRef, newCounter.toJson());
      return newCounter;
    });
  }

  /// Check if a plant is a new species (never discovered before)
  /// Returns true if no PlantCounter exists for this plant
  Future<bool> isNewSpecies(String plantName) async {
    final normalized = _normalizePlantName(plantName);
    final doc = await _firestore
        .collection(_plantCountersCollection)
        .doc(normalized)
        .get();

    final isNew = !doc.exists;
    debugPrint('🌱 isNewSpecies("$plantName"): $isNew');
    return isNew;
  }

  /// Check if this is the first discovery of a known plant by anyone
  Future<bool> isFirstDiscovery(String plantName) async {
    final counter = await getOrCreatePlantCounter(plantName);
    final isFirst = counter.totalMinted == 0;
    debugPrint('🥇 isFirstDiscovery("$plantName"): $isFirst');
    return isFirst;
  }

  // ============ NFT Minting ============

  /// Mint a Plant Discovery NFT
  ///
  /// This implements the same logic as the Solana program:
  /// - New species → AuroraSeed (legendary)
  /// - First discovery → PrimordialRelic (legendary)
  /// - Epic count < 20 → MythicCrest (epic)
  /// - Rare count < 50 → AstralShard (rare)
  /// - Otherwise → GenesisFragment (common)
  Future<MintResult> mintPlantDiscoveryNFT({
    required String walletAddress,
    required String plantName,
    required bool isNewSpecies,
    String? imageUrl,
    String? scientificName,
    String? treasureId,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint(
        '🎴 Starting mint for $plantName (isNewSpecies: $isNewSpecies)',
      );
      debugPrint('🎴 Wallet address for mint: $walletAddress');

      // Get or create plant counter
      final counter = await getOrCreatePlantCounter(plantName);

      // Determine card rarity based on Solana program logic
      CardRarity rarity;

      if (isNewSpecies && counter.seedCount == 0) {
        // New species - Aurora Seed (only first person gets this)
        rarity = CardRarity.auroraSeed;
        debugPrint('🌟 Minting AURORA SEED (new species)');
      } else if (counter.isFirstMint) {
        // First discovery of known plant - Primordial Relic
        rarity = CardRarity.primordialRelic;
        debugPrint('🏺 Minting PRIMORDIAL RELIC (first discovery)');
      } else if (counter.hasEpicAvailable) {
        // Epic still available
        rarity = CardRarity.mythicCrest;
        debugPrint(
          '💜 Minting MYTHIC CREST (epic: ${counter.epicCount + 1}/$epicLimit)',
        );
      } else if (counter.hasRareAvailable) {
        // Rare still available
        rarity = CardRarity.astralShard;
        debugPrint(
          '💙 Minting ASTRAL SHARD (rare: ${counter.rareCount + 1}/$rareLimit)',
        );
      } else {
        // Default to common
        rarity = CardRarity.genesisFragment;
        debugPrint('⬜ Minting GENESIS FRAGMENT (common)');
      }

      String nftMint;
      String transactionSignature;
      String? explorerUrl;

      // Try real blockchain minting first
      if (useRealBlockchain) {
        final backendResult = await _mintViaBackend(
          walletAddress: walletAddress,
          plantName: plantName,
          rarity: rarity.name,
          treasureId: treasureId,
          imageUrl: imageUrl,
          scientificName: scientificName,
          description: description,
          latitude: latitude,
          longitude: longitude,
        );

        if (backendResult != null && backendResult['success'] == true) {
          nftMint =
              backendResult['nftMint'] ?? 'nft_${_uuid.v4().substring(0, 8)}';
          transactionSignature = backendResult['signature'] ?? '';
          explorerUrl = backendResult['explorerUrl'];
          debugPrint('✅ Real NFT minted on Solana: $nftMint');
        } else {
          // Fallback to simulated mint
          debugPrint('⚠️ Backend unavailable, using simulated mint');
          nftMint = 'sim_${_uuid.v4().substring(0, 8)}';
          transactionSignature = 'sim_${_uuid.v4().substring(0, 16)}';
        }
      } else {
        // Simulated mint
        nftMint = 'sim_${_uuid.v4().substring(0, 8)}';
        transactionSignature = 'sim_${_uuid.v4().substring(0, 16)}';
      }

      // Create NFT card record
      final nftCard = NFTCard(
        ownerWallet: walletAddress,
        plantName: plantName,
        rarity: rarity,
        nftMint: nftMint,
        imageUrl: imageUrl,
        mintedAt: DateTime.now(),
        transactionSignature: transactionSignature,
        scientificName: scientificName,
      );

      // Save to Firestore (always - for app display)
      await _saveToFirestore(
        nftCard: nftCard,
        plantName: plantName,
        rarity: rarity,
        walletAddress: walletAddress,
        isNewSpecies: isNewSpecies,
        treasureId: treasureId,
        explorerUrl: explorerUrl,
      );

      debugPrint('✅ NFT Minted: ${rarity.displayName} for $plantName');

      return MintResult(
        success: true,
        nftCard: nftCard,
        message: 'Successfully minted ${rarity.displayName}!',
        explorerUrl: explorerUrl,
      );
    } catch (e) {
      debugPrint('❌ Mint failed: $e');
      return MintResult(success: false, error: 'Minting failed: $e');
    }
  }

  /// Mint NFT via backend server (real blockchain)
  Future<Map<String, dynamic>?> _mintViaBackend({
    required String walletAddress,
    required String plantName,
    required String rarity,
    String? treasureId,
    String? imageUrl,
    String? scientificName,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _httpClient
          .post(
            Uri.parse('$backendUrl${SolanaConfig.mintEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'walletAddress': walletAddress,
              'plantName': plantName,
              'rarity': rarity,
              'treasureId': treasureId,
              'imageUrl': imageUrl,
              'scientificName': scientificName,
              'description': description,
              if (latitude != null && longitude != null)
                'location': {'lat': latitude, 'lng': longitude},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
          'Backend mint failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Backend mint error: $e');
      return null;
    }
  }

  /// Save NFT record to Firestore
  Future<void> _saveToFirestore({
    required NFTCard nftCard,
    required String plantName,
    required CardRarity rarity,
    required String walletAddress,
    required bool isNewSpecies,
    String? treasureId,
    String? explorerUrl,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final counterRef = _firestore
          .collection(_plantCountersCollection)
          .doc(_normalizePlantName(plantName));

      final counterSnap = await transaction.get(counterRef);
      final currentCounter = counterSnap.exists
          ? PlantCounter.fromJson(counterSnap.data()!)
          : PlantCounter(plantName: _normalizePlantName(plantName));

      // Update counter based on rarity
      final updatedCounter = _incrementCounter(
        currentCounter,
        rarity,
        walletAddress,
      );
      transaction.set(counterRef, updatedCounter.toJson());

      // Create NFT card document
      final nftRef = _firestore
          .collection(_nftCardsCollection)
          .doc(nftCard.nftMint);
      transaction.set(nftRef, {
        ...nftCard.toJson(),
        'treasureId': treasureId,
        'explorerUrl': explorerUrl,
        'onChain': explorerUrl != null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to mint history
      final historyRef = _firestore.collection(_mintHistoryCollection).doc();
      transaction.set(historyRef, {
        'walletAddress': walletAddress,
        'plantName': plantName,
        'rarity': rarity.name,
        'nftMint': nftCard.nftMint,
        'isNewSpecies': isNewSpecies,
        'treasureId': treasureId,
        'explorerUrl': explorerUrl,
        'onChain': explorerUrl != null,
        'mintedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Mint a Quiz NFT
  Future<MintResult> mintQuizNFT({
    required String walletAddress,
    required String plantName,
    required bool isWinner,
  }) async {
    try {
      final rarity = isWinner
          ? CardRarity.ascendantSeal
          : CardRarity.codexOfInsight;

      debugPrint(
        '🎓 Minting Quiz NFT: ${rarity.displayName} (winner: $isWinner)',
      );

      final nftMint = 'quiz_${_uuid.v4().substring(0, 8)}';

      final nftCard = NFTCard(
        ownerWallet: walletAddress,
        plantName: plantName,
        rarity: rarity,
        nftMint: nftMint,
        mintedAt: DateTime.now(),
        transactionSignature: 'sim_${_uuid.v4().substring(0, 16)}',
      );

      // Update counter and create NFT
      await _firestore.runTransaction((transaction) async {
        final counterRef = _firestore
            .collection(_plantCountersCollection)
            .doc(_normalizePlantName(plantName));

        final counterSnap = await transaction.get(counterRef);
        final currentCounter = counterSnap.exists
            ? PlantCounter.fromJson(counterSnap.data()!)
            : PlantCounter(plantName: _normalizePlantName(plantName));

        final updatedCounter = _incrementCounter(
          currentCounter,
          rarity,
          walletAddress,
        );
        transaction.set(counterRef, updatedCounter.toJson());

        final nftRef = _firestore.collection(_nftCardsCollection).doc(nftMint);
        transaction.set(nftRef, {
          ...nftCard.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return MintResult(
        success: true,
        nftCard: nftCard,
        message: 'Successfully minted ${rarity.displayName}!',
      );
    } catch (e) {
      debugPrint('❌ Quiz mint failed: $e');
      return MintResult(success: false, error: 'Quiz minting failed: $e');
    }
  }

  // ============ Query NFTs ============

  /// Get all NFTs owned by a wallet
  Future<List<NFTCard>> getUserNFTs(String walletAddress) async {
    debugPrint('🔍 MintingService: Querying NFTs for wallet: $walletAddress');
    try {
      final snapshot = await _firestore
          .collection(_nftCardsCollection)
          .where('owner_wallet', isEqualTo: walletAddress)
          .orderBy('minted_at', descending: true)
          .get();

      debugPrint('🔍 MintingService: Found ${snapshot.docs.length} NFTs');
      for (final doc in snapshot.docs) {
        debugPrint('  📄 NFT: ${doc.id} - ${doc.data()['plant_name']}');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NFTCard.fromJson({...data, 'nft_mint': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting user NFTs: $e');
      return [];
    }
  }

  /// Stream user's NFT collection
  Stream<List<NFTCard>> streamUserNFTs(String walletAddress) {
    return _firestore
        .collection(_nftCardsCollection)
        .where('owner_wallet', isEqualTo: walletAddress)
        .orderBy('minted_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return NFTCard.fromJson({...data, 'nft_mint': doc.id});
          }).toList(),
        );
  }

  /// Check if user already owns a specific plant NFT
  Future<bool> ownsPlantNFT(String walletAddress, String plantName) async {
    final snapshot = await _firestore
        .collection(_nftCardsCollection)
        .where('owner_wallet', isEqualTo: walletAddress)
        .where('plant_name', isEqualTo: _normalizePlantName(plantName))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get total NFTs minted count
  Future<int> getTotalNFTsMinted() async {
    final snapshot = await _firestore
        .collection(_nftCardsCollection)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get rarity distribution for a plant
  Future<Map<CardRarity, int>> getPlantRarityDistribution(
    String plantName,
  ) async {
    final counter = await getOrCreatePlantCounter(plantName);
    return {
      CardRarity.genesisFragment: counter.commonCount,
      CardRarity.astralShard: counter.rareCount,
      CardRarity.mythicCrest: counter.epicCount,
      CardRarity.primordialRelic: counter.relicCount,
      CardRarity.auroraSeed: counter.seedCount,
      CardRarity.ascendantSeal: counter.masteryCount,
      CardRarity.codexOfInsight: counter.codexCount,
    };
  }

  // ============ Helper Methods ============

  /// Normalize plant name for consistent storage
  String _normalizePlantName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Increment the appropriate counter for a rarity
  PlantCounter _incrementCounter(
    PlantCounter counter,
    CardRarity rarity,
    String minterWallet,
  ) {
    switch (rarity) {
      case CardRarity.genesisFragment:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount + 1,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.astralShard:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount + 1,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.mythicCrest:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount + 1,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.primordialRelic:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount + 1,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.auroraSeed:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount + 1,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.ascendantSeal:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount + 1,
          codexCount: counter.codexCount,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
      case CardRarity.codexOfInsight:
        return PlantCounter(
          plantName: counter.plantName,
          seedCount: counter.seedCount,
          relicCount: counter.relicCount,
          epicCount: counter.epicCount,
          rareCount: counter.rareCount,
          commonCount: counter.commonCount,
          masteryCount: counter.masteryCount,
          codexCount: counter.codexCount + 1,
          firstMinter: counter.firstMinter ?? minterWallet,
        );
    }
  }
}

/// Result from an NFT minting operation
class MintResult {
  final bool success;
  final NFTCard? nftCard;
  final String message;
  final String? error;
  final String? transactionSignature;
  final String? _explorerUrl;

  MintResult({
    required this.success,
    this.nftCard,
    String? message,
    this.error,
    this.transactionSignature,
    String? explorerUrl,
  }) : message =
           message ?? (success ? 'Mint successful' : error ?? 'Mint failed'),
       _explorerUrl = explorerUrl;

  /// Get Solana Explorer URL for the transaction
  String? get explorerUrl {
    if (_explorerUrl != null) return _explorerUrl;
    if (transactionSignature == null) return null;
    if (transactionSignature!.startsWith('sim_')) return null; // Simulated
    return SolanaConfig.getExplorerUrl(transactionSignature!);
  }

  /// Whether this NFT was minted on-chain (vs simulated)
  bool get isOnChain =>
      _explorerUrl != null ||
      (transactionSignature != null &&
          !transactionSignature!.startsWith('sim_'));
}
