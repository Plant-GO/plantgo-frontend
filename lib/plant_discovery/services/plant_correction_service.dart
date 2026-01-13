import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_correction.dart';
import '../models/plant_counter.dart'; // For NFTRarity extension
import 'plant_discovery_service.dart';

/// Service for handling plant identification corrections
class PlantCorrectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantDiscoveryService _discoveryService = PlantDiscoveryService();

  static const String _correctionsCollection = 'plant_corrections';
  static const String _treasuresCollection = 'treasures';

  /// Submit a correction for a misidentified plant
  Future<PlantCorrection> submitCorrection({
    required String originalTreasureId,
    required String originalPlantName,
    required String correctedPlantName,
    required String correctedBy,
    required String correctedByName,
    required String originalDiscoveredBy,
    required String originalDiscoveredByName,
    required double originalConfidence,
    String? imageBase64,
    double? latitude,
    double? longitude,
  }) async {
    final correction = PlantCorrection(
      id: '', // Will be set by Firestore
      originalTreasureId: originalTreasureId,
      originalPlantName: originalPlantName,
      correctedPlantName: correctedPlantName.trim().toLowerCase(),
      correctedBy: correctedBy,
      correctedByName: correctedByName,
      originalDiscoveredBy: originalDiscoveredBy,
      originalDiscoveredByName: originalDiscoveredByName,
      originalConfidence: originalConfidence,
      imageBase64: imageBase64,
      latitude: latitude,
      longitude: longitude,
      status: CorrectionStatus.pending,
      upvotes: 0,
      downvotes: 0,
      voterIds: [],
    );

    final docRef = await _firestore
        .collection(_correctionsCollection)
        .add(correction.toFirestore());

    print(
      'PlantCorrectionService: Submitted correction ${docRef.id} for $originalPlantName -> $correctedPlantName',
    );

    return correction.copyWith(id: docRef.id);
  }

  /// Upvote a correction (agree with the new identification)
  Future<PlantCorrection?> upvoteCorrection(
    String correctionId,
    String voterId,
  ) async {
    return await _vote(correctionId, voterId, isUpvote: true);
  }

  /// Downvote a correction (disagree with the new identification)
  Future<PlantCorrection?> downvoteCorrection(
    String correctionId,
    String voterId,
  ) async {
    return await _vote(correctionId, voterId, isUpvote: false);
  }

  Future<PlantCorrection?> _vote(
    String correctionId,
    String voterId, {
    required bool isUpvote,
  }) async {
    final docRef = _firestore
        .collection(_correctionsCollection)
        .doc(correctionId);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        print('PlantCorrectionService: Correction $correctionId not found');
        return null;
      }

      final correction = PlantCorrection.fromFirestore(snapshot);

      // Check if already voted
      if (correction.hasVoted(voterId)) {
        print(
          'PlantCorrectionService: User $voterId already voted on $correctionId',
        );
        return correction;
      }

      // Add vote
      final newVoterIds = [...correction.voterIds, voterId];
      final newUpvotes = isUpvote ? correction.upvotes + 1 : correction.upvotes;
      final newDownvotes = isUpvote
          ? correction.downvotes
          : correction.downvotes + 1;

      CorrectionStatus newStatus = correction.status;
      DateTime? verifiedAt;

      // Check thresholds
      if (newUpvotes >= PlantCorrection.upvotesRequired &&
          correction.status == CorrectionStatus.pending) {
        newStatus = CorrectionStatus.approved;
        verifiedAt = DateTime.now();
        print('PlantCorrectionService: Correction $correctionId APPROVED!');
      } else if (newDownvotes >= PlantCorrection.downvotesRequired &&
          correction.status == CorrectionStatus.pending) {
        newStatus = CorrectionStatus.rejected;
        verifiedAt = DateTime.now();
        print('PlantCorrectionService: Correction $correctionId REJECTED!');
      }

      transaction.update(docRef, {
        'upvotes': newUpvotes,
        'downvotes': newDownvotes,
        'voterIds': newVoterIds,
        'status': newStatus.name,
        if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt),
      });

      final updatedCorrection = correction.copyWith(
        upvotes: newUpvotes,
        downvotes: newDownvotes,
        voterIds: newVoterIds,
        status: newStatus,
        verifiedAt: verifiedAt,
      );

      // If approved, create the new treasure with correct plant name
      if (newStatus == CorrectionStatus.approved) {
        await _createCorrectedTreasure(updatedCorrection, transaction);
      }

      return updatedCorrection;
    });
  }

  /// Create a new treasure entry for the corrected plant
  Future<void> _createCorrectedTreasure(
    PlantCorrection correction,
    Transaction transaction,
  ) async {
    // First, check if this is a new species (never before seen in our system)
    final isNewSpecies = await _discoveryService.isNewSpecies(
      correction.correctedPlantName,
    );

    // Determine the rarity for this plant
    final rarity = await _discoveryService.determineRarity(
      plantName: correction.correctedPlantName,
      isNewSpeciesDiscovery: isNewSpecies,
    );

    final treasureDoc = _firestore.collection(_treasuresCollection).doc();

    final treasureData = {
      'plantName': correction.correctedPlantName,
      'originalPlantName': correction
          .originalPlantName, // Keep track of what it was originally identified as
      'confidence': 1.0, // Community verified = 100% confidence
      'imageBase64': correction.imageBase64,
      'latitude': correction.latitude,
      'longitude': correction.longitude,
      'discoveredAt': Timestamp.fromDate(correction.submittedAt),
      'verifiedAt': Timestamp.now(),

      // Attribution
      'discoveredBy': correction.originalDiscoveredBy,
      'discoveredByName': correction.originalDiscoveredByName,
      'identifiedBy': correction.correctedBy,
      'identifiedByName': correction.correctedByName,

      // Verification status
      'verificationStatus': 'verified',
      'isCommunityVerified': true,
      'isCorrectedIdentification': true,
      'originalCorrectionId': correction.id,

      // NFT Rarity
      'nftRarity': rarity.name,
      'nftRarityDisplayName': rarity.displayName,
      'nftRarityColor': rarity.colorHex,

      // Minting status
      'nftMinted': false,
      'nftPendingMint': true,
    };

    transaction.set(treasureDoc, treasureData);

    // Record the mint for counter tracking (outside transaction to avoid nested transaction)
    // Note: This will be executed after the transaction completes
    _discoveryService.recordMint(
      plantName: correction.correctedPlantName,
      rarity: rarity,
      discoveredBy: correction.originalDiscoveredBy,
    );

    print(
      'PlantCorrectionService: Created corrected treasure ${treasureDoc.id} with rarity ${rarity.displayName}',
    );
    print('  - Discovered by: ${correction.originalDiscoveredByName}');
    print('  - Identified by: ${correction.correctedByName}');
  }

  /// Get all pending corrections for community verification
  Stream<List<PlantCorrection>> getPendingCorrections() {
    return _firestore
        .collection(_correctionsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlantCorrection.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get corrections submitted by a specific user
  Stream<List<PlantCorrection>> getUserCorrections(String userId) {
    return _firestore
        .collection(_correctionsCollection)
        .where('correctedBy', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlantCorrection.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get a single correction by ID
  Future<PlantCorrection?> getCorrection(String correctionId) async {
    final doc = await _firestore
        .collection(_correctionsCollection)
        .doc(correctionId)
        .get();
    if (!doc.exists) return null;
    return PlantCorrection.fromFirestore(doc);
  }

  /// Check if a correction already exists for a treasure
  Future<bool> hasPendingCorrection(String treasureId) async {
    final query = await _firestore
        .collection(_correctionsCollection)
        .where('originalTreasureId', isEqualTo: treasureId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get statistics for corrections
  Future<Map<String, int>> getCorrectionStats(String userId) async {
    final submitted = await _firestore
        .collection(_correctionsCollection)
        .where('correctedBy', isEqualTo: userId)
        .get();

    int approved = 0;
    int rejected = 0;
    int pending = 0;

    for (final doc in submitted.docs) {
      final status = doc.data()['status'] as String?;
      switch (status) {
        case 'approved':
          approved++;
          break;
        case 'rejected':
          rejected++;
          break;
        default:
          pending++;
      }
    }

    return {
      'total': submitted.docs.length,
      'approved': approved,
      'rejected': rejected,
      'pending': pending,
    };
  }
}
