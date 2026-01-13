/**
 * NFT Minting Service
 * 
 * Handles Solana NFT creation using Metaplex
 */

const { 
  Connection, 
  Keypair, 
  PublicKey,
  clusterApiUrl,
} = require('@solana/web3.js');
const { 
  createUmi 
} = require('@metaplex-foundation/umi-bundle-defaults');
const { 
  createNft,
  mplTokenMetadata,
} = require('@metaplex-foundation/mpl-token-metadata');
const {
  generateSigner,
  keypairIdentity,
  percentAmount,
  publicKey,
} = require('@metaplex-foundation/umi');
const bs58 = require('bs58');
const {
  storeMetadata,
  getMetadataUrl,
  createFullMetadata,
} = require('./metadata-service');

// Rarity to attributes mapping
const RARITY_CONFIG = {
  auroraSeed: {
    name: 'Aurora Seed',
    symbol: 'AURORA',
    sellerFeeBasisPoints: 500, // 5%
    attributes: [
      { trait_type: 'Rarity', value: 'Legendary' },
      { trait_type: 'Type', value: 'New Species Discovery' },
    ],
  },
  primordialRelic: {
    name: 'Primordial Relic',
    symbol: 'RELIC',
    sellerFeeBasisPoints: 500,
    attributes: [
      { trait_type: 'Rarity', value: 'Legendary' },
      { trait_type: 'Type', value: 'First Discovery' },
    ],
  },
  mythicCrest: {
    name: 'Mythic Crest',
    symbol: 'MYTHIC',
    sellerFeeBasisPoints: 300,
    attributes: [
      { trait_type: 'Rarity', value: 'Epic' },
      { trait_type: 'Type', value: 'Early Discovery' },
    ],
  },
  astralShard: {
    name: 'Astral Shard',
    symbol: 'ASTRAL',
    sellerFeeBasisPoints: 200,
    attributes: [
      { trait_type: 'Rarity', value: 'Rare' },
      { trait_type: 'Type', value: 'Discovery' },
    ],
  },
  genesisFragment: {
    name: 'Genesis Fragment',
    symbol: 'GENESIS',
    sellerFeeBasisPoints: 100,
    attributes: [
      { trait_type: 'Rarity', value: 'Common' },
      { trait_type: 'Type', value: 'Discovery' },
    ],
  },
  codexOfInsight: {
    name: 'Codex of Insight',
    symbol: 'CODEX',
    sellerFeeBasisPoints: 150,
    attributes: [
      { trait_type: 'Rarity', value: 'Uncommon' },
      { trait_type: 'Type', value: 'Quiz Participation' },
    ],
  },
  ascendantSeal: {
    name: 'Ascendant Seal',
    symbol: 'ASCEND',
    sellerFeeBasisPoints: 400,
    attributes: [
      { trait_type: 'Rarity', value: 'Epic' },
      { trait_type: 'Type', value: 'Quiz Victory' },
    ],
  },
};

// Get Solana connection
function getConnection() {
  const rpcUrl = process.env.SOLANA_RPC_URL || clusterApiUrl(process.env.SOLANA_NETWORK || 'devnet');
  return new Connection(rpcUrl, 'confirmed');
}

// Get mint authority keypair
function getMintAuthorityKeypair() {
  const secretKey = process.env.MINT_AUTHORITY_SECRET_KEY;
  if (!secretKey) {
    throw new Error('MINT_AUTHORITY_SECRET_KEY not set in environment');
  }
  
  try {
    const decoded = bs58.decode(secretKey);
    return Keypair.fromSecretKey(decoded);
  } catch (error) {
    throw new Error(`Invalid MINT_AUTHORITY_SECRET_KEY: ${error.message}`);
  }
}

// Get mint authority public key
async function getMintAuthority() {
  const keypair = getMintAuthorityKeypair();
  return {
    publicKey: keypair.publicKey.toBase58(),
  };
}

// Create NFT metadata JSON
function createMetadata({
  plantName,
  rarity,
  scientificName,
  description,
  imageUrl,
  location,
  treasureId,
}) {
  const rarityConfig = RARITY_CONFIG[rarity] || RARITY_CONFIG.genesisFragment;
  
  const attributes = [
    ...rarityConfig.attributes,
    { trait_type: 'Plant Name', value: plantName },
  ];
  
  if (scientificName) {
    attributes.push({ trait_type: 'Scientific Name', value: scientificName });
  }
  
  if (location) {
    attributes.push({ trait_type: 'Discovery Location', value: `${location.lat}, ${location.lng}` });
  }
  
  return {
    name: `${plantName} - ${rarityConfig.name}`,
    symbol: rarityConfig.symbol,
    description: description || `A ${rarityConfig.name} NFT from PlantGO - discovered ${plantName}`,
    image: imageUrl || 'https://plantgo.app/nft-placeholder.png',
    external_url: 'https://plantgo.app',
    attributes,
    properties: {
      files: imageUrl ? [{ uri: imageUrl, type: 'image/png' }] : [],
      category: 'image',
      creators: [
        {
          address: getMintAuthorityKeypair().publicKey.toBase58(),
          share: 100,
        },
      ],
    },
    collection: {
      name: 'PlantGO Discoveries',
      family: 'PlantGO',
    },
  };
}

// Upload metadata to IPFS (or return placeholder for now)
async function uploadMetadata(metadata) {
  // For MVP: Return a data URI with the metadata
  // For production: Upload to IPFS via Pinata, NFT.storage, or Arweave
  
  if (process.env.PINATA_API_KEY && process.env.PINATA_SECRET_KEY) {
    // TODO: Implement Pinata upload
    console.log('Pinata integration not yet implemented, using placeholder');
  }
  
  // Placeholder: encode metadata as base64 data URI
  // In production, this should be uploaded to IPFS
  const metadataJson = JSON.stringify(metadata);
  const base64 = Buffer.from(metadataJson).toString('base64');
  
  // For devnet testing, we'll use a simple approach
  // The metadata is embedded but this works for testing
  return `data:application/json;base64,${base64}`;
}

// Mint NFT
async function mintNFT({
  ownerWallet,
  plantName,
  rarity,
  treasureId,
  imageUrl,
  scientificName,
  description,
  location,
}) {
  try {
    // Validate owner wallet
    let ownerPubkey;
    try {
      ownerPubkey = new PublicKey(ownerWallet);
    } catch (e) {
      return { success: false, error: 'Invalid wallet address' };
    }
    
    // Get connection and keypair
    const connection = getConnection();
    const mintAuthority = getMintAuthorityKeypair();
    
    // Check mint authority balance
    const balance = await connection.getBalance(mintAuthority.publicKey);
    const minBalance = 0.05 * 1e9; // 0.05 SOL minimum
    if (balance < minBalance) {
      return { 
        success: false, 
        error: `Mint authority has insufficient balance: ${balance / 1e9} SOL`,
      };
    }
    
    // Create UMI instance
    const umi = createUmi(process.env.SOLANA_RPC_URL || clusterApiUrl('devnet'))
      .use(mplTokenMetadata());
    
    // Set the keypair identity
    const umiKeypair = umi.eddsa.createKeypairFromSecretKey(mintAuthority.secretKey);
    umi.use(keypairIdentity(umiKeypair));
    
    // Create full metadata for external storage
    const fullMetadata = createFullMetadata({
      plantName,
      rarity,
      scientificName,
      description,
      imageUrl,
      location,
      treasureId,
      creatorAddress: mintAuthority.publicKey.toBase58(),
    });
    
    // For devnet: Use data URI to embed metadata (Phantom can read this)
    // For production: Use IPFS or Arweave
    const metadataJson = JSON.stringify(fullMetadata);
    const metadataBase64 = Buffer.from(metadataJson).toString('base64');
    const metadataUri = `data:application/json;base64,${metadataBase64}`;
    
    // Also store for HTTP access (for debugging)
    const metadataId = storeMetadata(fullMetadata);
    const baseUrl = process.env.BASE_URL || 'http://localhost:3001';
    const httpMetadataUrl = getMetadataUrl(metadataId, baseUrl);
    
    console.log('📝 Metadata stored:', metadataId);
    console.log('🔗 HTTP URL (debug):', httpMetadataUrl);
    console.log('📦 Using data URI for on-chain (Phantom compatible)');
    console.log(`   Size: ${metadataBase64.length} bytes`);
    
    // Get rarity config
    const rarityConfig = RARITY_CONFIG[rarity] || RARITY_CONFIG.genesisFragment;
    
    // Generate a new mint address
    const mint = generateSigner(umi);
    
    // Create shortened name for on-chain (max 32 bytes)
    // Format: "PlantName" or "PlantName #1" to keep it short
    let shortName = plantName.substring(0, 28); // Reserve 4 chars for suffix if needed
    
    // Truncate if still too long
    if (shortName.length > 32) {
      shortName = shortName.substring(0, 32);
    }
    
    console.log(`📛 NFT Name: "${shortName}" (${shortName.length} chars)`);
    
    // Create the NFT
    console.log('🔨 Creating NFT on-chain...');
    console.log('   Owner Wallet:', ownerWallet);
    console.log('   Metadata URI:', metadataUri);
    
    const { signature } = await createNft(umi, {
      mint,
      name: shortName,
      symbol: rarityConfig.symbol,
      uri: metadataUri,
      sellerFeeBasisPoints: percentAmount(rarityConfig.sellerFeeBasisPoints / 100),
      tokenOwner: publicKey(ownerWallet),
    }).sendAndConfirm(umi);
    
    // Convert signature to base58
    const signatureBase58 = bs58.encode(signature);
    
    // Get explorer URL
    const network = process.env.SOLANA_NETWORK || 'devnet';
    const explorerUrl = network === 'mainnet-beta'
      ? `https://explorer.solana.com/tx/${signatureBase58}`
      : `https://explorer.solana.com/tx/${signatureBase58}?cluster=${network}`;
    
    const mintAddress = mint.publicKey.toString();
    
    console.log('✅ NFT minted successfully!');
    console.log('   Mint Address:', mintAddress);
    console.log('   Owner:', ownerWallet);
    console.log('   Signature:', signatureBase58);
    console.log('   Explorer:', explorerUrl);
    console.log('   🔗 View NFT: https://explorer.solana.com/address/' + mintAddress + '?cluster=' + network);
    console.log('');
    console.log('⏳ Note: It may take 1-2 minutes for the NFT to appear in Phantom wallet.');
    console.log('   Phantom needs to index the new NFT from the blockchain.');
    
    return {
      success: true,
      nftMint: mint.publicKey.toString(),
      signature: signatureBase58,
      explorerUrl,
      metadataUri,
    };
  } catch (error) {
    console.error('❌ Mint error:', error);
    return {
      success: false,
      error: error.message || 'Unknown minting error',
    };
  }
}

module.exports = {
  mintNFT,
  getMintAuthority,
  getConnection,
  RARITY_CONFIG,
};
