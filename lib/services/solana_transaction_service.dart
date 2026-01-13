import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../blockchain/solana_config.dart';
import 'wallet_service.dart';
import 'backend_url_provider.dart';

/// Service for building and sending Solana transactions.
///
/// This service handles:
/// 1. Building transactions for NFT minting
/// 2. Sending transactions to Phantom for signing
/// 3. Broadcasting signed transactions to Solana network
class SolanaTransactionService {
  static final SolanaTransactionService _instance =
      SolanaTransactionService._internal();
  factory SolanaTransactionService() => _instance;
  SolanaTransactionService._internal();

  final http.Client _client = http.Client();
  final WalletService _walletService = WalletService();

  int _requestId = 0;
  int get _nextId => ++_requestId;

  // ============ RPC Helper Methods ============

  /// Make a JSON-RPC call to Solana
  Future<Map<String, dynamic>> _rpcCall(
    String method,
    List<dynamic> params,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(SolanaConfig.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': _nextId,
          'method': method,
          'params': params,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('RPC request failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw Exception(data['error']['message'] ?? 'RPC error');
      }

      return data;
    } catch (e) {
      debugPrint('SolanaTransactionService: RPC error: $e');
      rethrow;
    }
  }

  /// Get recent blockhash for transaction
  Future<String?> getRecentBlockhash() async {
    try {
      final result = await _rpcCall('getLatestBlockhash', [
        {'commitment': 'finalized'},
      ]);

      return result['result']?['value']?['blockhash'];
    } catch (e) {
      debugPrint('SolanaTransactionService: Error getting blockhash: $e');
      return null;
    }
  }

  /// Get minimum balance for rent exemption
  Future<int> getMinimumBalanceForRentExemption(int dataSize) async {
    try {
      final result = await _rpcCall('getMinimumBalanceForRentExemption', [
        dataSize,
      ]);
      return result['result'] ?? 0;
    } catch (e) {
      debugPrint('SolanaTransactionService: Error getting rent exemption: $e');
      return 0;
    }
  }

  /// Get account balance in SOL
  Future<double> getBalance(String pubkey) async {
    try {
      final result = await _rpcCall('getBalance', [pubkey]);
      final lamports = result['result']?['value'] ?? 0;
      return lamports / 1e9;
    } catch (e) {
      debugPrint('SolanaTransactionService: Error getting balance: $e');
      return 0;
    }
  }

  /// Confirm a transaction
  Future<bool> confirmTransaction(
    String signature, {
    int maxRetries = 30,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final result = await _rpcCall('getSignatureStatuses', [
          [signature],
        ]);
        final value = result['result']?['value']?[0];

        if (value != null) {
          final confirmationStatus = value['confirmationStatus'];
          if (confirmationStatus == 'confirmed' ||
              confirmationStatus == 'finalized') {
            debugPrint(
              'SolanaTransactionService: Transaction confirmed: $signature',
            );
            return true;
          }
          if (value['err'] != null) {
            debugPrint(
              'SolanaTransactionService: Transaction failed: ${value['err']}',
            );
            return false;
          }
        }

        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('SolanaTransactionService: Error confirming: $e');
      }
    }

    return false;
  }

  /// Request airdrop (devnet only) - for testing
  Future<String?> requestAirdrop(String pubkey, {double sol = 1.0}) async {
    if (!SolanaConfig.isDevnet) {
      debugPrint('SolanaTransactionService: Airdrop only available on devnet');
      return null;
    }

    try {
      final lamports = (sol * 1e9).toInt();
      final result = await _rpcCall('requestAirdrop', [pubkey, lamports]);

      final signature = result['result'] as String?;
      if (signature != null) {
        debugPrint('SolanaTransactionService: Airdrop requested: $signature');

        // Wait for confirmation
        final confirmed = await confirmTransaction(signature);
        if (confirmed) {
          debugPrint('SolanaTransactionService: Airdrop confirmed!');
        }
      }

      return signature;
    } catch (e) {
      debugPrint('SolanaTransactionService: Airdrop error: $e');
      return null;
    }
  }

  // ============ NFT Minting via Phantom ============

  /// Mint an NFT by building the transaction and sending to Phantom for signing
  ///
  /// For MVP, this creates a simplified memo transaction as proof of concept.
  /// Full NFT minting requires the Metaplex SDK or backend integration.
  Future<MintTransactionResult> mintNFTViaPhantom({
    required String walletAddress,
    required String plantName,
    required String rarity,
    String? imageUrl,
  }) async {
    try {
      debugPrint('SolanaTransactionService: Building mint transaction...');

      // Get recent blockhash
      final blockhash = await getRecentBlockhash();
      if (blockhash == null) {
        return MintTransactionResult(
          success: false,
          error: 'Failed to get blockhash',
        );
      }

      // For MVP: Create a memo transaction as proof of concept
      // This proves the wallet connection and signing works
      // Full NFT minting requires Metaplex integration
      final memoData = jsonEncode({
        'type': 'plantgo_nft_mint',
        'plant': plantName,
        'rarity': rarity,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Build serialized transaction (base64)
      // Note: This is a placeholder - real implementation needs proper transaction building
      final serializedTx = _buildMemoTransaction(
        walletAddress: walletAddress,
        blockhash: blockhash,
        memo: memoData,
      );

      if (serializedTx == null) {
        return MintTransactionResult(
          success: false,
          error: 'Failed to build transaction',
        );
      }

      // Send to Phantom for signing
      debugPrint('SolanaTransactionService: Sending to Phantom for signing...');
      final signature = await _walletService.signAndSendTransaction(
        serializedTx,
      );

      if (signature == null) {
        return MintTransactionResult(
          success: false,
          error: 'User rejected or signing failed',
        );
      }

      // Confirm transaction
      final confirmed = await confirmTransaction(signature);

      return MintTransactionResult(
        success: confirmed,
        signature: signature,
        explorerUrl: SolanaConfig.getExplorerUrl(signature),
        error: confirmed ? null : 'Transaction not confirmed',
      );
    } catch (e) {
      debugPrint('SolanaTransactionService: Mint error: $e');
      return MintTransactionResult(success: false, error: e.toString());
    }
  }

  /// Build a memo transaction (for proof of concept)
  /// In production, this would be replaced with proper Metaplex NFT minting
  String? _buildMemoTransaction({
    required String walletAddress,
    required String blockhash,
    required String memo,
  }) {
    // NOTE: Building raw Solana transactions in Dart requires:
    // 1. Proper instruction encoding
    // 2. Account key serialization
    // 3. Transaction signature placeholders
    //
    // For a full implementation, consider:
    // - Using a Dart Solana SDK (solana package)
    // - Or building transactions on a backend server
    // - Or using Phantom's built-in transaction building

    // For now, return null to indicate we need backend support
    // The wallet connection and deep linking is ready!
    debugPrint(
      'SolanaTransactionService: Transaction building requires backend or Solana SDK',
    );
    return null;
  }

  // ============ Backend-Assisted Minting ============

  /// Mint NFT using backend server
  /// This is the recommended approach for production
  Future<MintTransactionResult> mintNFTViaBackend({
    required String walletAddress,
    required String plantName,
    required String rarity,
    required String treasureId,
    String? imageUrl,
  }) async {
    try {
      debugPrint('SolanaTransactionService: Requesting mint from backend...');

      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _client.post(
        Uri.parse('$backendUrl${SolanaConfig.mintEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'walletAddress': walletAddress,
          'plantName': plantName,
          'rarity': rarity,
          'treasureId': treasureId,
          'imageUrl': imageUrl,
          'cluster': SolanaConfig.cluster,
        }),
      );

      if (response.statusCode != 200) {
        return MintTransactionResult(
          success: false,
          error: 'Backend error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        return MintTransactionResult(
          success: true,
          signature: data['signature'],
          nftMint: data['nftMint'],
          explorerUrl: data['explorerUrl'],
        );
      } else {
        return MintTransactionResult(
          success: false,
          error: data['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      debugPrint('SolanaTransactionService: Backend mint error: $e');
      return MintTransactionResult(success: false, error: e.toString());
    }
  }
}

/// Result of an NFT minting transaction
class MintTransactionResult {
  final bool success;
  final String? signature;
  final String? nftMint;
  final String? explorerUrl;
  final String? error;

  MintTransactionResult({
    required this.success,
    this.signature,
    this.nftMint,
    this.explorerUrl,
    this.error,
  });
}
