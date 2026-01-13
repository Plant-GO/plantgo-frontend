import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'user_service.dart';
import 'wallet_service.dart';
import '../models/app_user.dart';

/// Authentication service for handling Firebase Auth and Guest login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final WalletService _walletService = WalletService();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in (either Firebase or Guest)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;
    return _auth.currentUser != null || isGuest;
  }

  /// Check if current user is a guest
  Future<bool> isGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  /// Register with email and password
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String userName,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await firebaseUser.updateDisplayName(userName);

      // Create user in Firestore
      final appUser = await _userService.createEmailUser(
        firebaseUser.uid,
        userName,
        email,
      );

      // Clear any cached wallet from previous session
      await _walletService.disconnect();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deviceId'); // Remove device ID cache
      await prefs.setString('userName', userName);
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isGuest', false);
      await prefs.setBool('hasCompletedOnboarding', true);

      print('✅ Registered new user: ${firebaseUser.uid}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Registration error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  /// Login with email and password
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Get user from Firestore
      final appUser = await _userService.getUser(firebaseUser.uid);
      if (appUser == null) {
        throw Exception('User data not found');
      }

      // Save to SharedPreferences - Clear any guest data to avoid confusion
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deviceId'); // Remove device ID cache for registered users
      
      // Clear any cached wallet from previous session
      await _walletService.disconnect();
      
      await prefs.setString('userName', appUser.userName);
      await prefs.setString('userId', firebaseUser.uid);
      await prefs.setString('userEmail', appUser.email ?? '');
      await prefs.setBool('isGuest', false);
      await prefs.setBool('hasCompletedOnboarding', true);

      print('✅ Logged in user: ${firebaseUser.uid}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('❌ Login error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  /// Login as guest using device ID
  Future<AppUser> loginAsGuest(String userName) async {
    try {
      final deviceId = await _getDeviceId();

      // Create or get user from Firestore
      final appUser = await _userService.getOrCreateUser(deviceId, userName);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('deviceId', deviceId);
      await prefs.setString('userId', deviceId);
      await prefs.setBool('isGuest', true);
      await prefs.setBool('hasCompletedOnboarding', true);

      print('✅ Guest login: $deviceId');
      return appUser;
    } catch (e) {
      print('❌ Guest login error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userName');
      await prefs.remove('userId');
      await prefs.remove('deviceId');
      await prefs.remove('userEmail');
      await prefs.remove('isGuest');
      await prefs.setBool('hasCompletedOnboarding', false);

      print('✅ Signed out');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get device ID for guest login
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }

    return 'unknown_device';
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
