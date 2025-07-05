import 'package:injectable/injectable.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

@injectable
class UserService {
  static const String _guestUserPrefix = 'guest_';
  
  String? _currentUserId;
  String? _currentUserType; // 'email', 'google', 'guest'
  
  String? get currentUserId => _currentUserId;
  String? get currentUserType => _currentUserType;
  bool get isAuthenticated => _currentUserId != null;
  bool get isGuestUser => _currentUserType == 'guest';
  
  // Set user for email/Google authentication
  void setAuthenticatedUser(String userId, String userType) {
    _currentUserId = userId;
    _currentUserType = userType;
  }
  
  // Generate guest user ID based on device info
  Future<String> generateGuestUserId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else {
        deviceId = 'unknown_platform';
      }
      
      return '$_guestUserPrefix$deviceId';
    } catch (e) {
      // Fallback to timestamp-based ID
      return '${_guestUserPrefix}${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Set guest user
  Future<void> setGuestUser() async {
    final guestId = await generateGuestUserId();
    _currentUserId = guestId;
    _currentUserType = 'guest';
  }
  
  // Clear user session
  void clearUser() {
    _currentUserId = null;
    _currentUserType = null;
  }
  
  // Check if current user can access data
  bool canAccessUserData(String? dataUserId) {
    if (_currentUserId == null || dataUserId == null) return false;
    return _currentUserId == dataUserId;
  }
}
