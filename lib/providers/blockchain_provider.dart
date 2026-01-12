import 'dart:async';
import 'package:flutter/foundation.dart';
import '../blockchain/blockchain.dart';
import '../services/nft_minting_service.dart';
import '../services/wallet_service.dart';
import '../services/solana_rpc_service.dart';

/// Provider for blockchain/NFT state management
/// 
/// Handles:
/// - Wallet connection state
/// - NFT collection
/// - Minting operations
/// - New species detection
class BlockchainProvider extends ChangeNotifier {
  final NFTMintingService _mintingService = NFTMintingService();
  final WalletService _walletService = WalletService();
  final SolanaRpcService _rpcService = SolanaRpcService();

  // ============ State ============

  /// Connected wallet address (null if not connected)
  String? _walletAddress;
  String? get walletAddress => _walletAddress;
  bool get isWalletConnected => _walletAddress != null;

  /// User's NFT collection
  List<NFTCard> _nftCollection = [];
  List<NFTCard> get nftCollection => _nftCollection;

  /// Loading states
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isMinting = false;
  bool get isMinting => _isMinting;

  bool _isLoadingNFTs = false;
  bool get isLoadingNFTs => _isLoadingNFTs;

  /// Wallet SOL balance
  double _balance = 0;
  double get balance => _balance;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Last minted NFT (for showing success dialog)
  NFTCard? _lastMintedNFT;
  NFTCard? get lastMintedNFT => _lastMintedNFT;

  /// Stream subscription for NFT updates
  StreamSubscription? _nftSubscription;

  // ============ Initialization ============

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      await _walletService.initialize();
      
      // Check for cached wallet address
      final cachedAddress = await _walletService.getCachedWalletAddress();
      if (cachedAddress != null) {
        _walletAddress = cachedAddress;
        await _refreshBalance();
        _subscribeToNFTs();
        notifyListeners();
      }

      debugPrint('✅ BlockchainProvider initialized');
    } catch (e) {
      debugPrint('❌ BlockchainProvider initialization error: $e');
    }
  }

  /// Set device ID as fallback "wallet" for users without Phantom
  void setDeviceAsWallet(String deviceId) {
    if (_walletAddress == null) {
      _walletAddress = 'device_$deviceId';
      _subscribeToNFTs();
      notifyListeners();
      debugPrint('📱 Using device ID as wallet: $_walletAddress');
    }
  }

  // ============ Wallet Operations ============

  /// Connect to Phantom wallet
  Future<bool> connectWallet() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final address = await _walletService.connect();
      
      if (address != null) {
        _walletAddress = address;
        await _refreshBalance();
        _subscribeToNFTs();
        debugPrint('✅ Wallet connected: $address');
        
        _isConnecting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to connect wallet';
        _isConnecting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect wallet
  Future<void> disconnectWallet() async {
    await _walletService.disconnect();
    _walletAddress = null;
    _nftCollection = [];
    _balance = 0;
    _nftSubscription?.cancel();
    notifyListeners();
    debugPrint('👋 Wallet disconnected');
  }

  /// Refresh wallet balance
  Future<void> _refreshBalance() async {
    if (_walletAddress == null || _walletAddress!.startsWith('device_')) {
      return;
    }

    try {
      _balance = await _rpcService.getBalance(_walletAddress!);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing balance: $e');
    }
  }

  /// Request airdrop (devnet only)
  Future<bool> requestAirdrop({double amount = 1.0}) async {
    if (_walletAddress == null || !SolanaConfig.isDevnet) {
      return false;
    }

    try {
      final signature = await _rpcService.requestAirdrop(
        _walletAddress!,
        amount: amount,
      );
      
      if (signature != null) {
        await _rpcService.confirmTransaction(signature);
        await _refreshBalance();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Airdrop failed: $e');
      return false;
    }
  }

  // ============ NFT Operations ============

  /// Subscribe to NFT collection updates
  void _subscribeToNFTs() {
    if (_walletAddress == null) return;

    _nftSubscription?.cancel();
    _nftSubscription = _mintingService
        .streamUserNFTs(_walletAddress!)
        .listen((nfts) {
          _nftCollection = nfts;
          notifyListeners();
        });
  }

  /// Load NFT collection
  Future<void> loadNFTCollection() async {
    if (_walletAddress == null) return;

    _isLoadingNFTs = true;
    notifyListeners();

    try {
      _nftCollection = await _mintingService.getUserNFTs(_walletAddress!);
      debugPrint('✅ Loaded ${_nftCollection.length} NFTs');
    } catch (e) {
      debugPrint('❌ Error loading NFTs: $e');
      _errorMessage = 'Failed to load NFT collection';
    } finally {
      _isLoadingNFTs = false;
      notifyListeners();
    }
  }

  // ============ Minting Operations ============

  /// Check if a plant is a new species
  Future<bool> isNewSpecies(String plantName) async {
    return await _mintingService.isNewSpecies(plantName);
  }

  /// Check if this is the first discovery
  Future<bool> isFirstDiscovery(String plantName) async {
    return await _mintingService.isFirstDiscovery(plantName);
  }

  /// Mint NFT for plant discovery
  /// 
  /// Called when:
  /// 1. Treasure is auto-verified (confidence >= 60%)
  /// 2. Community verification passes (4+ upvotes)
  Future<MintResult> mintPlantNFT({
    required String plantName,
    String? imageUrl,
    String? scientificName,
    String? treasureId,
  }) async {
    if (_walletAddress == null) {
      return MintResult(
        success: false,
        error: 'No wallet connected',
      );
    }

    _isMinting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if this is a new species
      final isNew = await _mintingService.isNewSpecies(plantName);

      // Mint the NFT
      final result = await _mintingService.mintPlantDiscoveryNFT(
        walletAddress: _walletAddress!,
        plantName: plantName,
        isNewSpecies: isNew,
        imageUrl: imageUrl,
        scientificName: scientificName,
        treasureId: treasureId,
      );

      if (result.success && result.nftCard != null) {
        _lastMintedNFT = result.nftCard;
        debugPrint('🎴 Minted: ${result.nftCard!.rarity.displayName}');
      }

      _isMinting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Minting failed: $e';
      _isMinting = false;
      notifyListeners();
      return MintResult(
        success: false,
        error: 'Minting failed: $e',
      );
    }
  }

  /// Mint quiz participation NFT
  Future<MintResult> mintQuizNFT({
    required String plantName,
    required bool isWinner,
  }) async {
    if (_walletAddress == null) {
      return MintResult(
        success: false,
        error: 'No wallet connected',
      );
    }

    _isMinting = true;
    notifyListeners();

    try {
      final result = await _mintingService.mintQuizNFT(
        walletAddress: _walletAddress!,
        plantName: plantName,
        isWinner: isWinner,
      );

      if (result.success && result.nftCard != null) {
        _lastMintedNFT = result.nftCard;
      }

      _isMinting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isMinting = false;
      notifyListeners();
      return MintResult(
        success: false,
        error: 'Quiz minting failed: $e',
      );
    }
  }

  /// Clear last minted NFT (after showing success dialog)
  void clearLastMinted() {
    _lastMintedNFT = null;
    notifyListeners();
  }

  // ============ Statistics ============

  /// Get NFT counts by rarity
  Map<CardRarity, int> getNFTCountsByRarity() {
    final counts = <CardRarity, int>{};
    for (final rarity in CardRarity.values) {
      counts[rarity] = _nftCollection.where((n) => n.rarity == rarity).length;
    }
    return counts;
  }

  /// Get unique plants discovered
  int get uniquePlantsDiscovered {
    return _nftCollection.map((n) => n.plantName).toSet().length;
  }

  /// Get legendary NFT count
  int get legendaryCount {
    return _nftCollection.where((n) => 
      n.rarity == CardRarity.auroraSeed || 
      n.rarity == CardRarity.primordialRelic
    ).length;
  }

  // ============ Cleanup ============

  @override
  void dispose() {
    _nftSubscription?.cancel();
    _walletService.dispose();
    super.dispose();
  }
}
