import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../blockchain/solana_config.dart';

/// Service for connecting to Phantom wallet via deep links.
/// 
/// Handles wallet connection, disconnection, and session management.
class WalletService {
  static const String _walletAddressKey = 'phantom_wallet_address';
  static const String _sessionTokenKey = 'phantom_session_token';
  
  /// Singleton instance
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  /// AppLinks instance
  final _appLinks = AppLinks();

  /// Stream controller for deep link responses
  StreamSubscription? _linkSubscription;
  
  /// Completer for pending connection requests
  Completer<String?>? _connectionCompleter;

  /// Initialize the wallet service and listen for deep links
  Future<void> initialize() async {
    // Handle incoming deep links (both initial and new)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) {
        debugPrint('WalletService: Deep link error: $err');
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }

  /// Handle incoming deep links from Phantom
  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    
    debugPrint('WalletService: Received deep link: $uri');
    
    // Parse Phantom response
    if (uri.scheme == SolanaConfig.appScheme) {
      final path = uri.host;
      
      switch (path) {
        case 'onConnect':
          _handleConnectResponse(uri);
          break;
        case 'onDisconnect':
          _handleDisconnectResponse();
          break;
        case 'onSignTransaction':
          // Handle signed transaction response
          break;
        default:
          debugPrint('WalletService: Unknown path: $path');
      }
    }
  }

  /// Handle connection response from Phantom
  void _handleConnectResponse(Uri uri) {
    final params = uri.queryParameters;
    
    if (params.containsKey('errorCode')) {
      final errorMessage = params['errorMessage'] ?? 'Connection rejected';
      debugPrint('WalletService: Connection error: $errorMessage');
      _connectionCompleter?.complete(null);
      return;
    }
    
    // Decode the public key from base58
    final publicKey = params['phantom_encryption_public_key'];
    final data = params['data'];
    
    if (data != null) {
      try {
        // Decode and parse the response data
        final decoded = utf8.decode(base64Decode(data));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final walletAddress = json['public_key'] as String?;
        
        if (walletAddress != null) {
          _saveWalletAddress(walletAddress);
          _connectionCompleter?.complete(walletAddress);
          return;
        }
      } catch (e) {
        debugPrint('WalletService: Error parsing connection data: $e');
      }
    }
    
    // Fallback: use the public key directly if available
    if (publicKey != null) {
      _saveWalletAddress(publicKey);
      _connectionCompleter?.complete(publicKey);
    } else {
      _connectionCompleter?.complete(null);
    }
  }

  /// Handle disconnect response from Phantom
  void _handleDisconnectResponse() {
    _clearWalletData();
    debugPrint('WalletService: Wallet disconnected');
  }

  /// Connect to Phantom wallet
  /// Returns the wallet address if successful, null otherwise
  Future<String?> connect() async {
    _connectionCompleter = Completer<String?>();
    
    // Build Phantom connect URL
    final connectUrl = _buildPhantomUrl(
      path: 'connect',
      queryParams: {
        'app_url': 'https://plantgo.app',
        'dapp_encryption_public_key': '', // Not needed for simple connect
        'redirect_link': '${SolanaConfig.appScheme}://onConnect',
        'cluster': SolanaConfig.cluster,
      },
    );
    
    // Launch Phantom
    final launched = await _launchPhantom(connectUrl);
    
    if (!launched) {
      _connectionCompleter?.complete(null);
      return null;
    }
    
    // Wait for response (with timeout)
    try {
      return await _connectionCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('WalletService: Connection timeout or error: $e');
      return null;
    }
  }

  /// Disconnect from Phantom wallet
  Future<void> disconnect() async {
    _clearWalletData();
    
    // Optionally notify Phantom about disconnection
    final disconnectUrl = _buildPhantomUrl(
      path: 'disconnect',
      queryParams: {
        'redirect_link': '${SolanaConfig.appScheme}://onDisconnect',
      },
    );
    
    await _launchPhantom(disconnectUrl);
  }

  /// Get the connected wallet address (from local storage)
  Future<String?> getConnectedWallet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_walletAddressKey);
  }

  /// Alias for getConnectedWallet for provider compatibility
  Future<String?> getCachedWalletAddress() => getConnectedWallet();

  /// Check if a wallet is currently connected
  Future<bool> isConnected() async {
    final address = await getConnectedWallet();
    return address != null && address.isNotEmpty;
  }

  /// Build a Phantom deep link URL
  Uri _buildPhantomUrl({
    required String path,
    required Map<String, String> queryParams,
  }) {
    // Remove empty params
    queryParams.removeWhere((key, value) => value.isEmpty);
    
    return Uri(
      scheme: SolanaConfig.phantomScheme,
      host: 'ul',
      path: 'v1/$path',
      queryParameters: queryParams,
    );
  }

  /// Launch Phantom app via deep link
  Future<bool> _launchPhantom(Uri url) async {
    try {
      debugPrint('WalletService: Attempting to launch Phantom: $url');
      
      // Try to launch directly - Android package visibility means canLaunchUrl 
      // may return false even when the app is installed
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        debugPrint('WalletService: Successfully launched Phantom');
        return true;
      }
      
      // If launch failed, Phantom might not be installed
      debugPrint('WalletService: Launch returned false - Phantom may not be installed');
      await _openPhantomAppStore();
      return false;
    } catch (e) {
      debugPrint('WalletService: Error launching Phantom: $e');
      // Try opening app store as fallback
      await _openPhantomAppStore();
      return false;
    }
  }

  /// Open Phantom app store page
  Future<void> _openPhantomAppStore() async {
    // iOS App Store link
    const appStoreUrl = 'https://apps.apple.com/app/phantom-solana-wallet/id1598432977';
    // Android Play Store link
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=app.phantom';
    
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse(appStoreUrl)
        : Uri.parse(playStoreUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Save wallet address to local storage
  Future<void> _saveWalletAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletAddressKey, address);
  }

  /// Clear wallet data from local storage
  Future<void> _clearWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletAddressKey);
    await prefs.remove(_sessionTokenKey);
  }

  /// Get abbreviated wallet address for display (e.g., "7nYB...4xkA")
  static String abbreviateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
  }
}
