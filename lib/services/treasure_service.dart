import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../blockchain/blockchain.dart';
import '../models/verification.dart';
import 'nft_minting_service.dart';

/// Confidence threshold for auto-verification
const double verificationConfidenceThreshold = 0.60;

/// Result from saving a treasure
class TreasureSaveResult {
  final Treasure treasure;
  final bool autoVerified;
  final bool nftMinted;
  final String? nftRarity;
  final String? error;

  TreasureSaveResult({
    required this.treasure,
    this.autoVerified = false,
    this.nftMinted = false,
    this.nftRarity,
    this.error,
  });
}

/// Model for a plant treasure discovery
class Treasure {
  final String id;
  final String plantName;
  final String commonName;
  final double latitude;
  final double longitude;
  final String imageBase64; // Store base64 string instead of URL
  final String userId;
  final String userName;
  final DateTime discoveredAt;
  final int levelId;
  final double confidence;
  final String? description; // Plant description from API
  final VerificationStatus verificationStatus; // Verification status

  Treasure({
    required this.id,
    required this.plantName,
    required this.commonName,
    required this.latitude,
    required this.longitude,
    required this.imageBase64,
    required this.userId,
    required this.userName,
    required this.discoveredAt,
    required this.levelId,
    required this.confidence,
    this.description,
    this.verificationStatus = VerificationStatus.pending,
  });

  /// Check if this treasure needs community verification
  bool get needsVerification => confidence < verificationConfidenceThreshold;

  /// Check if this treasure is verified (auto or community)
  bool get isVerified => 
      verificationStatus == VerificationStatus.autoVerified || 
      verificationStatus == VerificationStatus.verified;

  factory Treasure.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Treasure(
      id: doc.id,
      plantName: data['name'] ?? data['plantName'] ?? '',
      commonName: data['name'] ?? data['commonName'] ?? '',
      latitude: (data['lat'] ?? data['latitude'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? data['longitude'] ?? 0).toDouble(),
      imageBase64: data['imageUrl'] ?? data['imageBase64'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      discoveredAt: (data['discoveredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      levelId: data['levelId'] ?? 0,
      confidence: (data['confidence'] ?? 0).toDouble(),
      description: data['description'],
      verificationStatus: VerificationStatusExtension.fromString(
        data['verificationStatus'] ?? 'pending',
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    // Validate numeric values to prevent Firestore errors
    final validLatitude = latitude.isFinite ? latitude : 0.0;
    final validLongitude = longitude.isFinite ? longitude : 0.0;
    final validConfidence = confidence.isFinite ? confidence : 0.0;
    
    // Determine verification status based on confidence
    final status = validConfidence >= verificationConfidenceThreshold
        ? VerificationStatus.autoVerified
        : VerificationStatus.pending;
    
    return {
      'name': commonName.isNotEmpty ? commonName : plantName,
      'plantName': plantName,
      'commonName': commonName,
      'lat': validLatitude,
      'lng': validLongitude,
      'latitude': validLatitude,
      'longitude': validLongitude,
      'imageUrl': imageBase64,
      'imageBase64': imageBase64,
      'userId': userId,
      'userName': userName,
      'discoveredAt': Timestamp.fromDate(discoveredAt),
      'levelId': levelId,
      'confidence': validConfidence,
      'location': GeoPoint(validLatitude, validLongitude),
      'verificationStatus': status.name,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}

/// Service for managing treasure (discovered plants) in Firestore
class TreasureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NFTMintingService _nftMintingService = NFTMintingService();
  static const String _treasuresCollection = 'treasures';
  final _uuid = const Uuid();

  /// Save a new treasure (discovered plant) to Firestore
  /// Returns TreasureSaveResult with NFT minting status
  Future<TreasureSaveResult> saveTreasure({
    required String plantName,
    required String commonName,
    required double latitude,
    required double longitude,
    required String imageBase64,
    required String userId,
    required String userName,
    required int levelId,
    required double confidence,
    String? description,
    String? walletAddress, // For NFT minting
  }) async {
    final treasureId = _uuid.v4();
    final autoVerified = confidence >= verificationConfidenceThreshold;
    
    final treasure = Treasure(
      id: treasureId,
      plantName: plantName,
      commonName: commonName,
      latitude: latitude,
      longitude: longitude,
      imageBase64: imageBase64,
      userId: userId,
      userName: userName,
      discoveredAt: DateTime.now(),
      levelId: levelId,
      confidence: confidence,
      description: description,
      verificationStatus: autoVerified 
          ? VerificationStatus.autoVerified 
          : VerificationStatus.pending,
    );

    // Save to Firestore
    try {
      print('💾 Attempting to save treasure to Firestore...');
      
      await _firestore
          .collection(_treasuresCollection)
          .doc(treasureId)
          .set(treasure.toFirestore());
      
      print('✅ Treasure saved successfully to Firestore: $treasureId');

      // Handle based on confidence level
      if (!autoVerified) {
        print('⏳ Low confidence (${(confidence * 100).toStringAsFixed(0)}%) - creating verification record');
        await _initializeVerification(treasureId, confidence);
        
        return TreasureSaveResult(
          treasure: treasure,
          autoVerified: false,
          nftMinted: false,
        );
      }

      print('✅ Auto-verified (${(confidence * 100).toStringAsFixed(0)}% confidence)');

      // Mint NFT for auto-verified treasures
      if (walletAddress != null) {
        final mintResult = await _mintNFTForTreasure(
          treasureId: treasureId,
          plantName: plantName,
          walletAddress: walletAddress,
          imageUrl: imageBase64,
        );

        return TreasureSaveResult(
          treasure: treasure,
          autoVerified: true,
          nftMinted: mintResult.success,
          nftRarity: mintResult.nftCard?.rarity.displayName,
        );
      }
      
      return TreasureSaveResult(
        treasure: treasure,
        autoVerified: true,
        nftMinted: false,
      );
    } catch (e, stackTrace) {
      print('❌ Error saving treasure to Firestore: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mint NFT for a treasure
  Future<MintResult> _mintNFTForTreasure({
    required String treasureId,
    required String plantName,
    required String walletAddress,
    String? imageUrl,
  }) async {
    try {
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

      if (result.success && result.nftCard != null) {
        // Update treasure with NFT info
        await _firestore.collection(_treasuresCollection).doc(treasureId).update({
          'nftMinted': true,
          'nftMint': result.nftCard!.nftMint,
          'nftRarity': result.nftCard!.rarity.name,
          'nftMintedAt': FieldValue.serverTimestamp(),
          'isNewSpecies': isNew,
        });
        print('🎴 NFT minted: ${result.nftCard!.rarity.displayName}');
      }

      return result;
    } catch (e) {
      print('❌ Error minting NFT: $e');
      return MintResult(success: false, error: e.toString());
    }
  }

  /// Mint NFT for previously saved treasure (called after community verification)
  Future<MintResult> mintNFTForExistingTreasure({
    required String treasureId,
    required String walletAddress,
  }) async {
    final doc = await _firestore.collection(_treasuresCollection).doc(treasureId).get();
    
    if (!doc.exists) {
      return MintResult(success: false, error: 'Treasure not found');
    }

    final data = doc.data()!;
    final plantName = data['plantName'] ?? data['name'] ?? '';

    return _mintNFTForTreasure(
      treasureId: treasureId,
      plantName: plantName,
      walletAddress: walletAddress,
      imageUrl: data['imageUrl'],
    );
  }

  /// Initialize verification record for low-confidence discoveries
  Future<void> _initializeVerification(String treasureId, double confidence) async {
    try {
      await _firestore
          .collection('verifications')
          .doc(treasureId)
          .set({
            'upvotes': 0,
            'downvotes': 0,
            'voterIds': [],
            'status': 'pending',
          });
      print('✅ Verification record created for $treasureId');
    } catch (e) {
      print('⚠️ Warning: Could not create verification record: $e');
      // Don't rethrow - treasure is saved, verification can be created later
    }
  }

  /// Get all treasures for a specific user
  Future<List<Treasure>> getUserTreasures(String userId) async {
    final snapshot = await _firestore
        .collection(_treasuresCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('discoveredAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Treasure.fromFirestore(doc)).toList();
  }

  /// Stream user's treasures for real-time updates
  Stream<List<Treasure>> getUserTreasuresStream(String userId) {
    return _firestore
        .collection(_treasuresCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('discoveredAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Treasure.fromFirestore(doc)).toList());
  }

  /// Get all treasures (community map)
  Future<List<Treasure>> getAllTreasures() async {
    try {
      final snapshot = await _firestore
          .collection(_treasuresCollection)
          .limit(100)
          .get();
      
      print('📍 Firestore query completed. Found ${snapshot.docs.length} documents');
      
      final treasures = snapshot.docs.map((doc) {
        print('📍 Processing document ${doc.id}: ${doc.data()}');
        return Treasure.fromFirestore(doc);
      }).toList();
      
      return treasures;
    } catch (e) {
      print('❌ Error fetching treasures: $e');
      return [];
    }
  }

  /// Stream of user's treasures for real-time updates
  Stream<List<Treasure>> streamUserTreasures(String userId) {
    return _firestore
        .collection(_treasuresCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('discoveredAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Treasure.fromFirestore(doc)).toList());
  }

  /// Check if user has already discovered a plant for a specific level
  Future<bool> hasDiscoveredLevel(String userId, int levelId) async {
    final snapshot = await _firestore
        .collection(_treasuresCollection)
        .where('userId', isEqualTo: userId)
        .where('levelId', isEqualTo: levelId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get treasure count for a user
  Future<int> getTreasureCount(String userId) async {
    final snapshot = await _firestore
        .collection(_treasuresCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  /// Delete a treasure
  Future<void> deleteTreasure(String treasureId) async {
    // Delete from Firestore
    await _firestore.collection(_treasuresCollection).doc(treasureId).delete();
  }
}
