import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/verification.dart';
import '../services/verification_service.dart';
import '../services/nft_minting_service.dart';

/// Provider for community verification state management
class VerificationProvider extends ChangeNotifier {
  final VerificationService _service = VerificationService();
  final NFTMintingService _nftMintingService = NFTMintingService();

  /// Current user ID (set on initialization)
  String? _currentUserId;
  
  /// List of pending verifications to display
  List<Map<String, dynamic>> _pendingVerifications = [];
  List<Map<String, dynamic>> get pendingVerifications => _pendingVerifications;

  /// User's own submissions that are pending/verified/rejected
  List<Map<String, dynamic>> _userSubmissions = [];
  List<Map<String, dynamic>> get userSubmissions => _userSubmissions;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Voting state
  bool _isVoting = false;
  bool get isVoting => _isVoting;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Count of pending verifications
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  /// Stream subscription for pending count
  StreamSubscription? _countSubscription;

  /// Initialize the provider with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToPendingCount();
    loadPendingVerifications();
  }

  /// Listen to pending verification count for badge
  void _listenToPendingCount() {
    _countSubscription?.cancel();
    _countSubscription = _service
        .streamPendingCount(excludeUserId: _currentUserId)
        .listen((count) {
          _pendingCount = count;
          notifyListeners();
        });
  }

  /// Load pending verifications from Firestore
  Future<void> loadPendingVerifications() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingVerifications = await _service.getPendingVerifications(
        excludeUserId: _currentUserId,
      );
      debugPrint('✅ Loaded ${_pendingVerifications.length} pending verifications');
    } catch (e) {
      debugPrint('❌ Error loading pending verifications: $e');
      _errorMessage = 'Failed to load verifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's own submissions
  Future<void> loadUserSubmissions() async {
    if (_currentUserId == null) return;

    try {
      _userSubmissions = await _service.getUserSubmissions(_currentUserId!);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user submissions: $e');
    }
  }

  /// Submit a vote (upvote or downvote)
  /// If verification passes, triggers NFT minting for the original submitter
  Future<bool> submitVote({
    required String treasureId,
    required bool isUpvote,
    String? voterWalletAddress, // Wallet of the voter (for potential rewards)
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isVoting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.submitVote(
        treasureId: treasureId,
        oderId: _currentUserId!,
        isUpvote: isUpvote,
      );

      if (result != null) {
        // Remove from pending list if resolved or voted
        _pendingVerifications.removeWhere((item) => item['treasureId'] == treasureId);
        
        // If verified, trigger NFT minting for the original submitter
        if (result.status == VerificationStatus.verified) {
          debugPrint('🎴 Verification passed - triggering NFT mint for treasure $treasureId');
          await _mintNFTForVerifiedTreasure(treasureId);
        }
        
        _isVoting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to submit vote';
        _isVoting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting vote: $e');
      _errorMessage = 'Error: $e';
      _isVoting = false;
      notifyListeners();
      return false;
    }
  }

  /// Mint NFT for a verified treasure
  Future<void> _mintNFTForVerifiedTreasure(String treasureId) async {
    try {
      // Get treasure data to find original submitter
      final treasureData = _pendingVerifications.firstWhere(
        (item) => item['treasureId'] == treasureId,
        orElse: () => {},
      );

      if (treasureData.isEmpty) {
        // Fetch from service if not in local cache
        await _service.mintNFTForVerifiedTreasure(
          treasureId: treasureId,
          walletAddress: 'device_unknown', // Fallback, will be retrieved from treasure
        );
        return;
      }

      final treasure = treasureData['treasure'] as Map<String, dynamic>?;
      if (treasure == null) return;

      final userId = treasure['userId'] as String? ?? '';
      final walletAddress = 'device_$userId';

      await _service.mintNFTForVerifiedTreasure(
        treasureId: treasureId,
        walletAddress: walletAddress,
      );
      
      debugPrint('✅ NFT minting triggered for verified treasure $treasureId');
    } catch (e) {
      debugPrint('❌ Error minting NFT for verified treasure: $e');
    }
  }

  /// Initialize verification for a new treasure
  Future<TreasureVerification?> initializeVerification({
    required String treasureId,
    required double confidence,
  }) async {
    try {
      return await _service.initializeVerification(
        treasureId: treasureId,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('❌ Error initializing verification: $e');
      return null;
    }
  }

  /// Check if a treasure needs verification
  bool needsVerification(double confidence) {
    return VerificationService.needsVerification(confidence);
  }

  /// Get initial verification status based on confidence
  VerificationStatus getInitialStatus(double confidence) {
    return VerificationService.getInitialStatus(confidence);
  }

  /// Get verification for a specific treasure
  Future<TreasureVerification?> getVerification(String treasureId) async {
    return await _service.getVerification(treasureId);
  }

  /// Refresh pending verifications
  Future<void> refresh() async {
    await loadPendingVerifications();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countSubscription?.cancel();
    super.dispose();
  }
}
