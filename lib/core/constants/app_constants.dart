class AppConstants {
  // API Constants
  static const String baseUrl = 'YOUR_API_BASE_URL'; // Replace with your backend URL
  static const String apiVersion = 'v1';
  
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
}
