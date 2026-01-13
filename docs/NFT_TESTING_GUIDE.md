# PlantGO NFT & Blockchain Testing Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Testing Flow Overview](#testing-flow-overview)
4. [Step-by-Step Testing](#step-by-step-testing)
5. [Verification Methods](#verification-methods)
6. [Troubleshooting](#troubleshooting)
7. [NFT Rarity System](#nft-rarity-system)

---

## Prerequisites

### ✅ What You Need
- [x] Phantom Wallet installed and connected (✓ Already working!)
- [ ] Backend server running on port 3001
- [ ] Solana devnet SOL in wallet (for gas fees)
- [ ] Firebase Firestore access
- [ ] Plant discovery/scan functionality working

### 🔑 Get Devnet SOL (Free!)
```bash
# Your wallet address (check in app after connecting)
WALLET_ADDRESS="B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw"

# Request airdrop (can do multiple times)
solana airdrop 2 $WALLET_ADDRESS --url devnet
```

Or use the [Solana Devnet Faucet](https://faucet.solana.com/)

---

## Backend Setup

### 1. Check Backend Status

```bash
# Navigate to backend directory
cd /Users/dikshitbhatta/plantgo-frontend/backend

# Check if backend is running
curl http://localhost:3001/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "network": "devnet",
  "timestamp": "2026-01-13T..."
}
```

### 2. Start Backend (if not running)

```bash
# Install dependencies (first time only)
npm install

# Generate keypair (first time only)
node scripts/generate-keypair.js

# Start the backend server
npm start
```

**Expected Output:**
```
🚀 PlantGO NFT Server running on port 3001
🌐 Network: devnet
🔑 Mint Authority: <pubkey>
✅ Ready to mint NFTs!
```

### 3. Backend Environment Check

The backend needs these environment variables in `.env`:

```bash
# Check backend/.env file
cat backend/.env
```

Should contain:
```env
PORT=3001
SOLANA_NETWORK=devnet
MINT_AUTHORITY_SECRET_KEY=<base58_secret_key>
```

If missing, create it:
```bash
echo "PORT=3001
SOLANA_NETWORK=devnet
MINT_AUTHORITY_SECRET_KEY=$(cat backend/mint-authority-keypair.json | jq -r '.secretKey')" > backend/.env
```

---

## Testing Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     NFT CREATION FLOW                           │
└─────────────────────────────────────────────────────────────────┘

1. DISCOVER PLANT
   └─> User scans/identifies a plant
       └─> treasure_service.dart creates treasure in Firestore

2. PHANTOM WALLET CONNECTION
   └─> wallet_service.dart handles deep link
       └─> Stores wallet address: B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw

3. RARITY DETERMINATION
   └─> plant_discovery_service.dart checks plant_counters
       ├─> New species? → AuroraSeed (Legendary)
       ├─> First discovery? → PrimordialRelic (Legendary)
       ├─> Count 1-20? → MythicCrest (Epic)
       ├─> Count 21-50? → AstralShard (Rare)
       └─> Count 51+? → GenesisFragment (Common)

4. NFT MINTING
   └─> nft_minting_service.dart
       ├─> Calls backend: POST /api/mint
       │   └─> backend/src/services/nft-service.js
       │       └─> Creates NFT on Solana devnet
       │           └─> Returns: nftMint, signature, explorerUrl
       └─> Saves to Firestore: nft_cards collection

5. VERIFICATION
   ├─> Check Solana Explorer
   ├─> Check Firebase Firestore
   └─> Check Phantom Wallet
```

---

## Step-by-Step Testing

### Test 1: Backend Health Check

**Terminal 1 - Start Backend:**
```bash
cd /Users/dikshitbhatta/plantgo-frontend/backend
npm start
```

**Terminal 2 - Test API:**
```bash
# Health check
curl http://localhost:3001/health

# Get mint authority (should match backend logs)
curl http://localhost:3001/api/mint-authority

# Test mint endpoint (dry run)
curl -X POST http://localhost:3001/api/mint \
  -H "Content-Type: application/json" \
  -d '{
    "walletAddress": "B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw",
    "plantName": "test_oak_tree",
    "rarity": "mythic_crest",
    "treasureId": "test_123"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "nftMint": "<nft_public_key>",
  "signature": "<transaction_signature>",
  "explorerUrl": "https://explorer.solana.com/tx/<signature>?cluster=devnet"
}
```

---

### Test 2: App Flow Testing

#### 2.1 Launch App with Backend Running

```bash
# Terminal 1: Backend
cd backend && npm start

# Terminal 2: Flutter app
flutter run
```

#### 2.2 Connect Phantom Wallet

1. **In PlantGO app**: Go to Profile/Settings
2. **Tap "Connect Wallet"**
3. **Phantom opens** → Tap "Connect"
4. **Return to PlantGO** → Should see: "✅ Connected to wallet: B558..."

**Verify in Logs:**
```
WalletService: ✅ Connected to wallet: B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw
```

#### 2.3 Discover a Plant

**Option A: Camera Scan**
1. Tap Map/Camera icon
2. Scan a plant (or use test image)
3. Wait for identification
4. Review plant details

**Option B: Test Discovery (for development)**
```dart
// In treasure_service.dart or use debug console
final testDiscovery = await treasureService.createTreasure(
  plantName: 'Rosa damascena',  // First time = PrimordialRelic
  commonName: 'Damask Rose',
  confidence: 0.95,
  imageBase64: '<base64_image>',
  latitude: 37.7749,
  longitude: -122.4194,
  deviceId: 'test_device',
  userName: 'Test Explorer',
);
```

#### 2.4 Mint NFT

After discovering a plant:

1. **Tap "Mint NFT"** button
2. **App calls** `nft_minting_service.dart`
3. **Backend mints** on Solana devnet
4. **Success dialog** appears with:
   - NFT Rarity (e.g., "Primordial Relic")
   - Transaction signature
   - Explorer link

**App Logs to Check:**
```
PlantDiscoveryService: isNewSpecies("rosa_damascena"): true
🌟 New species "rosa_damascena" → Aurora Seed
✅ Real NFT minted on Solana: <nft_mint>
✅ NFT Minted: Aurora Seed for rosa_damascena
```

**Backend Logs to Check:**
```
🎨 Creating metadata for: rosa_damascena
🔑 Signing transaction...
✅ NFT Minted: <nft_mint>
📝 Transaction: <signature>
```

---

## Verification Methods

### Method 1: Solana Explorer (On-Chain Verification)

After minting, get the transaction signature from app logs or success dialog:

```
Transaction: 5xK7... (example)
```

**Visit Solana Explorer:**
```
https://explorer.solana.com/tx/<TRANSACTION_SIGNATURE>?cluster=devnet
```

**What to Look For:**
- ✅ Status: "Success" (green checkmark)
- ✅ Block confirmations: 32/32
- ✅ Instructions: "Create", "Mint To"
- ✅ NFT Mint address
- ✅ Owner: Your wallet address (B558...)

**Example:**
```
https://explorer.solana.com/tx/5xK7QWz...?cluster=devnet
```

### Method 2: Firebase Firestore (Database Verification)

Open Firebase Console → Firestore Database

#### Check `nft_cards` Collection
```
Document ID: <nft_mint>
{
  owner_wallet: "B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw"
  plant_name: "rosa_damascena"
  rarity: "auroraSeed"
  minted_at: Timestamp(...)
  transaction_signature: "5xK7..."
  explorer_url: "https://explorer.solana.com/tx/..."
  on_chain: true
}
```

#### Check `plant_counters` Collection
```
Document ID: "rosa_damascena"
{
  plantName: "rosa_damascena"
  totalMinted: 1
  seedCount: 1      // AuroraSeed
  relicCount: 0     // PrimordialRelic
  epicCount: 0      // MythicCrest
  rareCount: 0      // AstralShard
  commonCount: 0    // GenesisFragment
  firstDiscoveredBy: "test_device"
  firstDiscoveredAt: Timestamp(...)
}
```

#### Check `treasures` Collection
```
Document ID: <treasure_id>
{
  plantName: "rosa_damascena"
  confidence: 0.95
  nftMinted: true
  nftPendingMint: false
  nftRarity: "auroraSeed"
  nftRarityDisplayName: "Aurora Seed"
  discoveredBy: "test_device"
  userName: "Test Explorer"
}
```

### Method 3: Phantom Wallet (User View)

1. **Open Phantom Wallet**
2. **Go to "Collectibles" tab**
3. **Should see your PlantGO NFT!**

**Note:** NFT metadata might take 1-2 minutes to appear in Phantom. The NFT exists on-chain immediately, but Phantom needs to index the metadata.

**If not showing:**
- Wait 2-3 minutes
- Pull down to refresh
- Check you're on "Devnet" in Phantom settings
- Verify the NFT mint address in Solana Explorer

### Method 4: API Verification

```bash
# Get all NFTs for a wallet
curl -X GET "http://localhost:3001/api/nfts/<WALLET_ADDRESS>"

# Get specific NFT details
curl -X GET "http://localhost:3001/api/nft/<NFT_MINT_ADDRESS>"
```

---

## Troubleshooting

### ❌ Backend Not Responding

**Symptoms:**
- App shows "Simulated mint" instead of real NFT
- Logs show: "Backend unavailable, using simulated mint"

**Solutions:**
```bash
# Check if backend is running
curl http://localhost:3001/health

# If not running, start it:
cd backend
npm start

# Check for port conflicts
lsof -i :3001

# Kill conflicting process
kill -9 <PID>

# Restart backend
npm start
```

### ❌ "Insufficient Funds" Error

**Symptoms:**
- Backend logs: "Error: Insufficient funds"
- Transaction fails

**Solution:**
```bash
# Get devnet SOL (free)
solana airdrop 2 <WALLET_ADDRESS> --url devnet

# Check balance
solana balance <WALLET_ADDRESS> --url devnet
```

### ❌ Wallet Not Connected

**Symptoms:**
- "Connect wallet" button still showing
- Mint button disabled

**Solutions:**
1. Open Phantom wallet manually
2. Ensure you're on "Devnet" network in Phantom
3. Reconnect from PlantGO app
4. Check SharedPreferences for stored keys:
   ```dart
   // In debug console
   final prefs = await SharedPreferences.getInstance();
   print(prefs.getKeys());
   ```

### ❌ NFT Not Showing in Phantom

**Symptoms:**
- Transaction successful on Explorer
- NFT in Firestore
- But not in Phantom wallet

**Solutions:**
1. **Wait 2-3 minutes** (indexing delay)
2. Switch Phantom to "Mainnet" then back to "Devnet"
3. Pull down to refresh Collectibles tab
4. Check Phantom is set to "Devnet" network
5. Verify NFT ownership on Solana Explorer:
   ```
   https://explorer.solana.com/address/<NFT_MINT>?cluster=devnet
   ```

### ❌ "Transaction Signature Verification Failure"

**Symptoms:**
- Backend error: "Transaction signature verification failure"

**Solutions:**
```bash
# Regenerate mint authority keypair
cd backend
node scripts/generate-keypair.js

# Update .env with new secret key
# Restart backend
npm start
```

### ❌ CORS Errors

**Symptoms:**
- Browser console: "CORS policy blocked"
- App can't reach backend

**Solution:**
```javascript
// In backend/src/index.js - verify CORS is configured:
app.use(cors({
  origin: true,  // Allow all origins for development
  methods: ['GET', 'POST'],
}));
```

---

## NFT Rarity System

### Rarity Tiers & Discovery Order

```
┌─────────────────────────────────────────────────────────┐
│                   RARITY BREAKDOWN                      │
└─────────────────────────────────────────────────────────┘

🌟 AURORA SEED (Legendary)
   └─> NEW SPECIES discovered for the first time ever
   └─> Only 1 per species globally
   └─> Example: You're the first person to identify "Rafflesia arnoldii"
   └─> Points: 1,000 XP

🏺 PRIMORDIAL RELIC (Legendary)  
   └─> FIRST DISCOVERY of a known plant species
   └─> Only 1 per species globally
   └─> Example: First person to find "Rosa damascena" in the app
   └─> Points: 500 XP

💜 MYTHIC CREST (Epic)
   └─> Discoveries #1-20 for each plant
   └─> Limited to 20 per species
   └─> Example: You're the 15th person to discover "Quercus robur"
   └─> Points: 100 XP

💙 ASTRAL SHARD (Rare)
   └─> Discoveries #21-50 for each plant
   └─> Limited to 30 per species
   └─> Example: You're the 35th person to discover "Acer palmatum"
   └─> Points: 50 XP

⬜ GENESIS FRAGMENT (Common)
   └─> Discoveries #51+ for each plant
   └─> Unlimited
   └─> Example: You're the 127th person to discover "Rosa damascena"
   └─> Points: 10 XP
```

### Testing Rarity Scenarios

#### Scenario 1: Brand New Species (Aurora Seed)

```dart
// Test with a plant that has NEVER been scanned before
final newPlant = await discoverPlant(
  plantName: 'Welwitschia mirabilis',  // Rare plant unlikely to be in database
  isNewSpecies: true,
);

// Expected: 🌟 Aurora Seed NFT
```

**Verify in Firestore:**
```
plant_counters/welwitschia_mirabilis:
{
  seedCount: 1,
  totalMinted: 1
}
```

#### Scenario 2: First Discovery (Primordial Relic)

```dart
// Test with a known plant that hasn't been minted yet
final firstDiscovery = await discoverPlant(
  plantName: 'Magnolia grandiflora',
  isNewSpecies: false,  // Known plant
);

// Check if totalMinted = 0 in plant_counters
// Expected: 🏺 Primordial Relic NFT
```

#### Scenario 3: Epic Discovery (Mythic Crest)

```dart
// Mint the same plant 5 times (with different users/devices)
for (int i = 1; i <= 5; i++) {
  await discoverPlant(
    plantName: 'Ficus elastica',
    deviceId: 'device_$i',
  );
}

// Discoveries 1-5: Expected 💜 Mythic Crest
```

#### Scenario 4: Testing Counter Progression

```dart
// Mint same plant 55 times to see all rarities
final plantName = 'test_counter_progression';

// Mint #1: Aurora Seed (if new species) OR Primordial Relic
// Mint #2-20: Mythic Crest (Epic)
// Mint #21-50: Astral Shard (Rare)
// Mint #51+: Genesis Fragment (Common)
```

---

## Complete Testing Checklist

### Phase 1: Setup ✓
- [x] Phantom wallet installed & connected
- [ ] Backend server running on port 3001
- [ ] Devnet SOL in wallet (>0.1 SOL)
- [ ] Firebase Firestore accessible

### Phase 2: First NFT Mint
- [ ] Discover a NEW plant species
- [ ] Tap "Mint NFT"
- [ ] See success dialog with Explorer link
- [ ] Verify transaction on Solana Explorer
- [ ] Check Firestore `nft_cards` collection
- [ ] Check Firestore `plant_counters` collection
- [ ] Wait 2 minutes, check Phantom wallet

### Phase 3: Rarity Testing
- [ ] Mint Aurora Seed (new species)
- [ ] Mint Primordial Relic (first discovery)
- [ ] Mint Mythic Crest (#1-20)
- [ ] Mint Astral Shard (#21-50)
- [ ] Mint Genesis Fragment (#51+)

### Phase 4: Community Features
- [ ] Submit plant for community verification
- [ ] Vote on pending verifications
- [ ] Submit a correction (No, Wrong → Enter correct name)
- [ ] Vote on pending corrections
- [ ] Verify correction creates new treasure with dual attribution

### Phase 5: Error Handling
- [ ] Test with backend offline (should use simulated mint)
- [ ] Test with insufficient SOL
- [ ] Test with wallet disconnected
- [ ] Test duplicate mint of same plant

---

## Monitoring & Logs

### App Logs (Flutter)

**Look for these key logs:**

```bash
# Wallet connection
WalletService: ✅ Connected to wallet: B558...

# Rarity determination
PlantDiscoveryService: isNewSpecies("plant_name"): true/false
🌟 New species "plant_name" → Aurora Seed

# Minting process
🎴 Starting mint for plant_name (isNewSpecies: true)
✅ Real NFT minted on Solana: <nft_mint>
✅ NFT Minted: Aurora Seed for plant_name

# Errors
❌ Mint failed: <error>
⚠️ Backend unavailable, using simulated mint
```

### Backend Logs (Node.js)

```bash
# In backend terminal
npm start

# Look for:
🚀 PlantGO NFT Server running on port 3001
🌐 Network: devnet
🔑 Mint Authority: <pubkey>

# Per mint:
📥 Mint request: rosa_damascena (auroraSeed)
🎨 Creating metadata...
🔑 Signing transaction...
✅ NFT Minted: <nft_mint>
📝 Transaction: <signature>
```

### Firestore Real-Time Monitoring

Open Firebase Console → Firestore → Enable real-time updates

Watch these collections update live:
- `nft_cards` - New NFTs created
- `plant_counters` - Discovery counts incrementing
- `treasures` - Plants discovered
- `plant_corrections` - Community corrections

---

## Advanced Testing

### Load Testing

```bash
# Test backend under load
for i in {1..10}; do
  curl -X POST http://localhost:3001/api/mint \
    -H "Content-Type: application/json" \
    -d "{
      \"walletAddress\": \"B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw\",
      \"plantName\": \"test_plant_$i\",
      \"rarity\": \"mythic_crest\"
    }" &
done
wait
```

### Devnet to Mainnet Migration

When ready for production:

1. **Update backend `.env`:**
   ```env
   SOLANA_NETWORK=mainnet-beta
   ```

2. **Generate new production keypair:**
   ```bash
   cd backend/scripts
   node generate-keypair.js --network mainnet
   ```

3. **Fund production wallet** (REAL SOL needed!)

4. **Update app config:**
   ```dart
   // lib/blockchain/solana_config.dart
   static const String cluster = 'mainnet-beta';
   ```

5. **Test thoroughly on devnet first!**

---

## Quick Reference Commands

```bash
# Start backend
cd backend && npm start

# Run Flutter app
flutter run

# Check devnet balance
solana balance B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw --url devnet

# Get devnet SOL
solana airdrop 2 B558JuBtLhEMGmpte7rx9dDpyxsz6RnCNNhiL5q1kuDw --url devnet

# Test backend
curl http://localhost:3001/health

# View backend logs
cd backend && npm run dev  # With nodemon for auto-reload

# Clear app cache (reset for testing)
flutter clean && flutter pub get

# Build release APK
flutter build apk --release
```

---

## Support & Resources

- **Solana Explorer (Devnet):** https://explorer.solana.com/?cluster=devnet
- **Solana Devnet Faucet:** https://faucet.solana.com/
- **Phantom Wallet:** https://phantom.app/
- **Firebase Console:** https://console.firebase.google.com/
- **Solana Docs:** https://docs.solana.com/

---

## Next Steps

1. ✅ Start backend server
2. ✅ Connect Phantom wallet in app
3. ✅ Discover your first plant
4. ✅ Mint your first NFT (Aurora Seed!)
5. ✅ Check Solana Explorer
6. ✅ View NFT in Phantom wallet
7. ✅ Test community verification
8. ✅ Submit & vote on corrections

**Happy Testing! 🌿✨**
