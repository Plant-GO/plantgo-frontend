import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../blockchain/solana_config.dart';
import 'backend_url_provider.dart';

/// Service for fetching NFTs from the Solana blockchain.
///
/// This service queries the blockchain directly to get NFTs owned by a wallet.
class BlockchainNFTService {
  static final BlockchainNFTService _instance =
      BlockchainNFTService._internal();
  factory BlockchainNFTService() => _instance;
  BlockchainNFTService._internal();

  /// Fetch all NFTs owned by a wallet address
  Future<List<BlockchainNFT>> getWalletNFTs(String walletAddress) async {
    try {
      debugPrint('BlockchainNFTService: Fetching NFTs for $walletAddress');

      // Get all token accounts owned by the wallet
      final tokenAccounts = await _getTokenAccountsByOwner(walletAddress);
      debugPrint(
        'BlockchainNFTService: Found ${tokenAccounts.length} token accounts',
      );

      // Filter for NFTs (tokens with amount = 1 and decimals = 0)
      final nfts = <BlockchainNFT>[];

      for (final account in tokenAccounts) {
        try {
          final tokenData = account['account']['data']['parsed']['info'];
          final mint = tokenData['mint'] as String;
          final amount = tokenData['tokenAmount']['uiAmount'] as num;
          final decimals = tokenData['tokenAmount']['decimals'] as int;

          // NFTs have exactly 1 token with 0 decimals
          if (amount == 1 && decimals == 0) {
            debugPrint('BlockchainNFTService: Found NFT mint: $mint');

            // Get metadata for this NFT
            final metadata = await _getTokenMetadata(mint);

            if (metadata != null) {
              nfts.add(
                BlockchainNFT(
                  mint: mint,
                  name: metadata['name'] ?? 'Unknown NFT',
                  symbol: metadata['symbol'] ?? '',
                  uri: metadata['uri'] ?? '',
                  image: metadata['image'] ?? '',
                  description: metadata['description'] ?? '',
                  attributes: metadata['attributes'] ?? [],
                ),
              );
            } else {
              // Add NFT even without metadata
              nfts.add(
                BlockchainNFT(
                  mint: mint,
                  name: 'NFT #${mint.substring(0, 8)}',
                  symbol: 'NFT',
                  uri: '',
                  image: '',
                  description: 'NFT on Solana',
                  attributes: [],
                ),
              );
            }
          }
        } catch (e) {
          debugPrint(
            'BlockchainNFTService: Error processing token account: $e',
          );
        }
      }

      debugPrint('BlockchainNFTService: Found ${nfts.length} NFTs');
      return nfts;
    } catch (e) {
      debugPrint('BlockchainNFTService: Error fetching NFTs: $e');
      return [];
    }
  }

  /// Get all token accounts owned by a wallet
  Future<List<dynamic>> _getTokenAccountsByOwner(String walletAddress) async {
    final response = await http.post(
      Uri.parse(SolanaConfig.rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'getTokenAccountsByOwner',
        'params': [
          walletAddress,
          {'programId': 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'},
          {'encoding': 'jsonParsed'},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null && data['result']['value'] != null) {
        return data['result']['value'] as List;
      }
    }

    return [];
  }

  /// Get metadata for an NFT by its mint address
  Future<Map<String, dynamic>?> _getTokenMetadata(String mintAddress) async {
    try {
      // First, find the metadata PDA (Program Derived Address)
      final metadataPDA = await _findMetadataPDA(mintAddress);

      if (metadataPDA == null) {
        debugPrint(
          'BlockchainNFTService: Could not find metadata PDA for $mintAddress',
        );
        return null;
      }

      // Get the account info for the metadata PDA
      final response = await http.post(
        Uri.parse(SolanaConfig.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getAccountInfo',
          'params': [
            metadataPDA,
            {'encoding': 'base64'},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['value'] != null) {
          final accountData = data['result']['value']['data'][0] as String;
          return _parseMetadataAccount(accountData);
        }
      }

      return null;
    } catch (e) {
      debugPrint('BlockchainNFTService: Error fetching metadata: $e');
      return null;
    }
  }

  /// Find the metadata PDA for a mint address
  /// Uses the Metaplex Token Metadata Program
  Future<String?> _findMetadataPDA(String mintAddress) async {
    // Metaplex Token Metadata Program ID: metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s

    try {
      // Call our backend to compute the PDA (since Dart doesn't have easy PDA derivation)
      final backendUrl = await BackendUrlProvider.getBackendUrl();
      final response = await http.get(
        Uri.parse('$backendUrl/api/nft/metadata-pda?mint=$mintAddress'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['pda'] as String?;
      }

      // Fallback: Return null if we can't compute PDA
      // The backend endpoint might not exist yet
      return null;
    } catch (e) {
      debugPrint('BlockchainNFTService: Error finding metadata PDA: $e');
      return null;
    }
  }

  /// Parse metadata account data
  Map<String, dynamic>? _parseMetadataAccount(String base64Data) {
    try {
      final bytes = base64Decode(base64Data);

      // Metaplex metadata account structure:
      // - 1 byte: key (always 4 for Metadata)
      // - 32 bytes: update authority
      // - 32 bytes: mint
      // - 4 bytes: name length + name string
      // - 4 bytes: symbol length + symbol string
      // - 4 bytes: uri length + uri string
      // ... more fields

      int offset = 1 + 32 + 32; // Skip key, update authority, mint

      // Read name
      final nameLength =
          bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
      offset += 4;
      final name = String.fromCharCodes(
        bytes.sublist(offset, offset + nameLength),
      ).replaceAll('\x00', '').trim();
      offset += nameLength;

      // Read symbol
      final symbolLength =
          bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
      offset += 4;
      final symbol = String.fromCharCodes(
        bytes.sublist(offset, offset + symbolLength),
      ).replaceAll('\x00', '').trim();
      offset += symbolLength;

      // Read URI
      final uriLength =
          bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
      offset += 4;
      final uri = String.fromCharCodes(
        bytes.sublist(offset, offset + uriLength),
      ).replaceAll('\x00', '').trim();

      debugPrint(
        'BlockchainNFTService: Parsed metadata - Name: $name, Symbol: $symbol, URI: $uri',
      );

      // If we have a URI, fetch the full metadata
      if (uri.isNotEmpty) {
        return {'name': name, 'symbol': symbol, 'uri': uri};
      }

      return {'name': name, 'symbol': symbol, 'uri': uri};
    } catch (e) {
      debugPrint('BlockchainNFTService: Error parsing metadata: $e');
      return null;
    }
  }

  /// Fetch off-chain metadata from URI (e.g., Arweave, IPFS)
  Future<Map<String, dynamic>?> fetchOffChainMetadata(String uri) async {
    try {
      if (uri.isEmpty) return null;

      // Convert IPFS URLs to HTTP gateway
      String httpUri = uri;
      if (uri.startsWith('ipfs://')) {
        httpUri = uri.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
      }

      final response = await http.get(Uri.parse(httpUri));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('BlockchainNFTService: Error fetching off-chain metadata: $e');
      return null;
    }
  }

  /// Get explorer URL for an NFT
  String getExplorerUrl(String mintAddress) {
    final network = SolanaConfig.network;
    final cluster = network == 'mainnet-beta' ? '' : '?cluster=$network';
    return 'https://explorer.solana.com/address/$mintAddress$cluster';
  }
}

/// Represents an NFT on the Solana blockchain
class BlockchainNFT {
  final String mint;
  final String name;
  final String symbol;
  final String uri;
  final String image;
  final String description;
  final List<dynamic> attributes;

  BlockchainNFT({
    required this.mint,
    required this.name,
    required this.symbol,
    required this.uri,
    required this.image,
    required this.description,
    required this.attributes,
  });

  /// Get the explorer URL for this NFT
  String get explorerUrl {
    final network = SolanaConfig.network;
    final cluster = network == 'mainnet-beta' ? '' : '?cluster=$network';
    return 'https://explorer.solana.com/address/$mint$cluster';
  }

  /// Get a specific attribute by trait type
  String? getAttribute(String traitType) {
    for (final attr in attributes) {
      if (attr is Map && attr['trait_type'] == traitType) {
        return attr['value']?.toString();
      }
    }
    return null;
  }

  @override
  String toString() => 'BlockchainNFT($name, mint: ${mint.substring(0, 8)}...)';
}
