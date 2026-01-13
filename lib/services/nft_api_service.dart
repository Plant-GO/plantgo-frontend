import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../blockchain/blockchain.dart';
import 'backend_url_provider.dart';

/// Service for interacting with the PlantGO backend API for NFT operations.
///
/// The backend handles:
/// - Transaction signing with mintAuthority (kept secret)
/// - Calling the Solana program
/// - Returning transaction signatures to the app
class NFTApiService {
  /// Singleton instance
  static final NFTApiService _instance = NFTApiService._internal();
  factory NFTApiService() => _instance;
  NFTApiService._internal();

  /// HTTP client for API calls
  final http.Client _client = http.Client();

  /// Timeout for API requests
  static const Duration _timeout = Duration(seconds: 30);

  // ============ Mint NFT Endpoints ============

  /// Mint a Plant Discovery NFT
  ///
  /// Called when user discovers a plant via the scanner.
  /// Backend determines the rarity based on on-chain data.
  ///
  /// [walletAddress] - User's Solana wallet public key
  /// [plantName] - Name of the discovered plant
  /// [isNewSpecies] - Whether this is a completely new species discovery
  /// [imageUrl] - Optional URL to the plant image
  ///
  /// Returns the minted NFTCard or throws an exception on failure.
  Future<MintResult> mintPlantDiscoveryNFT({
    required String walletAddress,
    required String plantName,
    required bool isNewSpecies,
    String? imageUrl,
    String? scientificName,
  }) async {
    try {
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _client
          .post(
            Uri.parse('$backendUrl${SolanaConfig.mintEndpoint}'),
            headers: _headers,
            body: jsonEncode({
              'wallet_address': walletAddress,
              'plant_name': plantName,
              'is_new_species': isNewSpecies,
              'quiz_winner': null, // Not a quiz mint
              'flow_type': 'plant_discovery',
              'image_url': imageUrl,
              'scientific_name': scientificName,
            }),
          )
          .timeout(_timeout);

      return _handleMintResponse(response);
    } catch (e) {
      debugPrint('NFTApiService: Mint plant discovery error: $e');
      rethrow;
    }
  }

  /// Mint a Quiz NFT
  ///
  /// Called when user participates in or wins a quiz.
  /// Backend determines whether to mint CodexOfInsight or AscendantSeal.
  ///
  /// [walletAddress] - User's Solana wallet public key
  /// [plantName] - Name of the plant the quiz was about
  /// [isWinner] - Whether the user won the quiz
  ///
  /// Returns the minted NFTCard or throws an exception on failure.
  Future<MintResult> mintQuizNFT({
    required String walletAddress,
    required String plantName,
    required bool isWinner,
  }) async {
    try {
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _client
          .post(
            Uri.parse('$backendUrl${SolanaConfig.mintEndpoint}'),
            headers: _headers,
            body: jsonEncode({
              'wallet_address': walletAddress,
              'plant_name': plantName,
              'is_new_species': null, // Not a plant discovery
              'quiz_winner': isWinner,
              'flow_type': 'quiz',
            }),
          )
          .timeout(_timeout);

      return _handleMintResponse(response);
    } catch (e) {
      debugPrint('NFTApiService: Mint quiz NFT error: $e');
      rethrow;
    }
  }

  // ============ Query Endpoints ============

  /// Get all NFTs owned by a user
  ///
  /// [walletAddress] - User's Solana wallet public key
  ///
  /// Returns a list of NFTCard objects owned by the user.
  Future<List<NFTCard>> getUserNFTs(String walletAddress) async {
    try {
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _client
          .get(
            Uri.parse(
              '$backendUrl${SolanaConfig.userNftsEndpoint}/$walletAddress',
            ),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nfts = (data['nfts'] as List<dynamic>?) ?? [];
        return nfts.map((json) => NFTCard.fromJson(json)).toList();
      } else {
        throw NFTApiException(
          'Failed to fetch NFTs',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NFTApiException) rethrow;
      debugPrint('NFTApiService: Get user NFTs error: $e');
      throw NFTApiException('Network error: $e');
    }
  }

  /// Check if user already owns a specific plant card
  ///
  /// [walletAddress] - User's Solana wallet public key
  /// [plantName] - Name of the plant to check
  /// [rarity] - Optional specific rarity to check
  ///
  /// Returns true if the user already owns this card.
  Future<bool> checkOwnership({
    required String walletAddress,
    required String plantName,
    CardRarity? rarity,
  }) async {
    try {
      final queryParams = {
        'wallet': walletAddress,
        'plant': plantName,
        if (rarity != null) 'rarity': rarity.name,
      };

      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final uri = Uri.parse(
        '$backendUrl/api/nft/check-ownership',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['owns'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('NFTApiService: Check ownership error: $e');
      return false; // Assume not owned on error
    }
  }

  /// Get plant counter data (mint statistics for a plant)
  ///
  /// [plantName] - Name of the plant
  ///
  /// Returns PlantCounter with mint counts.
  Future<PlantCounter?> getPlantCounter(String plantName) async {
    try {
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await _client
          .get(
            Uri.parse('$backendUrl/api/plant-counter/$plantName'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlantCounter.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('NFTApiService: Get plant counter error: $e');
      return null;
    }
  }

  // ============ Helpers ============

  /// Common headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // TODO: Add authentication token if required
    // 'Authorization': 'Bearer $token',
  };

  /// Handle mint response from backend
  MintResult _handleMintResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MintResult(
        success: true,
        nftCard: NFTCard.fromJson(data['nft'] ?? data),
        transactionSignature:
            data['signature'] ?? data['transaction_signature'],
        message: data['message'] ?? 'NFT minted successfully!',
      );
    } else if (response.statusCode == 409) {
      // User already owns this card
      return MintResult(
        success: false,
        message: data['message'] ?? 'You already own this card!',
        errorCode: 'ALREADY_OWNED',
      );
    } else {
      throw NFTApiException(
        data['message'] ?? 'Mint failed',
        statusCode: response.statusCode,
        errorCode: data['error_code'],
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Result of a mint operation
class MintResult {
  final bool success;
  final NFTCard? nftCard;
  final String? transactionSignature;
  final String message;
  final String? errorCode;

  const MintResult({
    required this.success,
    this.nftCard,
    this.transactionSignature,
    required this.message,
    this.errorCode,
  });

  /// Get Solana Explorer URL for the transaction
  String? get explorerUrl {
    if (transactionSignature == null) return null;
    return SolanaConfig.getExplorerUrl(transactionSignature!);
  }
}

/// Exception for NFT API errors
class NFTApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  NFTApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() =>
      'NFTApiException: $message (status: $statusCode, code: $errorCode)';
}
