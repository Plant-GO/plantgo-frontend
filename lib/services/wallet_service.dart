import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:pinenacl/x25519.dart';
import 'package:bs58/bs58.dart' as bs58;
import '../blockchain/solana_config.dart';

/// Service for connecting to Phantom wallet via deep links.
/// 
/// Implements Phantom v1 encrypted protocol with proper NaCl encryption.
/// Handles wallet connection, disconnection, transaction signing, and session management.
class WalletService {
  static const String _walletAddressKey = 'phantom_wallet_address';
  static const String _sessionTokenKey = 'phantom_session_token';
  static const String _phantomPubKeyKey = 'phantom_encryption_public_key';
  static const String _dappPrivateKeyKey = 'dapp_private_key';
  static const String _dappPublicKeyKey = 'dapp_public_key';
  
  // NaCl box nonce length is always 24 bytes
  static const int _nonceLength = 24;
  
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
  
  /// Completer for pending transaction signing
  Completer<String?>? _signTransactionCompleter;
  
  /// Whether Phantom app is installed
  bool _phantomInstalled = false;
  bool get isPhantomInstalled => _phantomInstalled;
  
  /// DApp encryption keypair (X25519)
  PrivateKey? _dappPrivateKey;
  PublicKey? _dappPublicKey;
  
  /// Phantom's encryption public key (received after connect)
  Uint8List? _phantomPublicKey;

  /// Initialize the wallet service and listen for deep links
  Future<void> initialize() async {
    debugPrint('WalletService: Initializing...');
    
    // Check if Phantom is installed
    await _checkPhantomInstalled();
    
    // Restore session keys (DApp keypair + Phantom public key)
    await _restoreSessionKeys();
    
    debugPrint('WalletService: After restore - DApp key: ${_dappPrivateKey != null}, Phantom key: ${_phantomPublicKey != null}');
    
    // Handle incoming deep links (both initial and new)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLinkAsync(uri),
      onError: (err) {
        debugPrint('WalletService: Deep link error: $err');
      },
    );
    
    // Check for initial link (app was opened via deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('WalletService: Initial link: $initialUri');
      if (initialUri != null) {
        await _handleDeepLinkAsync(initialUri);
      }
    } catch (e) {
      debugPrint('WalletService: Error getting initial link: $e');
    }
    
    debugPrint('WalletService: Initialization complete');
  }
  
  /// Generate X25519 encryption keypair for Phantom v1 protocol
  Future<void> _generateEncryptionKeyPair() async {
    final keyPair = PrivateKey.generate();
    _dappPrivateKey = keyPair;
    _dappPublicKey = keyPair.publicKey;
    
    // Clear phantom public key since we have a new keypair
    _phantomPublicKey = null;
    
    // Save keypair to storage so we can decrypt callback after app restart
    await _saveDappKeyPair();
    
    final pubKeyBase58 = bs58.base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
    debugPrint('WalletService: Generated fresh encryption keypair');
    debugPrint('WalletService: DApp public key: $pubKeyBase58');
  }
  
  /// Save DApp keypair to storage for callback decryption
  Future<void> _saveDappKeyPair() async {
    if (_dappPrivateKey == null || _dappPublicKey == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final privateKeyBase58 = bs58.base58.encode(Uint8List.fromList(_dappPrivateKey!.asTypedList));
      final publicKeyBase58 = bs58.base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
      
      await prefs.setString(_dappPrivateKeyKey, privateKeyBase58);
      await prefs.setString(_dappPublicKeyKey, publicKeyBase58);
      debugPrint('WalletService: Saved DApp keypair to storage');
    } catch (e) {
      debugPrint('WalletService: Error saving DApp keypair: $e');
    }
  }
  
  /// Restore DApp keypair from storage
  Future<bool> _restoreDappKeyPair() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privateKeyBase58 = prefs.getString(_dappPrivateKeyKey);
      final publicKeyBase58 = prefs.getString(_dappPublicKeyKey);
      
      if (privateKeyBase58 != null && publicKeyBase58 != null) {
        final privateKeyBytes = bs58.base58.decode(privateKeyBase58);
        _dappPrivateKey = PrivateKey(Uint8List.fromList(privateKeyBytes));
        _dappPublicKey = _dappPrivateKey!.publicKey;
        
        debugPrint('WalletService: Restored DApp keypair from storage');
        debugPrint('WalletService: DApp public key: $publicKeyBase58');
        return true;
      }
    } catch (e) {
      debugPrint('WalletService: Error restoring DApp keypair: $e');
    }
    return false;
  }
  
  /// Restore session keys from storage
  Future<void> _restoreSessionKeys() async {
    try {
      final hasKeyPair = await _restoreDappKeyPair();
      
      if (hasKeyPair) {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(_phantomPubKeyKey);
        
        if (stored != null) {
          _phantomPublicKey = bs58.base58.decode(stored);
          debugPrint('WalletService: Restored Phantom public key from storage');
        }
      } else {
        // No DApp keypair - clear any stale Phantom keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_phantomPubKeyKey);
        await prefs.remove(_sessionTokenKey);
      }
    } catch (e) {
      debugPrint('WalletService: Error restoring session keys: $e');
    }
  }
  
  /// Check if Phantom wallet is installed on the device
  Future<bool> _checkPhantomInstalled() async {
    try {
      final testUrl = Uri(scheme: 'phantom', host: 'ul', path: 'v1/connect');
      _phantomInstalled = await canLaunchUrl(testUrl);
      debugPrint('WalletService: Phantom installed: $_phantomInstalled');
      return _phantomInstalled;
    } catch (e) {
      debugPrint('WalletService: Error checking Phantom: $e');
      _phantomInstalled = false;
      return false;
    }
  }
  
  /// Public method to check if Phantom is installed
  Future<bool> checkPhantomInstalled() => _checkPhantomInstalled();

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
  
  /// Async wrapper for deep link handling
  Future<void> _handleDeepLinkAsync(Uri? uri) async {
    if (uri == null) return;
    
    debugPrint('WalletService: ========== DEEP LINK RECEIVED ==========');
    debugPrint('WalletService: URI: $uri');
    
    // Ensure keys are loaded before processing
    if (_dappPrivateKey == null) {
      debugPrint('WalletService: DApp key not in memory, restoring from storage...');
      await _restoreDappKeyPair();
      debugPrint('WalletService: After restore - DApp key available: ${_dappPrivateKey != null}');
    }
    
    // Now handle the deep link
    _handleDeepLink(uri);
  }

  /// Handle incoming deep links from Phantom
  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    
    debugPrint('WalletService: Received deep link: $uri');
    debugPrint('WalletService: URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
    debugPrint('WalletService: Query params: ${uri.queryParameters}');
    
    // Parse Phantom response - check scheme matches our app
    final scheme = uri.scheme.toLowerCase();
    if (scheme != SolanaConfig.appScheme.toLowerCase()) {
      debugPrint('WalletService: Ignoring deep link with scheme: $scheme');
      return;
    }
    
    // Use lowercase for case-insensitive matching
    final host = uri.host.toLowerCase();
    final pathSegment = uri.path.replaceAll('/', '').toLowerCase();
    final callbackType = host.isNotEmpty ? host : pathSegment;
    
    debugPrint('WalletService: Callback type detected: $callbackType');
    
    switch (callbackType) {
      case 'onconnect':
        _handleConnectResponse(uri);
        break;
      case 'ondisconnect':
        _handleDisconnectResponse();
        break;
      case 'onsigntransaction':
        _handleSignTransactionResponse(uri);
        break;
      case 'onsignandsendtransaction':
        _handleSignAndSendTransactionResponse(uri);
        break;
      default:
        debugPrint('WalletService: Unknown callback type: $callbackType');
    }
  }

  /// Handle connection response from Phantom (v1 encrypted protocol)
  void _handleConnectResponse(Uri uri) {
    final params = uri.queryParameters;
    
    debugPrint('WalletService: ========== CONNECT RESPONSE ==========');
    debugPrint('WalletService: Connect response URI: $uri');
    debugPrint('WalletService: Connect response params: $params');
    debugPrint('WalletService: DApp private key available: ${_dappPrivateKey != null}');
    debugPrint('WalletService: Connection completer active: ${_connectionCompleter != null}');
    
    // Check for errors first
    if (params.containsKey('errorCode')) {
      final errorCode = params['errorCode'];
      final errorMessage = params['errorMessage'] ?? 'Connection rejected';
      debugPrint('WalletService: ❌ Connection error [$errorCode]: $errorMessage');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(null);
      }
      return;
    }
    
    // Check if we have the DApp keypair (required for decryption)
    if (_dappPrivateKey == null) {
      debugPrint('WalletService: ❌ DApp private key is null - cannot decrypt response');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(null);
      }
      return;
    }
    
    try {
      // Phantom v1 returns:
      // - phantom_encryption_public_key: Phantom's public key for encryption
      // - nonce: The nonce used for encryption
      // - data: Encrypted payload containing the wallet address
      
      final phantomPubKeyStr = params['phantom_encryption_public_key'];
      final nonceStr = params['nonce'];
      final dataStr = params['data'];
      
      if (phantomPubKeyStr == null || nonceStr == null || dataStr == null) {
        debugPrint('WalletService: ❌ Missing required encryption parameters');
        debugPrint('WalletService: phantom_encryption_public_key: $phantomPubKeyStr');
        debugPrint('WalletService: nonce: $nonceStr');
        debugPrint('WalletService: data: $dataStr');
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(null);
        }
        return;
      }
      
      // Decode using bs58
      _phantomPublicKey = bs58.base58.decode(phantomPubKeyStr);
      debugPrint('WalletService: Phantom public key decoded (${_phantomPublicKey!.length} bytes)');
      
      final nonce = bs58.base58.decode(nonceStr);
      debugPrint('WalletService: Nonce decoded (${nonce.length} bytes)');
      
      if (nonce.length != _nonceLength) {
        debugPrint('WalletService: ❌ Invalid nonce length: ${nonce.length} (expected $_nonceLength)');
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(null);
        }
        return;
      }
      
      final encryptedData = bs58.base58.decode(dataStr);
      debugPrint('WalletService: Encrypted data decoded (${encryptedData.length} bytes)');
      
      // Create box with our private key and Phantom's public key
      final box = Box(
        myPrivateKey: _dappPrivateKey!,
        theirPublicKey: PublicKey(Uint8List.fromList(_phantomPublicKey!)),
      );
      
      // Decrypt the data
      final decryptedBytes = box.decrypt(
        ByteList(encryptedData),
        nonce: Uint8List.fromList(nonce),
      );
      
      final decryptedJson = utf8.decode(decryptedBytes);
      debugPrint('WalletService: Decrypted payload: $decryptedJson');
      
      // Parse the decrypted JSON
      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      // Extract wallet address and session
      final walletAddress = payload['public_key'] as String?;
      final session = payload['session'] as String?;
      
      if (walletAddress != null && walletAddress.isNotEmpty) {
        debugPrint('WalletService: ✅ Connected to wallet: $walletAddress');
        
        // Save wallet address and session token
        _saveWalletAddress(walletAddress);
        if (session != null) {
          _saveSessionToken(session);
        }
        // Save phantom public key for this session
        _savePhantomPublicKey(phantomPubKeyStr);
        
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(walletAddress);
        }
      } else {
        debugPrint('WalletService: ❌ No wallet address in decrypted payload');
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(null);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('WalletService: ❌ Error processing connect response: $e');
      debugPrint('WalletService: Stack trace: $stackTrace');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(null);
      }
    }
  }

  /// Handle disconnect response from Phantom
  void _handleDisconnectResponse() {
    _clearWalletData();
    debugPrint('WalletService: Wallet disconnected');
  }
  
  /// Handle sign transaction response from Phantom
  void _handleSignTransactionResponse(Uri uri) {
    final params = uri.queryParameters;
    
    if (params.containsKey('errorCode')) {
      final errorMessage = params['errorMessage'] ?? 'Transaction signing rejected';
      debugPrint('WalletService: Sign transaction error: $errorMessage');
      if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
        _signTransactionCompleter!.complete(null);
      }
      return;
    }
    
    try {
      final nonceStr = params['nonce'];
      final dataStr = params['data'];
      
      if (nonceStr == null || dataStr == null) {
        debugPrint('WalletService: ❌ Missing encryption params in sign response');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      final nonce = bs58.base58.decode(nonceStr);
      final encryptedData = bs58.base58.decode(dataStr);
      
      if (nonce.length != _nonceLength) {
        debugPrint('WalletService: ❌ Invalid nonce length in sign response: ${nonce.length}');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      if (_phantomPublicKey == null || _dappPrivateKey == null) {
        debugPrint('WalletService: ❌ Missing keys for decryption');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      final box = Box(
        myPrivateKey: _dappPrivateKey!,
        theirPublicKey: PublicKey(Uint8List.fromList(_phantomPublicKey!)),
      );
      
      final decryptedBytes = box.decrypt(
        ByteList(encryptedData),
        nonce: Uint8List.fromList(nonce),
      );
      
      final decryptedJson = utf8.decode(decryptedBytes);
      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      final signature = payload['signature'] as String?;
      if (signature != null) {
        debugPrint('WalletService: Transaction signed: $signature');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(signature);
        }
      } else {
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
      }
    } catch (e) {
      debugPrint('WalletService: Error processing sign response: $e');
      if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
        _signTransactionCompleter!.complete(null);
      }
    }
  }
  
  /// Handle sign and send transaction response from Phantom
  void _handleSignAndSendTransactionResponse(Uri uri) {
    final params = uri.queryParameters;
    
    if (params.containsKey('errorCode')) {
      final errorMessage = params['errorMessage'] ?? 'Transaction rejected';
      debugPrint('WalletService: Sign and send error: $errorMessage');
      if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
        _signTransactionCompleter!.complete(null);
      }
      return;
    }
    
    try {
      final nonceStr = params['nonce'];
      final dataStr = params['data'];
      
      if (nonceStr == null || dataStr == null) {
        debugPrint('WalletService: ❌ Missing encryption params in sign&send response');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      final nonce = bs58.base58.decode(nonceStr);
      final encryptedData = bs58.base58.decode(dataStr);
      
      if (nonce.length != _nonceLength) {
        debugPrint('WalletService: ❌ Invalid nonce length in sign&send response: ${nonce.length}');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      if (_phantomPublicKey == null || _dappPrivateKey == null) {
        debugPrint('WalletService: ❌ Missing keys for decryption');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
        return;
      }
      
      final box = Box(
        myPrivateKey: _dappPrivateKey!,
        theirPublicKey: PublicKey(Uint8List.fromList(_phantomPublicKey!)),
      );
      
      final decryptedBytes = box.decrypt(
        ByteList(encryptedData),
        nonce: Uint8List.fromList(nonce),
      );
      
      final decryptedJson = utf8.decode(decryptedBytes);
      final payload = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      final signature = payload['signature'] as String?;
      if (signature != null) {
        debugPrint('WalletService: Transaction sent: $signature');
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(signature);
        }
      } else {
        if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
          _signTransactionCompleter!.complete(null);
        }
      }
    } catch (e) {
      debugPrint('WalletService: Error processing sign&send response: $e');
      if (_signTransactionCompleter != null && !_signTransactionCompleter!.isCompleted) {
        _signTransactionCompleter!.complete(null);
      }
    }
  }

  /// Connect to Phantom wallet using v1 encrypted protocol
  /// Returns the wallet address if successful, null otherwise
  Future<String?> connect() async {
    // Generate fresh keypair for each connect attempt
    await _generateEncryptionKeyPair();
    
    _connectionCompleter = Completer<String?>();
    
    // Get the DApp's encryption public key in Base58
    final dappPubKeyBase58 = bs58.base58.encode(
      Uint8List.fromList(_dappPublicKey!.asTypedList),
    );
    
    debugPrint('WalletService: DApp encryption public key: $dappPubKeyBase58');
    debugPrint('WalletService: Key length: ${_dappPublicKey!.asTypedList.length} bytes');
    
    // Build the redirect link
    final redirectLink = '${SolanaConfig.appScheme}://onConnect';
    
    // CRITICAL: Use https://phantom.app/ul/v1/connect format (this works!)
    // Build manually to avoid any URI encoding issues
    final connectUrl = Uri.parse(
      'https://phantom.app/ul/v1/connect'
      '?app_url=${Uri.encodeComponent('https://plantgo.app')}'
      '&dapp_encryption_public_key=$dappPubKeyBase58'
      '&redirect_link=${Uri.encodeComponent(redirectLink)}'
      '&cluster=${SolanaConfig.cluster}'
    );
    
    debugPrint('WalletService: ========== CONNECT REQUEST ==========');
    debugPrint('WalletService: Connect URL: $connectUrl');
    
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
        onTimeout: () {
          debugPrint('WalletService: Connection timeout');
          return null;
        },
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
    final disconnectUrl = Uri(
      scheme: SolanaConfig.phantomScheme,
      host: 'ul',
      path: 'v1/disconnect',
      queryParameters: {
        'redirect_link': '${SolanaConfig.appScheme}://onDisconnect',
      },
    );
    
    await _launchPhantom(disconnectUrl);
  }
  
  /// Sign and send a transaction via Phantom (v1 encrypted protocol)
  /// Returns the transaction signature if successful
  Future<String?> signAndSendTransaction(String serializedTransaction) async {
    final walletAddress = await getConnectedWallet();
    if (walletAddress == null) {
      debugPrint('WalletService: No wallet connected');
      return null;
    }
    
    // Check if we have valid session keys
    if (_phantomPublicKey == null || _dappPrivateKey == null) {
      debugPrint('WalletService: Session not established, reconnecting...');
      final reconnected = await connect();
      if (reconnected == null) {
        debugPrint('WalletService: Failed to reconnect');
        return null;
      }
    }
    
    _signTransactionCompleter = Completer<String?>();
    
    // Get stored session token
    final session = await _getSessionToken();
    
    // Create the payload to encrypt
    final payload = {
      'transaction': serializedTransaction,
      if (session != null) 'session': session,
    };
    
    // Encrypt the payload
    final encryptedPayload = _encryptPayload(payload);
    if (encryptedPayload == null) {
      debugPrint('WalletService: Failed to encrypt transaction payload');
      _signTransactionCompleter?.complete(null);
      return null;
    }
    
    // Build the sign and send transaction URL
    final signUrl = Uri(
      scheme: SolanaConfig.phantomScheme,
      host: 'ul',
      path: 'v1/signAndSendTransaction',
      queryParameters: {
        'dapp_encryption_public_key': bs58.base58.encode(
          Uint8List.fromList(_dappPublicKey!.asTypedList),
        ),
        'nonce': encryptedPayload['nonce']!,
        'redirect_link': '${SolanaConfig.appScheme}://onSignAndSendTransaction',
        'payload': encryptedPayload['data']!,
      },
    );
    
    debugPrint('WalletService: Sign&Send URL: $signUrl');
    
    final launched = await _launchPhantom(signUrl);
    
    if (!launched) {
      _signTransactionCompleter?.complete(null);
      return null;
    }
    
    // Wait for response (with timeout)
    try {
      return await _signTransactionCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          debugPrint('WalletService: Sign transaction timeout');
          return null;
        },
      );
    } catch (e) {
      debugPrint('WalletService: Sign transaction timeout or error: $e');
      return null;
    }
  }
  
  /// Encrypt a payload using NaCl box
  Map<String, String>? _encryptPayload(Map<String, dynamic> payload) {
    try {
      if (_phantomPublicKey == null || _dappPrivateKey == null) {
        debugPrint('WalletService: Cannot encrypt - missing keys');
        return null;
      }
      
      final box = Box(
        myPrivateKey: _dappPrivateKey!,
        theirPublicKey: PublicKey(Uint8List.fromList(_phantomPublicKey!)),
      );
      
      // Generate a random nonce (24 bytes)
      final nonce = PineNaClUtils.randombytes(_nonceLength);
      
      debugPrint('WalletService: Generated nonce (${nonce.length} bytes)');
      
      // Encrypt the payload
      final payloadJson = jsonEncode(payload);
      final payloadBytes = utf8.encode(payloadJson);
      
      final encrypted = box.encrypt(
        Uint8List.fromList(payloadBytes),
        nonce: nonce,
      );
      
      return {
        'nonce': bs58.base58.encode(nonce),
        'data': bs58.base58.encode(Uint8List.fromList(encrypted.cipherText)),
      };
    } catch (e) {
      debugPrint('WalletService: Error encrypting payload: $e');
      return null;
    }
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

  /// Launch Phantom app via deep link
  Future<bool> _launchPhantom(Uri url) async {
    try {
      debugPrint('WalletService: Launching Phantom with URL: $url');
      
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        debugPrint('WalletService: Phantom launched successfully');
        return true;
      }
      
      // If direct launch failed, check if installed
      if (!await canLaunchUrl(url)) {
        debugPrint('WalletService: Phantom not installed, opening app store');
        await _openPhantomAppStore();
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('WalletService: Error launching Phantom: $e');
      await _openPhantomAppStore();
      return false;
    }
  }

  /// Open Phantom app store page based on platform
  Future<void> _openPhantomAppStore() async {
    Uri url;
    
    if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/phantom-solana-wallet/id1598432977');
    } else if (Platform.isAndroid) {
      final playStoreApp = Uri.parse('market://details?id=app.phantom');
      if (await canLaunchUrl(playStoreApp)) {
        await launchUrl(playStoreApp, mode: LaunchMode.externalApplication);
        return;
      }
      url = Uri.parse('https://play.google.com/store/apps/details?id=app.phantom');
    } else {
      url = Uri.parse('https://phantom.app/download');
    }
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Save wallet address to local storage
  Future<void> _saveWalletAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletAddressKey, address);
  }
  
  /// Save session token to local storage
  Future<void> _saveSessionToken(String session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, session);
  }
  
  /// Save Phantom public key to storage
  Future<void> _savePhantomPublicKey(String pubKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phantomPubKeyKey, pubKey);
  }
  
  /// Get session token from local storage
  Future<String?> _getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Clear wallet data from local storage
  Future<void> _clearWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walletAddressKey);
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_phantomPubKeyKey);
    await prefs.remove(_dappPrivateKeyKey);
    await prefs.remove(_dappPublicKeyKey);
    
    // Clear in-memory session data
    _phantomPublicKey = null;
    _dappPrivateKey = null;
    _dappPublicKey = null;
  }

  /// Get abbreviated wallet address for display (e.g., "7nYB...4xkA")
  static String abbreviateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
  }
}
