import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'backend_url_provider.dart';

/// Service for managing backend configuration
class BackendConfigService {
  static const String _backendUrlKey = 'backend_url';
  static const String _defaultBackendUrl =
      'http://10.0.2.2:3001'; // Android emulator default

  /// Get the stored backend URL
  static Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey) ?? _defaultBackendUrl;
  }

  /// Save backend URL
  static Future<void> saveBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, url);
    BackendUrlProvider.clearCache(); // Clear cache so new URL is used
    print('💾 Backend URL saved: $url');
  }

  /// Reset to default
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendUrlKey);
    print('🔄 Backend URL reset to default');
  }

  /// Test connection to backend
  static Future<bool> testConnection(String url) async {
    try {
      final uri = Uri.parse('$url/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Format IP address to backend URL
  static String formatBackendUrl(String input) {
    // Remove any whitespace
    input = input.trim();

    // If it already starts with http, return as is
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }

    // If it's just an IP, add http:// and port
    if (input.contains('.') && !input.contains(':')) {
      return 'http://$input:3001';
    }

    // If it has IP:port, add http://
    if (input.contains(':')) {
      return 'http://$input';
    }

    // Default: assume it's just IP
    return 'http://$input:3001';
  }

  /// Validate IP address format
  static bool isValidIP(String input) {
    // Basic validation for IP address
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d{1,5})?$');
    return ipRegex.hasMatch(input);
  }

  /// Get suggested IP addresses
  static List<String> getSuggestedIPs() {
    return [
      '192.168.1.x', // Common home network
      '192.168.0.x', // Alternative home network
      '10.0.2.2', // Android emulator
      '192.168.2.x', // Another common range
    ];
  }
}
