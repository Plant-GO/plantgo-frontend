# 🔍 Why Are All Plants Getting "Aurora Seed" Rarity?

## The Issue

You're seeing **Aurora Seed** (legendary rarity) for every plant you scan, instead of getting different rarities. This is happening for one of these reasons:

## Root Causes

### 1. **AI Identifies Each Plant with Different Names** (Most Likely)
The AI might be generating slightly different names each time it sees the same plant:
- First scan: "Rose"
- Second scan: "Red Rose"  
- Third scan: "Rosa damascena"
- Fourth scan: "Garden Rose"

**Each different name = New Species = Aurora Seed** 🌟

### 2. **Simulated Mints Instead of Real NFTs**
If the app can't reach the backend, it creates **simulated NFTs** with prefix `sim_xxxxx`:
- Real NFT: `7FNv8pfHGDFKt5n4oBDXB4BEjytBgvwfuXj51gvFm6FB`
- Simulated: `sim_a1b2c3d4`

Simulated mints don't check Firebase for existing plants, so everything appears "new".

### 3. **Backend Not Receiving Requests**
If backend gets no requests, it can't update plant counters in Firebase.

## How NFT Rarity Actually Works

```
Plant Name Normalization:
"Rose" → "rose"
"Red Rose" → "red_rose"  
"Rosa damascena" → "rosa_damascena"

These are stored as DIFFERENT plants in Firebase!
```

### Rarity Ladder (From Most to Least Rare)

1. **Aurora Seed** 🌟 (Legendary)
   - Condition: Brand NEW species never seen before
   - Example: First time ANYONE scans "Rafflesia arnoldii"

2. **Primordial Relic** 🏺 (Legendary)
   - Condition: First discovery of a KNOWN species
   - Example: First person to scan "rose" (but rose was discovered before)

3. **Mythic Crest** 💜 (Epic)
   - Condition: 2nd-20th mint of same plant
   - Example: 5th person to scan "rose"

4. **Astral Shard** 💙 (Rare)
   - Condition: 21st-50th mint of same plant
   - Example: 35th person to scan "rose"

5. **Genesis Fragment** ⬜ (Common)
   - Condition: 51st+ mint of same plant
   - Example: 100th person to scan "rose"

## Diagnosis

### Check 1: Are You Getting Real or Simulated NFTs?

**Open your app logs and look for:**
```
✅ Real NFT minted on Solana: 7FNv8pfHGDFKt5n4oBDXB...
```
vs
```
⚠️ Backend unavailable, using simulated mint
```

**How to check:**
1. Open terminal
2. Run: `flutter logs` (while app is running)
3. Scan a plant
4. Look for mint messages

### Check 2: What Plant Names Are Being Used?

**Look at Firebase Console:**
1. Go to Firebase Console → Firestore
2. Open `plant_counters` collection
3. Check the document IDs (these are the normalized plant names)

**Example of the problem:**
```
Documents in plant_counters:
- rose
- red_rose
- rosa_damascena
- garden_rose

All treated as different species! ❌
```

**What it should look like:**
```
Documents in plant_counters:
- rose (totalMinted: 45, epicCount: 20, rareCount: 30)
- tulip (totalMinted: 12, epicCount: 10, rareCount: 2)
- orchid (totalMinted: 3, epicCount: 3)

Same plant = higher count! ✅
```

### Check 3: Is Backend Receiving Requests?

**Look at backend terminal logs:**
```bash
# Good - backend is working:
POST /api/nft/mint - 200 OK
✅ NFT Minted successfully
   Plant: rose
   Rarity: mythicCrest
   Mint: 7FNv8pfHGDFKt5n4o...

# Bad - no requests coming in:
(silence... no POST requests)
```

## Solutions

### Solution 1: Standardize Plant Names

**Option A: Use Scientific Names**
Update your AI prompt to always return scientific names:
```dart
// In your plant identification code
String plantName = identificationResult['scientificName']; // "Rosa damascena"
// NOT: identificationResult['commonName']; // "Rose" or "Red Rose" (varies)
```

**Option B: Normalize in App**
Create a mapping of common names to canonical names:
```dart
Map<String, String> plantNameMapping = {
  'red rose': 'rose',
  'garden rose': 'rose',
  'rosa damascena': 'rose',
  'rosa': 'rose',
};

String getCanonicalName(String aiName) {
  final normalized = aiName.toLowerCase().trim();
  return plantNameMapping[normalized] ?? normalized;
}
```

### Solution 2: Fix Backend Connection

**If you're seeing simulated mints:**

1. **Configure backend IP in app:**
   ```
   Course Map → Settings ⚙️
   Enter: 192.168.201.134
   Tap: Test & Save
   ```

2. **Restart backend with fix:**
   ```bash
   cd backend
   npm start
   ```

3. **Verify connection:**
   ```bash
   ./test-backend-connection.sh
   ```

### Solution 3: Use Community Verification

The app has a **Community Verification** feature where users can correct misidentified plants. This helps standardize names over time.

## Testing Rarity Progression

To test if rarity is working correctly:

### Test 1: Scan Same Plant Multiple Times
```bash
# Clear Firebase data first (optional)
# Then scan the EXACT same plant repeatedly

Scan 1: "Rose" → Should get Aurora Seed (new)
Scan 2: "Rose" → Should get Mythic Crest (epic)
Scan 3: "Rose" → Should get Mythic Crest (epic)
...
Scan 21: "Rose" → Should get Astral Shard (rare)
...
Scan 51: "Rose" → Should get Genesis Fragment (common)
```

### Test 2: Check Firebase Counter
After each scan, check Firebase:
```
plant_counters/rose:
{
  plantName: "rose",
  totalMinted: 5,
  seedCount: 1,    // Aurora Seed count
  relicCount: 0,   // Primordial Relic count  
  epicCount: 4,    // Mythic Crest count
  rareCount: 0,    // Astral Shard count
  commonCount: 0   // Genesis Fragment count
}
```

### Test 3: Scan Different Plants
```bash
Scan "Rose" → Aurora Seed (new species)
Scan "Tulip" → Aurora Seed (new species)
Scan "Rose" again → Mythic Crest (2nd mint of rose)
Scan "Orchid" → Aurora Seed (new species)
Scan "Tulip" again → Mythic Crest (2nd mint of tulip)
```

## Debug Commands

### See What's Stored in Firebase
```dart
// Add to your debug screen
final counters = await FirebaseFirestore.instance
    .collection('plant_counters')
    .get();

for (var doc in counters.docs) {
  print('${doc.id}: ${doc.data()}');
}
```

### See Real-Time Mint Logs
```bash
# Terminal 1 - Backend logs
cd backend && npm start

# Terminal 2 - Flutter logs  
flutter logs

# Terminal 3 - Test connection
./test-backend-connection.sh
```

### Force Backend Minting
```dart
// In nft_minting_service.dart
static bool useRealBlockchain = true; // Make sure this is true!
```

## Expected Behavior Summary

### Correct Flow:
```
1. AI identifies plant: "rose"
2. App checks Firebase: plant_counters/rose
3. Counter shows: totalMinted = 5
4. Determines rarity: Mythic Crest (epic, 6th mint)
5. Sends to backend: POST /api/nft/mint
6. Backend mints on Solana devnet
7. Returns: { nftMint: "7FNv...", signature: "2pF..." }
8. App updates Firebase: totalMinted = 6, epicCount = 6
9. Shows success with real NFT address
```

### Incorrect Flow (Your Issue):
```
1. AI identifies plant: "Rosa damascena" 
2. App checks Firebase: plant_counters/rosa_damascena
3. Counter NOT FOUND (first time seeing this name)
4. Determines rarity: Aurora Seed (new species)
5. Backend times out or not configured
6. Falls back to simulated: { nftMint: "sim_a1b2c3d4" }
7. Creates new counter: totalMinted = 1
8. Next scan: AI says "Red Rose" (different name!)
9. Repeat → Everything is Aurora Seed
```

## Quick Fix Checklist

- [ ] Configure backend IP in app settings (192.168.201.134)
- [ ] Restart backend: `cd backend && npm start`
- [ ] Check backend logs show incoming requests
- [ ] Verify plant names are consistent (check Firebase)
- [ ] Look for real NFT addresses (not sim_xxxxx)
- [ ] Test scanning same plant 3+ times
- [ ] Should see rarity change from Aurora → Mythic → Astral

## Still Having Issues?

Run diagnostics:
```bash
./diagnose-nft-minting.sh
```

Check logs:
```bash
flutter logs | grep "🎴"
```

The most likely issue is **inconsistent plant names from AI**. Consider using scientific names or implementing a name normalization layer! 🌱
