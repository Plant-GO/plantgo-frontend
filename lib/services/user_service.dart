import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

/// Service for managing user data in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Get or create user by device ID
  Future<AppUser> getOrCreateUser(String deviceId, String userName) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(deviceId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update last active time
        await docRef.update({'lastActive': Timestamp.now()});
        return AppUser.fromFirestore(doc);
      } else {
        // Create new user
        final newUser = AppUser(userId: deviceId, userName: userName);
        await docRef.set(newUser.toFirestore());
        print('✅ Created new user: $deviceId');
        return newUser;
      }
    } catch (e) {
      print('❌ Error getting/creating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Update user coins
  Future<void> updateCoins(String userId, int coins) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'coins': coins,
        'lastActive': Timestamp.now(),
      });
      print('💰 Updated coins for user $userId: $coins');
    } catch (e) {
      print('❌ Error updating coins: $e');
      rethrow;
    }
  }

  /// Add coins to user
  Future<void> addCoins(String userId, int amount) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'coins': FieldValue.increment(amount),
        'lastActive': Timestamp.now(),
      });
      print('💰 Added $amount coins to user $userId');
    } catch (e) {
      print('❌ Error adding coins: $e');
      rethrow;
    }
  }

  /// Add leaves to user
  Future<void> addLeaves(String userId, int amount) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'leaves': FieldValue.increment(amount),
        'lastActive': Timestamp.now(),
      });
      print('🍃 Added $amount leaves to user $userId');
    } catch (e) {
      print('❌ Error adding leaves: $e');
      rethrow;
    }
  }

  /// Mark level as completed
  Future<void> completeLevel(String userId, int levelId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'completedLevelIds': FieldValue.arrayUnion([levelId.toString()]),
        'lastActive': Timestamp.now(),
      });
      print('✅ Marked level $levelId as completed for user $userId');
    } catch (e) {
      print('❌ Error completing level: $e');
      rethrow;
    }
  }

  /// Add treasure to user's collection
  Future<void> addTreasureToUser(String userId, String treasureId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'treasureIds': FieldValue.arrayUnion([treasureId]),
        'lastActive': Timestamp.now(),
      });
      print('🌿 Added treasure $treasureId to user $userId collection');
    } catch (e) {
      print('❌ Error adding treasure to user: $e');
      rethrow;
    }
  }

  /// Get user's treasure IDs
  Future<List<String>> getUserTreasureIds(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.treasureIds ?? [];
    } catch (e) {
      print('❌ Error getting user treasures: $e');
      return [];
    }
  }

  /// Check if user has completed a level
  Future<bool> hasCompletedLevel(String userId, int levelId) async {
    try {
      final user = await getUser(userId);
      return user?.completedLevelIds.contains(levelId.toString()) ?? false;
    } catch (e) {
      print('❌ Error checking level completion: $e');
      return false;
    }
  }

  /// Stream user data for real-time updates
  Stream<AppUser?> streamUser(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  /// Create a new user with email (for registered users)
  Future<AppUser> createEmailUser(String firebaseUid, String userName, String email) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(firebaseUid);
      final doc = await docRef.get();

      if (doc.exists) {
        // User already exists, return existing user
        return AppUser.fromFirestore(doc);
      }

      // Create new user with email
      final newUser = AppUser(
        userId: firebaseUid,
        userName: userName,
        email: email,
        isGuest: false,
      );
      await docRef.set(newUser.toFirestore());
      print('✅ Created new email user: $firebaseUid');
      return newUser;
    } catch (e) {
      print('❌ Error creating email user: $e');
      rethrow;
    }
  }

  /// Get current user ID from local storage (either device ID or Firebase UID)
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? prefs.getString('deviceId');
  }

  /// Get current user's device ID from local storage
  Future<String?> getCurrentDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deviceId');
  }

  /// Get current user's name from local storage
  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  /// Update user's name
  Future<void> updateUserName(String userId, String newName) async {
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    
    await userRef.update({
      'userName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
  }

  /// Get user's total treasure count
  Future<int> getUserTreasureCount(String userId) async {
    final treasures = await _firestore
        .collection('treasures')
        .where('userId', isEqualTo: userId)
        .get();

    return treasures.docs.length;
  }
}
