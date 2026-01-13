import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../blockchain/blockchain.dart';
import '../core/theme/app_colors.dart';
import '../providers/wallet_provider.dart';
import '../providers/nft_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/nft_card_widget.dart';
import '../widgets/wallet_connect_button.dart';

/// NFT Collection Screen - Displays user's NFT card collection
class NFTCollectionScreen extends StatefulWidget {
  const NFTCollectionScreen({super.key});

  @override
  State<NFTCollectionScreen> createState() => _NFTCollectionScreenState();
}

class _NFTCollectionScreenState extends State<NFTCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filterTabs = [
    'All',
    'Legendary',
    'Epic',
    'Rare',
    'Common',
    'Quiz',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNFTs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadNFTs() {
    final wallet = context.read<WalletProvider>();
    final userProvider = context.read<UserProvider>();

    // Use Phantom wallet if connected, otherwise use device wallet
    String? walletAddress;
    if (wallet.isConnected && wallet.walletAddress != null) {
      walletAddress = wallet.walletAddress!;
      debugPrint('🔑 NFT Collection: Using Phantom wallet: $walletAddress');
    } else if (userProvider.deviceId.isNotEmpty) {
      walletAddress = 'device_${userProvider.deviceId}';
      debugPrint('🔑 NFT Collection: Using device wallet: $walletAddress');
    } else {
      debugPrint(
        '⚠️ NFT Collection: No wallet available (deviceId: "${userProvider.deviceId}")',
      );
    }

    if (walletAddress != null) {
      debugPrint('📦 NFT Collection: Loading NFTs for $walletAddress');
      context.read<NFTProvider>().loadNFTs(walletAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer2<WalletProvider, UserProvider>(
        builder: (context, wallet, userProvider, child) {
          // Show NFT content if either Phantom is connected OR we have device ID
          final hasWallet =
              wallet.isConnected || userProvider.deviceId.isNotEmpty;
          if (!hasWallet) {
            return _buildConnectWalletPrompt();
          }
          return _buildNFTContent();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: const Text(
        'My NFT Collection',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: WalletConnectButton(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildFilterTabs(),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: _filterTabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildConnectWalletPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wallet illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.phantomGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Connect Your Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Connect your Phantom wallet to view and mint your Plant NFT collection',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            WalletConnectButton(expanded: true, onConnected: _loadNFTs),

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () {
                // Show info about NFTs
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('What are Plant NFTs?'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNFTContent() {
    return Consumer<NFTProvider>(
      builder: (context, nftProvider, child) {
        if (nftProvider.isLoading) {
          return _buildLoadingGrid();
        }

        return TabBarView(
          controller: _tabController,
          children: _filterTabs.map((tab) {
            final filteredNFTs = _getFilteredNFTs(nftProvider.nfts, tab);

            if (filteredNFTs.isEmpty) {
              return _buildEmptyState(tab);
            }

            return _buildNFTGrid(filteredNFTs);
          }).toList(),
        );
      },
    );
  }

  List<NFTCard> _getFilteredNFTs(List<NFTCard> nfts, String filter) {
    switch (filter) {
      case 'All':
        return nfts;
      case 'Legendary':
        return nfts.where((n) => n.rarity.isLegendary).toList();
      case 'Epic':
        return nfts.where((n) => n.rarity == CardRarity.mythicCrest).toList();
      case 'Rare':
        return nfts.where((n) => n.rarity == CardRarity.astralShard).toList();
      case 'Common':
        return nfts
            .where((n) => n.rarity == CardRarity.genesisFragment)
            .toList();
      case 'Quiz':
        return nfts.where((n) => n.rarity.isQuizCard).toList();
      default:
        return nfts;
    }
  }

  Widget _buildNFTGrid(List<NFTCard> nfts) {
    return RefreshIndicator(
      onRefresh: () async => _loadNFTs(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: nfts.length,
        itemBuilder: (context, index) {
          return NFTCardWidget(
            nftCard: nfts[index],
            onTap: () => _showNFTDetails(nfts[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const NFTCardSkeleton();
      },
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    if (filter == 'All') {
      message = 'Start discovering plants to earn your first NFT card!';
      icon = Icons.explore;
    } else {
      message = 'No $filter cards yet. Keep exploring!';
      icon = Icons.collections;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showNFTDetails(NFTCard nft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NFTDetailSheet(nft: nft),
    );
  }
}

/// NFT Detail Bottom Sheet
class _NFTDetailSheet extends StatelessWidget {
  final NFTCard nft;

  const _NFTDetailSheet({required this.nft});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(nft.rarity.primaryColor);
    final secondaryColor = Color(nft.rarity.secondaryColor);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Card preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Large card display
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rarity badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                nft.rarity.rarityTier.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Plant icon/image
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.local_florist,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Plant name
                            Text(
                              nft.plantName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (nft.scientificName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                nft.scientificName!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Card type
                            Text(
                              nft.rarity.displayName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.calendar_today,
                          label: 'Minted',
                          value: nft.mintedAt != null
                              ? '${nft.mintedAt!.day}/${nft.mintedAt!.month}/${nft.mintedAt!.year}'
                              : 'Unknown',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.verified,
                          label: 'Token',
                          value: nft.nftMint.isNotEmpty
                              ? '${nft.nftMint.substring(0, 6)}...'
                              : 'N/A',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (nft.transactionSignature != null) {
                              // Open Solana Explorer
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('View on Explorer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Share functionality
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
