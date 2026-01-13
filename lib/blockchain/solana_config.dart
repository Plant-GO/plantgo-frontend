/// Solana network configuration for PlantGO NFT integration.
/// 
/// Contains program IDs, RPC endpoints, and mint addresses.
class SolanaConfig {
  /// Private constructor
  SolanaConfig._();

  // ============ Network Configuration ============
  
  /// Current network (devnet/mainnet-beta)
  static const String network = 'devnet';
  
  /// RPC URL for Solana API calls
  static const String rpcUrl = 'https://api.devnet.solana.com';
  
  /// WebSocket URL for real-time updates
  static const String wsUrl = 'wss://api.devnet.solana.com';
  
  /// Deployed PlantGO NFT program ID
  static const String programId = '3JD2GSJBLPYwwHLmBzh5MRpDZp2eh4KukzHvR8CvmcAc';
  
  /// Deployment transaction signature (for verification)
  static const String deploymentSignature = 'qUCYitjUmixJS17MwKUjQdxG5nztTkDWmgfQ8a2NjEsTtFyxCxb5dMPYA';

  // ============ Mint Addresses ============
  // These are created once by admin and stored here
  // TODO: Update with actual mint addresses after CreateMint calls
  
  /// Common card mint (GenesisFragment)
  static const String commonMint = '';
  
  /// Rare card mint (AstralShard)  
  static const String rareMint = '';
  
  /// Epic card mint (MythicCrest)
  static const String epicMint = '';
  
  /// Aurora mint (AuroraSeed - new species discovery)
  static const String auroraMint = '';
  
  /// Primordial mint (PrimordialRelic - first discovery)
  static const String primordialMint = '';
  
  /// Codex mint (CodexOfInsight - quiz participation)
  static const String codexMint = '';
  
  /// Ascendant mint (AscendantSeal - quiz winner)
  static const String ascendantMint = '';

  // ============ Phantom Wallet ============
  
  /// Phantom app scheme for deep linking
  static const String phantomScheme = 'phantom';
  
  /// App callback scheme for Phantom responses
  static const String appScheme = 'plantgo';
  
  /// Cluster parameter for Phantom (devnet/mainnet-beta)
  static const String cluster = 'devnet';

  // ============ Backend API ============
  
  /// Backend API base URL for NFT minting
  /// For development: Use your local IP (not localhost for mobile)
  /// For production: Update to your deployed backend URL
  /// NOTE: This is now dynamically loaded from SharedPreferences
  /// Use BackendConfigScreen to set the IP address
  static const String backendApiUrl = 'http://10.0.2.2:3001'; // Default fallback
  
  /// NFT minting endpoint
  static const String mintEndpoint = '/api/nft/mint';
  
  /// Get user's NFTs endpoint
  static const String userNftsEndpoint = '/api/nft/user';
  
  /// Check if backend is available
  static const bool useBackend = true;

  // ============ Helpers ============
  
  /// Returns Solana Explorer URL for a transaction
  static String getExplorerUrl(String signature) {
    final cluster = network == 'mainnet-beta' ? '' : '?cluster=$network';
    return 'https://explorer.solana.com/tx/$signature$cluster';
  }
  
  /// Returns Solana Explorer URL for an address
  static String getAddressExplorerUrl(String address) {
    final cluster = network == 'mainnet-beta' ? '' : '?cluster=$network';
    return 'https://explorer.solana.com/address/$address$cluster';
  }

  /// Check if running on devnet
  static bool get isDevnet => network == 'devnet';
  
  /// Check if running on mainnet
  static bool get isMainnet => network == 'mainnet-beta';
}
