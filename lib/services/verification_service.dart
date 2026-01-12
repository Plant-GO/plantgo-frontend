import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../blockchain/blockchain.dart';
import '../models/verification.dart';
import 'nft_minting_service.dart';

/// Service for managing plant verification in Firestore
/// 
/// Verification thresholds:
/// - Confidence >= 60%: Auto-verified
/// - Confidence < 60%: Goes to community verification
/// - 4+ upvotes: Verified
/// - 2+ downvotes: Rejected
class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NFTMintingService _nftMintingService = NFTMintingService();
  
  static const String _verificationsCollection = 'verifications';
  static const String _treasuresCollection = 'treasures';
  
  // Threshold constants
  static const double confidenceThreshold = 0.60; // 60%
  static const int upvotesRequired = 4;
  static const int downvotesRequired = 2;

  /// Determine if a treasure needs community verification
  static bool needsVerification(double confidence) {
    return confidence < confidenceThreshold;
  }

  /// Get verification status based on confidence
  static VerificationStatus getInitialStatus(double confidence) {
    return confidence >= confidenceThreshold 
        ? VerificationStatus.autoVerified 
        : VerificationStatus.pending;
  }

  /// Create or update verification record for a treasure
  Future<TreasureVerification> initializeVerification({
    required String treasureId,
    required double confidence,
  }) async {
    final status = getInitialStatus(confidence);
    
    final verification = TreasureVerification(
      treasureId: treasureId,
      upvotes: 0,
      downvotes: 0,
      voterIds: [],
      status: status,
      verifiedAt: status == VerificationStatus.autoVerified ? DateTime.now() : null,
    );

    await _firestore
        .collection(_verificationsCollection)
        .doc(treasureId)
        .set(verification.toFirestore());

    // Also update the treasure document with verification status
    await _firestore
        .collection(_treasuresCollection)
        .doc(treasureId)
        .update({
          'verificationStatus': status.name,
        });

    debugPrint('✅ Verification initialized for $treasureId: ${status.name}');
    return verification;
  }

  /// Get verification data for a treasure
  Future<TreasureVerification?> getVerification(String treasureId) async {
    try {
      final doc = await _firestore
          .collection(_verificationsCollection)
          .doc(treasureId)
          .get();

      if (doc.exists) {
        return TreasureVerification.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting verification: $e');
      return null;
    }
  }

  /// Submit a vote for a treasure
  /// Returns the updated verification status
  Future<TreasureVerification?> submitVote({
    required String treasureId,
    required String oderId,
    required bool isUpvote,
  }) async {
    try {
      final docRef = _firestore.collection(_verificationsCollection).doc(treasureId);
      
      return await _firestore.runTransaction<TreasureVerification?>((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          debugPrint('❌ Verification record not found for $treasureId');
          return null;
        }

        final currentVerification = TreasureVerification.fromFirestore(snapshot);
        
        // Check if user already voted
        if (currentVerification.hasVoted(oderId)) {
          debugPrint('⚠️ User $oderId already voted on $treasureId');
          return currentVerification;
        }

        // Check if already resolved
        if (currentVerification.status != VerificationStatus.pending) {
          debugPrint('⚠️ Verification already resolved: ${currentVerification.status.name}');
          return currentVerification;
        }

        // Calculate new votes
        final newUpvotes = isUpvote ? currentVerification.upvotes + 1 : currentVerification.upvotes;
        final newDownvotes = !isUpvote ? currentVerification.downvotes + 1 : currentVerification.downvotes;
        final newVoterIds = [...currentVerification.voterIds, oderId];

        // Determine new status
        VerificationStatus newStatus = VerificationStatus.pending;
        DateTime? verifiedAt;
        String? verifiedBy;

        if (newUpvotes >= upvotesRequired) {
          newStatus = VerificationStatus.verified;
          verifiedAt = DateTime.now();
          verifiedBy = oderId;
          debugPrint('🏆 Treasure $treasureId VERIFIED by community!');
        } else if (newDownvotes >= downvotesRequired) {
          newStatus = VerificationStatus.rejected;
          verifiedAt = DateTime.now();
          verifiedBy = oderId;
          debugPrint('❌ Treasure $treasureId REJECTED by community');
        }

        final updatedVerification = currentVerification.copyWith(
          upvotes: newUpvotes,
          downvotes: newDownvotes,
          voterIds: newVoterIds,
          status: newStatus,
          verifiedAt: verifiedAt,
          verifiedBy: verifiedBy,
        );

        // Update verification document
        transaction.update(docRef, updatedVerification.toFirestore());

        // Update treasure document status
        transaction.update(
          _firestore.collection(_treasuresCollection).doc(treasureId),
          {
            'verificationStatus': newStatus.name,
            if (newStatus == VerificationStatus.verified)
              'nftPending': true, // Mark for NFT minting
          },
        );

        debugPrint('✅ Vote submitted: ${isUpvote ? "👍" : "👎"} for $treasureId');
        return updatedVerification;
      });
    } catch (e) {
      debugPrint('❌ Error submitting vote: $e');
      return null;
    }
  }

  /// Mint NFT after community verification
  /// Called separately after the transaction completes
  Future<void> mintNFTForVerifiedTreasure({
    required String treasureId,
    required String walletAddress,
  }) async {
    try {
      // Get treasure data
      final treasureDoc = await _firestore
          .collection(_treasuresCollection)
          .doc(treasureId)
          .get();

      if (!treasureDoc.exists) {
        debugPrint('❌ Treasure not found for NFT minting: $treasureId');
        return;
      }

      final data = treasureDoc.data()!;
      final plantName = data['plantName'] ?? data['name'] ?? '';
      final imageUrl = data['imageUrl'] ?? data['imageBase64'];

      // Check if this is a new species
      final isNew = await _nftMintingService.isNewSpecies(plantName);

      // Mint the NFT
      final result = await _nftMintingService.mintPlantDiscoveryNFT(
        walletAddress: walletAddress,
        plantName: plantName,
        isNewSpecies: isNew,
        imageUrl: imageUrl,
        treasureId: treasureId,
      );

      if (result.success) {
        // Update treasure with NFT info
        await _firestore.collection(_treasuresCollection).doc(treasureId).update({
          'nftPending': false,
          'nftMinted': true,
          'nftMint': result.nftCard?.nftMint,
          'nftRarity': result.nftCard?.rarity.name,
          'nftMintedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('🎴 NFT minted for verified treasure: ${result.nftCard?.rarity.displayName}');
      } else {
        debugPrint('❌ NFT minting failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Error minting NFT for treasure: $e');
    }
  }

  /// Get all pending verifications (for community verification screen)
  Future<List<Map<String, dynamic>>> getPendingVerifications({
    String? excludeUserId,
    int limit = 20,
  }) async {
    try {
      // Get treasures that need verification
      var query = _firestore
          .collection(_treasuresCollection)
          .where('verificationStatus', isEqualTo: VerificationStatus.pending.name)
          .orderBy('discoveredAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      
      final results = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final treasureData = doc.data();
        
        // Skip if this is the user's own submission
        if (excludeUserId != null && treasureData['userId'] == excludeUserId) {
          continue;
        }

        // Get verification data
        final verificationDoc = await _firestore
            .collection(_verificationsCollection)
            .doc(doc.id)
            .get();

        TreasureVerification? verification;
        if (verificationDoc.exists) {
          verification = TreasureVerification.fromFirestore(verificationDoc);
          
          // Skip if user already voted
          if (excludeUserId != null && verification.hasVoted(excludeUserId)) {
            continue;
          }
        }

        results.add({
          'treasure': treasureData,
          'treasureId': doc.id,
          'verification': verification,
        });
      }

      debugPrint('📋 Found ${results.length} pending verifications');
      return results;
    } catch (e) {
      debugPrint('❌ Error getting pending verifications: $e');
      return [];
    }
  }

  /// Stream pending verifications for real-time updates
  Stream<List<Map<String, dynamic>>> streamPendingVerifications({
    String? excludeUserId,
  }) {
    return _firestore
        .collection(_treasuresCollection)
        .where('verificationStatus', isEqualTo: VerificationStatus.pending.name)
        .orderBy('discoveredAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
          final results = <Map<String, dynamic>>[];
          
          for (final doc in snapshot.docs) {
            final treasureData = doc.data();
            
            // Skip if this is the user's own submission
            if (excludeUserId != null && treasureData['userId'] == excludeUserId) {
              continue;
            }

            // Get verification data
            final verificationDoc = await _firestore
                .collection(_verificationsCollection)
                .doc(doc.id)
                .get();

            TreasureVerification? verification;
            if (verificationDoc.exists) {
              verification = TreasureVerification.fromFirestore(verificationDoc);
              
              // Skip if user already voted
              if (excludeUserId != null && verification.hasVoted(excludeUserId)) {
                continue;
              }
            }

            results.add({
              'treasure': treasureData,
              'treasureId': doc.id,
              'verification': verification,
            });
          }

          return results;
        });
  }

  /// Get user's verification history (treasures they submitted)
  Future<List<Map<String, dynamic>>> getUserSubmissions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_treasuresCollection)
          .where('userId', isEqualTo: userId)
          .where('verificationStatus', whereIn: [
            VerificationStatus.pending.name,
            VerificationStatus.verified.name,
            VerificationStatus.rejected.name,
          ])
          .orderBy('discoveredAt', descending: true)
          .get();

      final results = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final verificationDoc = await _firestore
            .collection(_verificationsCollection)
            .doc(doc.id)
            .get();

        results.add({
          'treasure': doc.data(),
          'treasureId': doc.id,
          'verification': verificationDoc.exists 
              ? TreasureVerification.fromFirestore(verificationDoc) 
              : null,
        });
      }

      return results;
    } catch (e) {
      debugPrint('❌ Error getting user submissions: $e');
      return [];
    }
  }

  /// Get count of pending verifications (for badge)
  Stream<int> streamPendingCount({String? excludeUserId}) {
    return _firestore
        .collection(_treasuresCollection)
        .where('verificationStatus', isEqualTo: VerificationStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          if (excludeUserId == null) return snapshot.docs.length;
          
          // Exclude user's own submissions
          return snapshot.docs
              .where((doc) => doc.data()['userId'] != excludeUserId)
              .length;
        });
  }
}
