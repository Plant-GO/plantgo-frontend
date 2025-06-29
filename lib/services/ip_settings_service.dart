import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:plantgo/api/http_manager.dart';
import 'package:plantgo/core/constants/app_constants.dart';

@injectable
class IPSettingsService {
  final HttpManager _httpManager;

  IPSettingsService(this._httpManager);

  /// Get the current server IP address
  Future<String> getCurrentIP() async {
    // For now, we'll use a simple approach without shared_preferences
    // You can add shared_preferences dependency later if needed
    return 'localhost';
  }

  /// Get the current server port
  Future<int> getCurrentPort() async {
    return 8080;
  }

  /// Update the server IP address and port
  Future<bool> updateServerIP(String ipAddress, {int port = 8080}) async {
    try {
      // Validate IP address format
      if (!_isValidIP(ipAddress) && ipAddress != 'localhost') {
        throw Exception('Invalid IP address format');
      }

      // Validate port range
      if (port < 1 || port > 65535) {
        throw Exception('Invalid port number. Must be between 1 and 65535');
      }

      // Update app constants
      AppConstants.updateServerIP(ipAddress, port: port);

      // Update HTTP manager
      _httpManager.updateBaseUrl(AppConstants.baseUrl);

      print('IPSettingsService: Updated server to $ipAddress:$port');
      return true;
    } catch (e) {
      print('IPSettingsService: Failed to update server IP: $e');
      return false;
    }
  }

  /// Load saved IP settings on app start
  Future<void> loadSavedSettings() async {
    try {
      final ipAddress = await getCurrentIP();
      final port = await getCurrentPort();

      if (ipAddress != 'localhost' || port != 8080) {
        AppConstants.updateServerIP(ipAddress, port: port);
        _httpManager.updateBaseUrl(AppConstants.baseUrl);
        print('IPSettingsService: Loaded saved settings - $ipAddress:$port');
      }
    } catch (e) {
      print('IPSettingsService: Failed to load saved settings: $e');
    }
  }

  /// Test connection to the server
  Future<bool> testConnection({String? testIP, int? testPort}) async {
    try {
      final ip = testIP ?? await getCurrentIP();
      final port = testPort ?? await getCurrentPort();
      final testUrl = 'http://$ip:$port';

      // Create a test Dio instance
      final testDio = Dio(BaseOptions(
        baseUrl: testUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // Try to make a simple request to test connectivity
      final response = await testDio.get('/scan/image');

      return response.statusCode == 200 || response.statusCode == 404; // 404 is also ok, means server is running
    } catch (e) {
      print('IPSettingsService: Connection test failed: $e');
      return false;
    }
  }

  /// Reset to default localhost settings
  Future<void> resetToDefault() async {
    await updateServerIP('localhost', port: 8080);
  }

  /// Get the current full server URL
  String getCurrentServerURL() {
    return AppConstants.baseUrl;
  }

  /// Get the current WebSocket URL
  String getCurrentWebSocketURL() {
    return AppConstants.webSocketUrl;
  }

  /// Validate IP address format
  bool _isValidIP(String ip) {
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ip);
  }
}
