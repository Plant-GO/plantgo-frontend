class AppConstants {
  // API Constants - Go Backend
  static String _baseUrl = 'http://192.168.201.132:8080'; // Default Go backend server
  static String _webSocketUrl = 'ws://192.168.201.132:8080'; // Default WebSocket base URL
  static const String apiVersion = 'v1';
  
  // Getters for dynamic URLs
  static String get baseUrl => _baseUrl;
  static String get webSocketUrl => _webSocketUrl;
  
  // Method to update base URLs dynamically
  static void updateServerIP(String ipAddress, {int port = 8080}) {
    _baseUrl = 'http://$ipAddress:$port';
    _webSocketUrl = 'ws://$ipAddress:$port';
  }
  
  // Development Mode - Set to true when Go backend is not available
  static const bool isDevelopmentMode = true; // Set to false in production
  
  // Timeout Constants
  static const int connectionTimeOut = 30000;
  static const int receiveTimeOut = 30000;
  
  // Cache Constants
  static const String cacheKey = 'plantgo_cache';
  static const int cacheTimeout = 3600; // 1 hour in seconds
  
  // Map Constants
  static const double defaultLatitude = 27.7172;
  static const double defaultLongitude = 85.3240;
  static const double defaultZoom = 15.0;
  
  // Image Constants
  static const int maxImageSizeKB = 700;
  static const int imageQuality = 70;
  static const int maxImageDimension = 800;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';

  // Scanner Constants for Go Backend
  static const String scanImageEndpoint = '/scan/image';
  static const String scanVideoEndpoint = '/scan/video';
  static const int scanFrameRate = 2; // FPS for video streaming
}
