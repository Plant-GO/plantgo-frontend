import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

/// Provider for Phantom wallet connection state.
/// 
/// Manages wallet connection, disconnection, and provides reactive state.
class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  /// Current wallet address (null if not connected)
  String? _walletAddress;
  String? get walletAddress => _walletAddress;

  /// Whether wallet is connected
  bool get isConnected => _walletAddress != null && _walletAddress!.isNotEmpty;

  /// Abbreviated wallet address for display
  String get displayAddress =>
      _walletAddress != null ? WalletService.abbreviateAddress(_walletAddress!) : '';

  /// Connection state
  WalletConnectionState _connectionState = WalletConnectionState.disconnected;
  WalletConnectionState get connectionState => _connectionState;

  /// Whether currently connecting
  bool get isConnecting => _connectionState == WalletConnectionState.connecting;

  /// Error message if connection failed
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initialize the provider
  Future<void> initialize() async {
    await _walletService.initialize();
    await _loadSavedWallet();
  }

  /// Load saved wallet from local storage
  Future<void> _loadSavedWallet() async {
    final address = await _walletService.getConnectedWallet();
    if (address != null && address.isNotEmpty) {
      _walletAddress = address;
      _connectionState = WalletConnectionState.connected;
      notifyListeners();
    }
  }

  /// Connect to Phantom wallet
  Future<bool> connect() async {
    if (isConnecting) return false;

    _connectionState = WalletConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final address = await _walletService.connect();
      
      if (address != null) {
        _walletAddress = address;
        _connectionState = WalletConnectionState.connected;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _connectionState = WalletConnectionState.disconnected;
        _errorMessage = 'Connection cancelled or failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('WalletProvider: Connection error: $e');
      _connectionState = WalletConnectionState.error;
      _errorMessage = 'Failed to connect: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from wallet
  Future<void> disconnect() async {
    try {
      await _walletService.disconnect();
    } catch (e) {
      debugPrint('WalletProvider: Disconnect error: $e');
    }
    
    _walletAddress = null;
    _connectionState = WalletConnectionState.disconnected;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh connection state from local storage
  Future<void> refreshState() async {
    await _loadSavedWallet();
  }

  /// Clear any error state
  void clearError() {
    _errorMessage = null;
    if (_connectionState == WalletConnectionState.error) {
      _connectionState = WalletConnectionState.disconnected;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _walletService.dispose();
    super.dispose();
  }
}

/// Wallet connection states
enum WalletConnectionState {
  /// No wallet connected
  disconnected,
  
  /// Currently connecting to wallet
  connecting,
  
  /// Successfully connected
  connected,
  
  /// Error during connection
  error,
}
