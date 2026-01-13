/**
 * Simple Metadata Storage Service
 * Stores NFT metadata in memory and serves via HTTP endpoints
 * For production, use IPFS/Arweave
 */

const crypto = require('crypto');

// In-memory metadata storage (for devnet testing)
const metadataStore = new Map();

/**
 * Store metadata and get a unique ID
 */
function storeMetadata(metadata) {
  const id = crypto.randomBytes(16).toString('hex');
  metadataStore.set(id, {
    ...metadata,
    storedAt: new Date().toISOString(),
  });
  return id;
}

/**
 * Get metadata by ID
 */
function getMetadata(id) {
  return metadataStore.get(id);
}

/**
 * Get all metadata (for debugging)
 */
function getAllMetadata() {
  return Array.from(metadataStore.entries()).map(([id, data]) => ({
    id,
    ...data,
  }));
}

/**
 * Generate public URL for metadata
 */
function getMetadataUrl(id, baseUrl) {
  return `${baseUrl}/api/metadata/${id}`;
}

/**
 * Create compact metadata for Solana transaction
 * This version is optimized for size to fit in transaction
 */
function createCompactMetadata({
  plantName,
  rarity,
  scientificName,
  description,
  imageUrl,
  treasureId,
}) {
  // Minimal metadata that fits in transaction
  return {
    name: `${plantName}`,
    symbol: getRaritySymbol(rarity),
    uri: '', // Will be updated with external URL
  };
}

/**
 * Create full metadata for external storage
 */
function createFullMetadata({
  plantName,
  rarity,
  scientificName,
  description,
  imageUrl,
  location,
  treasureId,
  creatorAddress,
}) {
  const rarityConfig = getRarityConfig(rarity);
  
  const attributes = [
    ...rarityConfig.attributes,
    { trait_type: 'Plant', value: plantName },
  ];
  
  if (scientificName) {
    attributes.push({ trait_type: 'Scientific Name', value: scientificName });
  }
  
  if (treasureId) {
    attributes.push({ trait_type: 'Treasure ID', value: treasureId });
  }
  
  if (location) {
    attributes.push({ 
      trait_type: 'Discovery Location', 
      value: `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`,
    });
  }
  
  return {
    name: `${plantName} - ${rarityConfig.name}`,
    symbol: rarityConfig.symbol,
    description: description || `A ${rarityConfig.name} NFT from PlantGO`,
    image: imageUrl || 'https://arweave.net/placeholder-plantgo-nft.png',
    external_url: 'https://plantgo.app',
    attributes,
    properties: {
      files: imageUrl ? [{ uri: imageUrl, type: 'image/png' }] : [],
      category: 'image',
      creators: [
        {
          address: creatorAddress,
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

function getRaritySymbol(rarity) {
  const symbols = {
    auroraSeed: 'AURORA',
    primordialRelic: 'RELIC',
    mythicCrest: 'MYTHIC',
    astralShard: 'ASTRAL',
    genesisFragment: 'GENESIS',
    codexOfInsight: 'CODEX',
    ascendantSeal: 'ASCEND',
  };
  return symbols[rarity] || 'PLANT';
}

function getRarityConfig(rarity) {
  const configs = {
    auroraSeed: {
      name: 'Aurora Seed',
      symbol: 'AURORA',
      sellerFeeBasisPoints: 500,
      attributes: [
        { trait_type: 'Rarity', value: 'Legendary' },
        { trait_type: 'Type', value: 'New Species' },
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
        { trait_type: 'Type', value: 'Quiz' },
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
  
  return configs[rarity] || configs.genesisFragment;
}

module.exports = {
  storeMetadata,
  getMetadata,
  getAllMetadata,
  getMetadataUrl,
  createCompactMetadata,
  createFullMetadata,
};
