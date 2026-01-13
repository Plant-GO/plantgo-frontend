# 🔍 Why NFTs Don't Show in Phantom Wallet (And How to Fix It)

## The Problem

Your NFTs are successfully minted on Solana blockchain, but they **don't appear in Phantom wallet**.

## Root Cause

Phantom wallet needs to fetch the NFT **metadata** (name, image, description) from the URI stored on-chain. The problem was:

### ❌ Before Fix (Not Working)
```javascript
// Metadata URI stored on-chain
metadataUri: "http://192.168.201.134:3001/api/metadata/abc123"
```

**Why it fails:**
- Your backend runs on local network (192.168.x.x)
- Phantom wallet servers can't access your local network
- Metadata fetch fails → NFT invisible in wallet
- Transaction succeeds, but metadata is unreachable

## The Fix

### ✅ After Fix (Working)
```javascript
// Use data URI to embed metadata directly
metadataUri: "data:application/json;base64,eyJuYW1lIjoiUm9zZSAt..."
```

**Why it works:**
- Metadata is embedded directly in the blockchain
- No external HTTP request needed
- Phantom can read it immediately
- Works on devnet for testing

## How It Works Now

### 1. Metadata Creation
```javascript
const fullMetadata = {
  name: "Rose - Aurora Seed",
  symbol: "AURORA",
  description: "A Legendary NFT from PlantGO",
  image: "https://your-image-url.com/rose.png",
  attributes: [
    { trait_type: "Rarity", value: "Legendary" },
    { trait_type: "Plant", value: "Rose" }
  ],
  properties: {
    creators: [{ address: "...", share: 100 }],
    files: [{ uri: "image-url", type: "image/png" }]
  }
};
```

### 2. Encode as Data URI
```javascript
const metadataJson = JSON.stringify(fullMetadata);
const metadataBase64 = Buffer.from(metadataJson).toString('base64');
const metadataUri = `data:application/json;base64,${metadataBase64}`;
```

### 3. Create NFT with Data URI
```javascript
await createNft(umi, {
  mint,
  name: "Rose",
  symbol: "AURORA",
  uri: metadataUri,  // ← Data URI, not HTTP URL!
  tokenOwner: publicKey(userWallet),
}).sendAndConfirm(umi);
```

## NFT Visibility Timeline

### Immediate (0-5 seconds)
✅ Transaction confirmed on Solana
✅ NFT mint address created
✅ Metadata stored on-chain

### Short Wait (30-60 seconds)
⏳ Phantom wallet indexes new transactions
⏳ Reads token accounts for your wallet
⏳ Fetches metadata from data URI

### After 1-2 Minutes
✅ NFT appears in Phantom wallet "Collectibles" tab
✅ Image, name, and attributes visible
✅ Can view on Solana Explorer

## How to Check If It Worked

### 1. Check Solana Explorer
```
https://explorer.solana.com/address/[MINT_ADDRESS]?cluster=devnet
```

**What to verify:**
- ✅ Mint account exists
- ✅ Token metadata program account created
- ✅ Token account owned by your wallet
- ✅ Supply: 1 (NFT has exactly 1 token)

### 2. Check in Phantom Wallet
```
1. Open Phantom wallet on mobile
2. Tap "Collectibles" tab (bottom)
3. Wait 1-2 minutes if just minted
4. Pull down to refresh
5. NFT should appear!
```

### 3. Check Backend Logs
```bash
cd backend
npm start

# After minting, look for:
✅ NFT minted successfully!
   Mint Address: 7FNv8pfHGDFKt5n4oBDXB4BEjytBgvwfuXj51gvFm6FB
   Owner: B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw
   📦 Using data URI for on-chain (Phantom compatible)
   Size: 1234 bytes
```

## Alternatives to Data URI

### Production Solutions

#### Option 1: IPFS (Recommended)
```javascript
// Upload to IPFS
const { cid } = await ipfs.add(JSON.stringify(metadata));
const metadataUri = `https://ipfs.io/ipfs/${cid}`;

// Pros: Decentralized, permanent, widely supported
// Cons: Requires IPFS setup
```

#### Option 2: Arweave (Permanent Storage)
```javascript
// Upload to Arweave
const tx = await arweave.createTransaction({ data: JSON.stringify(metadata) });
await arweave.transactions.sign(tx);
await arweave.transactions.post(tx);
const metadataUri = `https://arweave.net/${tx.id}`;

// Pros: Permanent, one-time payment
// Cons: Costs AR tokens
```

#### Option 3: Cloud Storage (S3, Cloud Storage)
```javascript
// Upload to S3
const url = await s3.upload('metadata.json', metadata);
const metadataUri = url;

// Pros: Fast, cheap, familiar
// Cons: Centralized, requires cloud account
```

### For Devnet Testing
```javascript
// Data URI (current solution)
const metadataUri = `data:application/json;base64,${base64}`;

// Pros: Works immediately, no external service
// Cons: Limited size (~10KB), increases transaction cost slightly
```

## Size Considerations

### Data URI Limits
- **Maximum size**: ~10KB (practical limit)
- **Current usage**: ~2-3KB per NFT
- **What's included**:
  - Name, symbol, description
  - Attributes (rarity, type, plant name)
  - Image URL (not the image itself)
  - Creator info

### If Metadata Too Large
```javascript
// Split metadata:
// 1. Essential on-chain (data URI)
const essentialMetadata = {
  name,
  symbol,
  image: imageUrl,  // Just URL, not image data
  attributes: basicAttributes,
};

// 2. Extended off-chain (IPFS)
const extendedMetadata = {
  ...essentialMetadata,
  fullDescription,
  highResImages,
  detailedHistory,
};
```

## Common Issues

### Issue 1: NFT Still Not Showing
**Possible causes:**
- Phantom indexing delay (wait 2-3 minutes)
- Wrong wallet address
- Wrong network (mainnet vs devnet)

**Solutions:**
```bash
# 1. Verify wallet address
echo "Wallet in app: B558JuBt..."
echo "Wallet in backend: [check logs]"

# 2. Verify network
curl http://localhost:3001/health
# Should show: "network": "devnet"

# 3. Check Solana Explorer
https://explorer.solana.com/address/[MINT]?cluster=devnet
```

### Issue 2: Image Not Loading in Phantom
**Cause:** Image URL not accessible

**Solutions:**
```javascript
// Use public image hosting:
// ❌ Don't: "http://192.168.1.100/image.png"
// ✅ Do: "https://your-domain.com/image.png"
// ✅ Or: "https://arweave.net/[hash]"
// ✅ Or: "https://ipfs.io/ipfs/[cid]"

// For testing, use placeholder:
imageUrl: "https://via.placeholder.com/400x400.png?text=PlantGO+NFT"
```

### Issue 3: Metadata Shows But Wrong Data
**Cause:** Metadata cached by Phantom

**Solution:**
```
1. Wait 5 minutes for cache expiration
2. Or disconnect/reconnect wallet
3. Or clear Phantom app cache
```

## Testing Checklist

After minting an NFT:

- [ ] Backend logs show "NFT minted successfully"
- [ ] Backend logs show "Using data URI for on-chain"
- [ ] Mint address appears in logs
- [ ] Owner wallet matches your Phantom address
- [ ] Solana Explorer shows NFT exists
- [ ] Solana Explorer shows token account with supply=1
- [ ] Wait 2 minutes
- [ ] Refresh Phantom wallet
- [ ] NFT appears in Collectibles tab
- [ ] Image loads correctly
- [ ] Name and attributes correct

## Production Deployment

When deploying to production:

### 1. Switch to IPFS/Arweave
```javascript
// Update .env
METADATA_STORAGE=ipfs  // or 'arweave'
IPFS_URL=https://ipfs.infura.io:5001
IPFS_PROJECT_ID=your_project_id
IPFS_PROJECT_SECRET=your_secret

// Update nft-service.js
if (process.env.METADATA_STORAGE === 'ipfs') {
  metadataUri = await uploadToIPFS(fullMetadata);
} else {
  // Fallback to data URI
  metadataUri = createDataURI(fullMetadata);
}
```

### 2. Use Public Image Hosting
```javascript
// Upload plant images to CDN
const imageUrl = await uploadToCDN(plantImage);

// Or use Arweave for images
const imageUrl = await uploadToArweave(plantImage);
```

### 3. Switch to Mainnet
```env
SOLANA_NETWORK=mainnet-beta
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
```

## Summary

**Problem:** NFTs minted but not visible in Phantom
**Cause:** Metadata URI pointed to local backend (unreachable)
**Solution:** Use data URI to embed metadata on-chain
**Result:** NFTs now visible in Phantom wallet! ✅

**For production:** Migrate to IPFS or Arweave for scalability and decentralization.
