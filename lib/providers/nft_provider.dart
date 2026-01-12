import 'dart:async';
import 'package:flutter/foundation.dart';
import '../blockchain/blockchain.dart';
import '../services/nft_minting_service.dart';

/// Provider for NFT collection state and minting operations.
/// 
/// For MVP: Uses Firestore-backed NFT minting service
/// For Production: Switch to NFTApiService with backend server
class NFTProvider extends ChangeNotifier {
  final NFTMintingService _mintingService = NFTMintingService();

  /// User's owned NFTs
  List<NFTCard> _nfts = [];
  List<NFTCard> get nfts => List.unmodifiable(_nfts);

  /// Current wallet address
  String? _walletAddress;

  /// NFT stream subscription
  StreamSubscription? _nftSubscription;

  /// NFTs grouped by rarity
  Map<CardRarity, List<NFTCard>> get nftsByRarity {
    final map = <CardRarity, List<NFTCard>>{};
    for (final nft in _nfts) {
      map.putIfAbsent(nft.rarity, () => []).add(nft);
    }
    return map;
  }

  /// Total number of NFTs owned
  int get totalNFTs => _nfts.length;

  /// Unique plants discovered (by NFT)
  int get uniquePlants => _nfts.map((n) => n.plantName).toSet().length;

  /// Legendary NFTs (AuroraSeed + PrimordialRelic)
  int get legendaryCount => _nfts.where((n) => 
    n.rarity == CardRarity.auroraSeed || 
    n.rarity == CardRarity.primordialRelic
  ).length;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Minting state
  MintingState _mintingState = MintingState.idle;
  MintingState get mintingState => _mintingState;
  bool get isMinting => _mintingState == MintingState.minting;

  /// Last mint result
  MintResult? _lastMintResult;
  MintResult? get lastMintResult => _lastMintResult;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initialize with wallet address
  void initialize(String? walletAddress) {
    if (walletAddress == null) return;
    _walletAddress = walletAddress;
    _subscribeToNFTs();
  }

  /// Subscribe to real-time NFT updates
  void _subscribeToNFTs() {
    if (_walletAddress == null) return;
    
    _nftSubscription?.cancel();
    _nftSubscription = _mintingService
        .streamUserNFTs(_walletAddress!)
        .listen((nfts) {
          _nfts = nfts;
          notifyListeners();
        });
  }

  /// Load NFTs for a wallet address
  Future<void> loadNFTs(String walletAddress) async {
    if (_isLoading) return;

    debugPrint('📦 NFTProvider: Loading NFTs for wallet: $walletAddress');
    _walletAddress = walletAddress;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nfts = await _mintingService.getUserNFTs(walletAddress);
      debugPrint('📦 NFTProvider: Found ${_nfts.length} NFTs');
      _nfts.sort((a, b) => (b.mintedAt ?? DateTime.now())
          .compareTo(a.mintedAt ?? DateTime.now()));
      
      // Start listening for real-time updates
      _subscribeToNFTs();
    } catch (e) {
      debugPrint('❌ NFTProvider: Load NFTs error: $e');
      _errorMessage = 'Failed to load NFTs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mint a plant discovery NFT
  Future<MintResult> mintPlantDiscoveryNFT({
    required String walletAddress,
    required String plantName,
    required bool isNewSpecies,
    String? imageUrl,
    String? scientificName,
    String? treasureId,
  }) async {
    return _performMint(() => _mintingService.mintPlantDiscoveryNFT(
      walletAddress: walletAddress,
      plantName: plantName,
      isNewSpecies: isNewSpecies,
      imageUrl: imageUrl,
      scientificName: scientificName,
      treasureId: treasureId,
    ));
  }

  /// Mint a quiz NFT
  Future<MintResult> mintQuizNFT({
    required String walletAddress,
    required String plantName,
    required bool isWinner,
  }) async {
    return _performMint(() => _mintingService.mintQuizNFT(
      walletAddress: walletAddress,
      plantName: plantName,
      isWinner: isWinner,
    ));
  }

  /// Common minting logic
  Future<MintResult> _performMint(Future<MintResult> Function() mintFunction) async {
    if (isMinting) {
      return MintResult(
        success: false,
        message: 'Minting already in progress',
      );
    }

    _mintingState = MintingState.minting;
    _errorMessage = null;
    _lastMintResult = null;
    notifyListeners();

    try {
      final result = await mintFunction();
      _lastMintResult = result;

      if (result.success && result.nftCard != null) {
        // Add the new NFT to the collection
        _nfts.insert(0, result.nftCard!);
        _mintingState = MintingState.success;
      } else {
        _mintingState = MintingState.error;
        _errorMessage = result.message;
      }

      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('NFTProvider: Mint error: $e');
      _mintingState = MintingState.error;
      _errorMessage = e.toString();
      notifyListeners();

      return MintResult(
        success: false,
        message: 'Minting failed: $e',
      );
    }
  }

  /// Check if user already owns a specific plant card
  Future<bool> checkOwnership({
    required String walletAddress,
    required String plantName,
    CardRarity? rarity,
  }) async {
    try {
      return await _mintingService.ownsPlantNFT(walletAddress, plantName);
    } catch (e) {
      debugPrint('NFTProvider: Check ownership error: $e');
      return false;
    }
  }

  /// Get plant counter (mint statistics)
  Future<PlantCounter?> getPlantCounter(String plantName) async {
    try {
      return await _mintingService.getOrCreatePlantCounter(plantName);
    } catch (e) {
      debugPrint('NFTProvider: Get plant counter error: $e');
      return null;
    }
  }

  /// Check if plant is a new species
  Future<bool> isNewSpecies(String plantName) async {
    return await _mintingService.isNewSpecies(plantName);
  }

  /// Check if this is the first discovery
  Future<bool> isFirstDiscovery(String plantName) async {
    return await _mintingService.isFirstDiscovery(plantName);
  }

  /// Reset minting state
  void resetMintingState() {
    _mintingState = MintingState.idle;
    _lastMintResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all NFTs (e.g., on wallet disconnect)
  void clearNFTs() {
    _nfts = [];
    _lastMintResult = null;
    _errorMessage = null;
    _mintingState = MintingState.idle;
    notifyListeners();
  }

  /// Filter NFTs by rarity tier
  List<NFTCard> filterByRarityTier(String tier) {
    return _nfts.where((nft) => nft.rarity.rarityTier == tier).toList();
  }

  /// Get legendary NFTs only
  List<NFTCard> get legendaryNFTs =>
      _nfts.where((nft) => nft.rarity.isLegendary).toList();

  /// Get quiz-related NFTs only
  List<NFTCard> get quizNFTs =>
      _nfts.where((nft) => nft.rarity.isQuizCard).toList();

  @override
  void dispose() {
    _nftSubscription?.cancel();
    super.dispose();
  }
}

/// NFT minting states
enum MintingState {
  /// No minting in progress
  idle,
  
  /// Currently minting
  minting,
  
  /// Minting succeeded
  success,
  
  /// Minting failed
  error,
}
