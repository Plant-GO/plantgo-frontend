import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../blockchain/solana_config.dart';
import '../blockchain/models/plant_counter.dart';

/// Service for direct Solana RPC calls (MVP/Testing mode)
/// 
/// This service interacts directly with Solana devnet via JSON-RPC.
/// For production, some operations would need a backend server
/// with the mintAuthority keypair for signing transactions.
class SolanaRpcService {
  /// Singleton instance
  static final SolanaRpcService _instance = SolanaRpcService._internal();
  factory SolanaRpcService() => _instance;
  SolanaRpcService._internal();

  final http.Client _client = http.Client();
  
  // RPC request ID counter
  int _requestId = 0;

  /// Get next request ID
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
        throw SolanaRpcException(
          'RPC request failed with status ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data.containsKey('error')) {
        final error = data['error'];
        throw SolanaRpcException(
          error['message'] ?? 'Unknown RPC error',
          code: error['code'],
        );
      }

      return data;
    } catch (e) {
      if (e is SolanaRpcException) rethrow;
      throw SolanaRpcException('RPC call failed: $e');
    }
  }

  // ============ Account Queries ============

  /// Get account info for a public key
  Future<Map<String, dynamic>?> getAccountInfo(String pubkey) async {
    try {
      final result = await _rpcCall('getAccountInfo', [
        pubkey,
        {'encoding': 'base64'},
      ]);

      return result['result']?['value'];
    } catch (e) {
      debugPrint('SolanaRpcService: Error getting account info: $e');
      return null;
    }
  }

  /// Check if an account exists on-chain
  Future<bool> accountExists(String pubkey) async {
    final info = await getAccountInfo(pubkey);
    return info != null;
  }

  /// Get SOL balance for an account
  Future<double> getBalance(String pubkey) async {
    try {
      final result = await _rpcCall('getBalance', [pubkey]);
      final lamports = result['result']?['value'] ?? 0;
      return lamports / 1e9; // Convert lamports to SOL
    } catch (e) {
      debugPrint('SolanaRpcService: Error getting balance: $e');
      return 0;
    }
  }

  /// Get recent blockhash (needed for transactions)
  Future<String?> getRecentBlockhash() async {
    try {
      final result = await _rpcCall('getLatestBlockhash', [
        {'commitment': 'finalized'},
      ]);
      return result['result']?['value']?['blockhash'];
    } catch (e) {
      debugPrint('SolanaRpcService: Error getting blockhash: $e');
      return null;
    }
  }

  /// Request airdrop (devnet only) - for testing
  Future<String?> requestAirdrop(String pubkey, {double amount = 1.0}) async {
    if (!SolanaConfig.isDevnet) {
      debugPrint('SolanaRpcService: Airdrop only available on devnet');
      return null;
    }

    try {
      final lamports = (amount * 1e9).toInt();
      final result = await _rpcCall('requestAirdrop', [pubkey, lamports]);
      final signature = result['result'];
      debugPrint('✅ Airdrop requested: $signature');
      return signature;
    } catch (e) {
      debugPrint('SolanaRpcService: Airdrop failed: $e');
      return null;
    }
  }

  // ============ Program Data Queries ============

  /// Derive PlantCounter PDA address
  /// Matches the Solana program's get_plant_counter_address function
  /// 
  /// Seeds: ["plant_counter", plant_name_bytes]
  String derivePlantCounterPda(String plantName) {
    // For MVP, we'll use a simplified address derivation
    // In production, this would use proper PDA derivation with SHA256
    // For now, we return a predictable identifier
    final normalized = plantName.toLowerCase().trim().replaceAll(' ', '_');
    return 'plant_counter_$normalized';
  }

  /// Derive OwnershipRecord PDA address
  /// Matches the Solana program's get_ownership_record_address function
  /// 
  /// Seeds: ["ownership", owner_wallet_bytes, plant_name_bytes, card_type_u8]
  String deriveOwnershipRecordPda(
    String ownerWallet,
    String plantName,
    int cardType,
  ) {
    final normalized = plantName.toLowerCase().trim().replaceAll(' ', '_');
    return 'ownership_${ownerWallet}_${normalized}_$cardType';
  }

  /// Get PlantCounter data from on-chain (or Firestore cache for MVP)
  /// Returns null if the plant has never been discovered
  Future<PlantCounter?> getPlantCounter(String plantName) async {
    try {
      // For MVP, we'll check Firestore instead of on-chain
      // In production, this would decode the on-chain PDA data
      debugPrint('🔍 Checking PlantCounter for: $plantName');
      
      // The PDA address would be derived and queried
      // final pdaAddress = derivePlantCounterPda(plantName);
      // final accountInfo = await getAccountInfo(pdaAddress);
      
      // For MVP, return null to indicate this is handled by Firestore
      return null;
    } catch (e) {
      debugPrint('SolanaRpcService: Error getting PlantCounter: $e');
      return null;
    }
  }

  // ============ Transaction Status ============

  /// Get transaction status
  Future<Map<String, dynamic>?> getTransaction(String signature) async {
    try {
      final result = await _rpcCall('getTransaction', [
        signature,
        {'encoding': 'jsonParsed', 'maxSupportedTransactionVersion': 0},
      ]);
      return result['result'];
    } catch (e) {
      debugPrint('SolanaRpcService: Error getting transaction: $e');
      return null;
    }
  }

  /// Confirm a transaction
  Future<bool> confirmTransaction(
    String signature, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final result = await _rpcCall('getSignatureStatuses', [
          [signature],
        ]);

        final status = result['result']?['value']?[0];
        if (status != null) {
          if (status['err'] != null) {
            debugPrint('❌ Transaction failed: ${status['err']}');
            return false;
          }
          
          final confirmations = status['confirmations'];
          if (confirmations != null || status['confirmationStatus'] == 'finalized') {
            debugPrint('✅ Transaction confirmed: $signature');
            return true;
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('SolanaRpcService: Error confirming transaction: $e');
      }
    }

    debugPrint('⏰ Transaction confirmation timeout: $signature');
    return false;
  }

  // ============ Health Check ============

  /// Check if RPC is healthy
  Future<bool> isHealthy() async {
    try {
      final result = await _rpcCall('getHealth', []);
      return result['result'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Get current slot
  Future<int?> getSlot() async {
    try {
      final result = await _rpcCall('getSlot', []);
      return result['result'];
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Exception for Solana RPC errors
class SolanaRpcException implements Exception {
  final String message;
  final int? code;

  SolanaRpcException(this.message, {this.code});

  @override
  String toString() => 'SolanaRpcException: $message${code != null ? ' (code: $code)' : ''}';
}
