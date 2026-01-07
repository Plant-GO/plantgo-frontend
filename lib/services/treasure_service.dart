import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

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
  });

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
    );
  }

  Map<String, dynamic> toFirestore() {
    // Validate numeric values to prevent Firestore errors
    final validLatitude = latitude.isFinite ? latitude : 0.0;
    final validLongitude = longitude.isFinite ? longitude : 0.0;
    final validConfidence = confidence.isFinite ? confidence : 0.0;
    
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
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}

/// Service for managing treasure (discovered plants) in Firestore
class TreasureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _treasuresCollection = 'treasures';
  final _uuid = const Uuid();

  /// Save a new treasure (discovered plant) to Firestore
  Future<Treasure> saveTreasure({
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
  }) async {
    final treasureId = _uuid.v4();
    
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
    );

    // Save to Firestore
    try {
      print('💾 Attempting to save treasure to Firestore...');
      print('💾 Treasure data: ${treasure.toFirestore()}');
      
      await _firestore
          .collection(_treasuresCollection)
          .doc(treasureId)
          .set(treasure.toFirestore());
      
      print('✅ Treasure saved successfully to Firestore: $treasureId');
      return treasure;
    } catch (e, stackTrace) {
      print('❌ Error saving treasure to Firestore: $e');
      print('Stack trace: $stackTrace');
      rethrow;
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
