import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/verification.dart';
import '../services/verification_service.dart';
import '../services/nft_minting_service.dart';

/// Provider for community verification state management
class VerificationProvider extends ChangeNotifier {
  final VerificationService _service = VerificationService();

  /// Current user ID (set on initialization)
  String? _currentUserId;

  /// List of pending verifications to display
  List<Map<String, dynamic>> _pendingVerifications = [];
  List<Map<String, dynamic>> get pendingVerifications => _pendingVerifications;

  /// User's own submissions that are pending/verified/rejected
  List<Map<String, dynamic>> _userSubmissions = [];
  List<Map<String, dynamic>> get userSubmissions => _userSubmissions;

  /// Items the user has voted on
  List<Map<String, dynamic>> _userVotes = [];
  List<Map<String, dynamic>> get userVotes => _userVotes;

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

  /// Stream subscription for pending verifications
  StreamSubscription? _pendingSubscription;

  /// Stream subscription for user submissions
  StreamSubscription? _submissionsSubscription;

  /// Stream subscription for user votes
  StreamSubscription? _votesSubscription;

  /// Initialize the provider with user ID
  void initialize(String userId) {
    debugPrint('🎯 Initializing VerificationProvider with userId: $userId');
    _currentUserId = userId;
    _listenToPendingCount();
    _listenToPendingVerifications();
    _listenToUserSubmissions();
    _listenToUserVotes();
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

  /// Listen to pending verifications stream
  void _listenToPendingVerifications() {
    if (_currentUserId == null) return;

    _pendingSubscription?.cancel();
    _pendingSubscription = _service
        .streamPendingVerifications(excludeUserId: _currentUserId)
        .listen(
          (verifications) {
            _pendingVerifications = verifications;
            debugPrint(
              '🔄 Pending verifications updated: ${verifications.length} items',
            );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Error in pending verifications stream: $error');
          },
        );
  }

  /// Listen to user submissions stream
  void _listenToUserSubmissions() {
    if (_currentUserId == null) return;

    _submissionsSubscription?.cancel();
    _submissionsSubscription = _service
        .streamUserSubmissions(_currentUserId!)
        .listen(
          (submissions) {
            _userSubmissions = submissions;
            debugPrint(
              '🔄 User submissions updated: ${submissions.length} items',
            );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Error in user submissions stream: $error');
          },
        );
  }

  /// Listen to user votes stream
  void _listenToUserVotes() {
    if (_currentUserId == null) return;

    _votesSubscription?.cancel();
    _votesSubscription = _service
        .streamUserVotes(_currentUserId!)
        .listen(
          (votes) {
            _userVotes = votes;
            debugPrint('🔄 User votes updated: ${votes.length} items');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Error in user votes stream: $error');
          },
        );
  }

  /// Mark all pending verifications as seen (clears badge)
  Future<void> markAllAsSeen() async {
    await _service.markAllAsSeen(_currentUserId);
    // Force immediate update by triggering a manual recount
    _pendingCount = 0;
    notifyListeners();
    debugPrint('✅ Marked all verifications as seen, badge cleared');
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
      debugPrint(
        '✅ Loaded ${_pendingVerifications.length} pending verifications',
      );
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
        _pendingVerifications.removeWhere(
          (item) => item['treasureId'] == treasureId,
        );

        // If verified, trigger NFT minting for the original submitter
        if (result.status == VerificationStatus.verified) {
          debugPrint(
            '🎴 Verification passed - triggering NFT mint for treasure $treasureId',
          );
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
          walletAddress:
              'device_unknown', // Fallback, will be retrieved from treasure
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
    _pendingSubscription?.cancel();
    _submissionsSubscription?.cancel();
    _votesSubscription?.cancel();
    super.dispose();
  }
}
