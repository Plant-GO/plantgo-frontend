import '../blockchain/solana_config.dart';
import 'backend_config_service.dart';

/// Provider for dynamic backend URL
/// Wraps SolanaConfig to support runtime configuration
class BackendUrlProvider {
  static String? _cachedUrl;

  /// Get the current backend URL (loads from storage)
  static Future<String> getBackendUrl() async {
    if (_cachedUrl != null) {
      return _cachedUrl!;
    }
    
    _cachedUrl = await BackendConfigService.getBackendUrl();
    return _cachedUrl!;
  }

  /// Clear cached URL (call after updating config)
  static void clearCache() {
    _cachedUrl = null;
  }

  /// Get backend URL synchronously (uses cached value or falls back to default)
  static String getBackendUrlSync() {
    return _cachedUrl ?? SolanaConfig.backendApiUrl;
  }
}
