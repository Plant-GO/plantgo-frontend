/**
 * PlantGO NFT Minting Backend Server
 * 
 * This server handles:
 * 1. NFT minting transactions on Solana
 * 2. Metadata creation and storage
 * 3. Transaction signing with mint authority
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { mintNFT, getMintAuthority } = require('./services/nft-service');
const { validateMintRequest } = require('./middleware/validation');
const { getMetadata, getAllMetadata } = require('./services/metadata-service');

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet());

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Increase payload size limit for plant images (up to 50MB)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    network: process.env.SOLANA_NETWORK,
    timestamp: new Date().toISOString(),
  });
});

// Get mint authority public key (for verification)
app.get('/api/mint-authority', async (req, res) => {
  try {
    const authority = await getMintAuthority();
    res.json({ 
      success: true, 
      publicKey: authority.publicKey,
      network: process.env.SOLANA_NETWORK,
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message,
    });
  }
});

// Get NFT metadata by ID
app.get('/api/metadata/:id', (req, res) => {
  try {
    const { id } = req.params;
    const metadata = getMetadata(id);
    
    if (!metadata) {
      return res.status(404).json({ error: 'Metadata not found' });
    }
    
    res.json(metadata);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all metadata (debug endpoint)
app.get('/api/metadata', (req, res) => {
  try {
    const allMetadata = getAllMetadata();
    res.json({ count: allMetadata.length, metadata: allMetadata });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mint NFT endpoint
app.post('/api/nft/mint', validateMintRequest, async (req, res) => {
  try {
    const { 
      walletAddress, 
      plantName, 
      rarity, 
      treasureId,
      imageUrl,
      scientificName,
      description,
      location,
    } = req.body;

    console.log(`🎴 Minting NFT for ${plantName} (${rarity}) to ${walletAddress}`);

    const result = await mintNFT({
      ownerWallet: walletAddress,
      plantName,
      rarity,
      treasureId,
      imageUrl,
      scientificName,
      description,
      location,
    });

    if (result.success) {
      console.log(`✅ NFT minted: ${result.nftMint}`);
      res.json({
        success: true,
        nftMint: result.nftMint,
        signature: result.signature,
        explorerUrl: result.explorerUrl,
        metadataUri: result.metadataUri,
      });
    } else {
      console.error(`❌ Mint failed: ${result.error}`);
      res.status(400).json({
        success: false,
        error: result.error,
      });
    }
  } catch (error) {
    console.error('❌ Mint error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Get user's NFTs
app.get('/api/nft/user/:walletAddress', async (req, res) => {
  try {
    const { walletAddress } = req.params;
    // For now, return empty - can integrate with Helius or other indexer
    res.json({
      success: true,
      nfts: [],
      message: 'NFT indexing not yet implemented - use Firestore for now',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Get metadata PDA for a mint address
app.get('/api/nft/metadata-pda', async (req, res) => {
  try {
    const { mint } = req.query;
    if (!mint) {
      return res.status(400).json({ success: false, error: 'Missing mint parameter' });
    }

    const { PublicKey } = require('@solana/web3.js');
    
    // Metaplex Token Metadata Program ID
    const METADATA_PROGRAM_ID = new PublicKey('metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s');
    const mintPubkey = new PublicKey(mint);
    
    // Derive PDA
    const [pda] = PublicKey.findProgramAddressSync(
      [
        Buffer.from('metadata'),
        METADATA_PROGRAM_ID.toBuffer(),
        mintPubkey.toBuffer(),
      ],
      METADATA_PROGRAM_ID
    );
    
    res.json({
      success: true,
      pda: pda.toBase58(),
      mint: mint,
    });
  } catch (error) {
    console.error('PDA derivation error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    success: false,
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error',
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 PlantGO NFT Backend running on port ${PORT}`);
  console.log(`📡 Network: ${process.env.SOLANA_NETWORK}`);
  console.log(`🔗 RPC: ${process.env.SOLANA_RPC_URL}`);
});
