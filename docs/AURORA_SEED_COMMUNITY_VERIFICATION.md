# 🌟 Aurora Seed for AI-Unidentified Plants (Community Verification Flow)

## How It Works

When a plant is **not identified by AI** but is **identified as a new species through community verification**, it gets **Aurora Seed** rarity!

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: Scanner                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User scans plant → AI tries to identify                   │
│                                                             │
│  Option A: AI Success ✅                                    │
│  ├─> Returns: "Rose"                                        │
│  └─> Goes to normal mint flow                              │
│                                                             │
│  Option B: AI Failure ❌                                    │
│  ├─> Returns: "Unknown Plant" or low confidence            │
│  └─> Goes to Community Verification                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: Community Verification Screen                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Other users see:                                           │
│  • Plant image                                              │
│  • AI said: "Unknown Plant"                                 │
│  • Can submit correction                                    │
│                                                             │
│  Community member corrects:                                 │
│  ├─> "This is actually a Rafflesia arnoldii"               │
│  └─> Submits correction                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: Correction Approval                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  System checks:                                             │
│  ├─> Is "Rafflesia arnoldii" in database?                  │
│  │                                                          │
│  │   NO → isNewSpecies = true ✨                           │
│  │   ├─> Check plant_counters/rafflesia_arnoldii           │
│  │   ├─> Document doesn't exist                            │
│  │   └─> This is a BRAND NEW SPECIES!                      │
│  │                                                          │
│  │   YES → isNewSpecies = false                            │
│  │   ├─> Check plant_counters/rafflesia_arnoldii           │
│  │   ├─> Document exists (totalMinted: 5)                  │
│  │   └─> Known plant, determine rarity from count          │
│  │                                                          │
│  └─> Calls: determineRarity()                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: Rarity Determination (New Species Path)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  IF isNewSpecies = true:                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 🌟 AURORA SEED (Legendary)                          │  │
│  │                                                      │  │
│  │ This plant has NEVER been discovered before!        │  │
│  │                                                      │  │
│  │ Dual Attribution:                                   │  │
│  │ • Original Discoverer: User who scanned it          │  │
│  │ • Identifier: Community member who named it         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  IF isNewSpecies = false:                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Rarity based on counter:                            │  │
│  │ • 1st mint: 🏺 Primordial Relic                    │  │
│  │ • 2-20: 💜 Mythic Crest                            │  │
│  │ • 21-50: 💙 Astral Shard                           │  │
│  │ • 51+: ⬜ Genesis Fragment                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: Create Treasure & Mint NFT                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Creates new treasure document:                             │
│  {                                                          │
│    plantName: "Rafflesia arnoldii",                        │
│    originalPlantName: "Unknown Plant",                     │
│    confidence: 1.0,  // Community verified                 │
│    discoveredBy: "user123", // Original scanner            │
│    identifiedBy: "botanist456", // Community corrector     │
│    nftRarity: "auroraSeed",                                │
│    isCommunityVerified: true,                              │
│    isCorrectedIdentification: true,                        │
│    nftPendingMint: true                                    │
│  }                                                          │
│                                                             │
│  Then mints NFT with dual attribution on Solana!           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Code Implementation

### 1. Check if New Species
```dart
// In plant_correction_service.dart line 131
final isNewSpecies = await _discoveryService.isNewSpecies(
  correction.correctedPlantName
);
```

### 2. Determine Rarity
```dart
// In plant_correction_service.dart line 134
final rarity = await _discoveryService.determineRarity(
  plantName: correction.correctedPlantName,
  isNewSpeciesDiscovery: isNewSpecies,  // 🌟 KEY: This is true for new species!
);
```

### 3. Rarity Logic
```dart
// In plant_discovery_service.dart line 56
Future<NFTRarity> determineRarity({
  required String plantName,
  required bool isNewSpeciesDiscovery,
}) async {
  final counter = await getPlantCounter(plantName);
  
  if (counter == null) {
    if (isNewSpeciesDiscovery) {
      debugPrint('🌟 New species "$plantName" → Aurora Seed');
      return NFTRarity.auroraSeed;  // ← Returns Aurora Seed!
    }
  }
  
  // ... rest of rarity logic
}
```

## Example Scenarios

### Scenario 1: AI Can't Identify, New Species
```
1. User scans rare flower
2. AI: "Unknown Plant" (confidence: 30%)
3. Goes to Community Verification
4. Botanist corrects: "Rafflesia arnoldii"
5. System checks: Never seen before! (isNewSpecies = true)
6. Result: 🌟 AURORA SEED
7. Dual attribution:
   - Discovered by: Original scanner
   - Identified by: Botanist
```

### Scenario 2: AI Can't Identify, Known Species
```
1. User scans common flower in poor lighting
2. AI: "Unknown Plant" (confidence: 25%)
3. Goes to Community Verification
4. User corrects: "Rose"
5. System checks: Rose has 15 previous mints
6. Result: 💜 MYTHIC CREST (16th mint)
7. Dual attribution:
   - Discovered by: Original scanner
   - Identified by: Corrector
```

### Scenario 3: AI Identifies Correctly
```
1. User scans rose
2. AI: "Rose" (confidence: 95%)
3. Checks: Rose has 15 previous mints
4. Result: 💜 MYTHIC CREST (16th mint)
5. Single attribution:
   - Discovered by: Scanner
```

## Key Features

### ✅ Already Implemented
- [x] AI failure detection
- [x] Community verification system
- [x] New species check (`isNewSpecies`)
- [x] Aurora Seed for new species
- [x] Dual attribution (discoverer + identifier)
- [x] Plant counter tracking
- [x] Rarity progression

### Dual Attribution System
When a correction is approved:
```dart
{
  discoveredBy: "user123",           // Person who scanned it
  discoveredByName: "Alice",
  identifiedBy: "botanist456",       // Person who correctly identified it
  identifiedByName: "Dr. Smith",
  isCorrectedIdentification: true,
  originalPlantName: "Unknown Plant",
  correctedPlantName: "Rafflesia arnoldii"
}
```

Both users get credit:
- **Discoverer**: Found the plant in the wild
- **Identifier**: Correctly identified what it is

## Firebase Structure

### Before Correction
```
plant_counters/
  (empty - no Rafflesia arnoldii yet)

treasures/
  {
    id: "xyz123",
    plantName: "Unknown Plant",
    confidence: 0.30,
    discoveredBy: "user123",
    nftMinted: false
  }
```

### After Correction (New Species)
```
plant_counters/
  rafflesia_arnoldii/
    {
      plantName: "rafflesia_arnoldii",
      totalMinted: 1,
      seedCount: 1,        // 🌟 Aurora Seed count
      relicCount: 0,
      epicCount: 0,
      rareCount: 0,
      commonCount: 0
    }

treasures/
  (new document)
  {
    id: "abc789",
    plantName: "Rafflesia arnoldii",
    originalPlantName: "Unknown Plant",
    confidence: 1.0,
    discoveredBy: "user123",
    identifiedBy: "botanist456",
    nftRarity: "auroraSeed",
    isCommunityVerified: true,
    isCorrectedIdentification: true,
    nftPendingMint: true
  }
```

## Testing

### Test New Species Path
1. Create a treasure with very unique plant name:
   ```dart
   plantName: "Extremely Rare Plant XYZ-12345"
   ```

2. Submit correction with even more unique name:
   ```dart
   correctedName: "Botanical Mystery Species Alpha"
   ```

3. Approve correction

4. Check logs for:
   ```
   🌱 isNewSpecies("Botanical Mystery Species Alpha"): true
   🌟 New species "Botanical Mystery Species Alpha" → Aurora Seed
   ```

5. Verify in Firebase:
   - New counter created
   - seedCount = 1
   - Treasure has nftRarity: "auroraSeed"

## Debug Logs

Watch for these logs when testing:
```dart
// When checking if new species
🌱 isNewSpecies("plant_name"): true/false

// When determining rarity
🌟 New species "plant_name" → Aurora Seed

// When creating corrected treasure
✅ Correction approved: Unknown Plant → Correct Name
🎴 Creating treasure for corrected plant
📊 Rarity determined: Aurora Seed
```

## Summary

**YES! ✅** The system is already implemented to give **Aurora Seed** rarity when:

1. AI **fails** to identify a plant (returns "Unknown Plant")
2. Community verification **correctly identifies** it
3. The identified plant is a **NEW SPECIES** (never seen before in the system)

The dual attribution system ensures both the **original discoverer** (who found it) and the **identifier** (who named it correctly) get credit! 🌟🏆
