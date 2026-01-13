# PlantGO Blockchain & Peer Verification Testing Guide

## Overview

This document provides comprehensive test cases for validating the blockchain NFT minting system and community peer verification flow in PlantGO. The implementation uses direct Solana devnet RPC calls (MVP mode) with Firestore as the NFT record store.

---

## Architecture Summary

### Blockchain Components
- **Solana RPC Service**: Direct JSON-RPC calls to Solana devnet
- **NFT Minting Service**: Firestore-backed NFT creation with rarity logic
- **Wallet Service**: Phantom wallet integration via deep links

### Verification Components
- **Verification Service**: Community voting and status management
- **Treasure Service**: Plant discovery saving with auto-verification

### Configuration
```
Solana Network: Devnet
RPC URL: https://api.devnet.solana.com
Program ID: 3JD2GSJBLPYwwHLmBzh5MRpDZp2eh4KukzHvR8CvmcAc
```

---

## Test Environment Setup

### Prerequisites
1. Install the PlantGO app on a device/emulator
2. Install Phantom Wallet app
3. Ensure internet connectivity for Solana devnet
4. Have test SOL from devnet faucet

### Firebase Setup
Ensure these Firestore collections exist:
- `treasures`
- `verifications`
- `plant_counters`
- `nft_cards`
- `mint_history`
- `users`

---

## Test Cases

### 1. Wallet Connection Tests

#### TC-WC-001: Connect Phantom Wallet
**Objective**: Verify wallet connection flow works correctly

**Steps**:
1. Open PlantGO app
2. Navigate to Profile tab
3. Tap "Connect Wallet" button
4. App should open Phantom wallet
5. Approve connection in Phantom
6. Return to PlantGO

**Expected Results**:
- [ ] Deep link opens Phantom successfully
- [ ] Wallet address is stored after approval
- [ ] UI shows connected wallet (truncated address)
- [ ] Balance is fetched and displayed

#### TC-WC-002: Wallet Disconnect
**Objective**: Verify wallet disconnection

**Steps**:
1. With connected wallet, tap "Disconnect"
2. Confirm disconnection

**Expected Results**:
- [ ] Wallet address is cleared
- [ ] UI reverts to "Connect Wallet" button
- [ ] NFT collection is cleared from view

#### TC-WC-003: Wallet Reconnection
**Objective**: Verify wallet can be reconnected

**Steps**:
1. Disconnect wallet
2. Reconnect to same or different wallet

**Expected Results**:
- [ ] New connection works without issues
- [ ] Previous wallet data does not persist

---

### 2. Solana RPC Tests

#### TC-RPC-001: Health Check
**Objective**: Verify Solana devnet connectivity

**Steps**:
1. Call `SolanaRPCService.isHealthy()`
2. Check response

**Expected Results**:
- [ ] Returns `true` when devnet is accessible
- [ ] Returns `false` with proper error on network failure

#### TC-RPC-002: Get Balance
**Objective**: Verify SOL balance retrieval

**Steps**:
1. Connect a wallet with known balance
2. Check displayed balance

**Expected Results**:
- [ ] Balance shown matches actual devnet balance
- [ ] Balance updates after transactions

#### TC-RPC-003: Request Airdrop (Devnet Only)
**Objective**: Test devnet airdrop functionality

**Steps**:
1. Connect wallet with low balance
2. Request airdrop of 1 SOL

**Expected Results**:
- [ ] Airdrop transaction is submitted
- [ ] Balance increases by 1 SOL after confirmation
- [ ] Transaction signature is returned

---

### 3. Plant Discovery & Auto-Verification Tests

#### TC-AV-001: High Confidence Auto-Verification (≥60%)
**Objective**: Verify auto-verification for confident identifications

**Steps**:
1. Connect wallet
2. Scan a plant that returns ≥60% confidence
3. Save the treasure

**Expected Results**:
- [ ] Treasure is saved to Firestore
- [ ] `verification.status` = "verified"
- [ ] `treasure.verified` = true
- [ ] NFT is automatically minted
- [ ] Success dialog shows NFT rarity

**Verification Query**:
```javascript
// Check Firestore
db.collection('treasures').doc(treasureId).get()
// Should show: { verified: true, nftMinted: true, nftRarity: "..." }
```

#### TC-AV-002: Low Confidence → Community Verification (<60%)
**Objective**: Verify low-confidence discoveries go to community

**Steps**:
1. Connect wallet
2. Scan a plant with <60% confidence
3. Save the treasure

**Expected Results**:
- [ ] Treasure is saved to Firestore
- [ ] `verification.status` = "pending"
- [ ] `treasure.verified` = false
- [ ] NFT is NOT minted yet
- [ ] Verification entry created with `upvotes: 0, downvotes: 0`

---

### 4. Community Verification Tests

#### TC-CV-001: Upvote Verification (4 upvotes to verify)
**Objective**: Verify community upvote threshold

**Setup**: Create a pending verification

**Steps**:
1. Have 4 different users upvote the verification
2. Check status after 4th upvote

**Expected Results**:
- [ ] After 3rd upvote: status = "pending"
- [ ] After 4th upvote: status = "verified"
- [ ] Associated treasure: `verified = true`
- [ ] NFT is minted after verification
- [ ] Original discoverer receives NFT

#### TC-CV-002: Downvote Rejection (2 downvotes to reject)
**Objective**: Verify community downvote threshold

**Setup**: Create a pending verification

**Steps**:
1. Have 2 different users downvote the verification
2. Check status after 2nd downvote

**Expected Results**:
- [ ] After 1st downvote: status = "pending"
- [ ] After 2nd downvote: status = "rejected"
- [ ] Associated treasure: `verified = false`
- [ ] NO NFT is minted

#### TC-CV-003: User Cannot Vote Twice
**Objective**: Verify duplicate vote prevention

**Steps**:
1. User votes on a verification
2. Same user attempts to vote again

**Expected Results**:
- [ ] Second vote is rejected with error message
- [ ] Vote counts remain unchanged
- [ ] `voters` array contains user ID only once

#### TC-CV-004: Discoverer Cannot Vote Own Discovery
**Objective**: Verify self-voting prevention

**Steps**:
1. User discovers a plant (pending verification)
2. Same user attempts to vote on their own discovery

**Expected Results**:
- [ ] Vote is rejected
- [ ] Error message: "Cannot vote on your own discovery"

#### TC-CV-005: Verification Feed Population
**Objective**: Verify pending verifications appear in feed

**Steps**:
1. Create multiple pending verifications
2. Open Community Verification screen as different user

**Expected Results**:
- [ ] Pending verifications visible in feed
- [ ] User's own discoveries excluded from feed
- [ ] Cards show plant image, name, location
- [ ] Upvote/downvote counts displayed

---

### 5. NFT Minting Tests

#### TC-NFT-001: New Species Detection (AuroraSeed)
**Objective**: Verify first-ever species discovery gets legendary rarity

**Setup**: Ensure plant has never been discovered

**Steps**:
1. Discover a completely new plant species
2. High confidence → auto-verify

**Expected Results**:
- [ ] `isNewSpecies` check returns `true`
- [ ] NFT rarity = "AuroraSeed" 
- [ ] Only ONE AuroraSeed exists for this plant
- [ ] Plant counter created with `firstDiscoveredBy` set

#### TC-NFT-002: First Discovery of Known Plant (PrimordialRelic)
**Objective**: Verify first discovery gets legendary rarity

**Setup**: Ensure plant is known but user hasn't found it

**Steps**:
1. User discovers a plant for the first time (personally)
2. Plant already exists in `plant_counters`

**Expected Results**:
- [ ] `isFirstDiscovery` returns `true` for user
- [ ] NFT rarity = "PrimordialRelic"
- [ ] User added to plant's discoverers list

#### TC-NFT-003: Epic Rarity (MythicCrest - max 20)
**Objective**: Verify epic distribution limit

**Setup**: Plant has been discovered 0-19 times as epic

**Steps**:
1. Discover plant when epic count < 20

**Expected Results**:
- [ ] NFT rarity = "MythicCrest"
- [ ] `epicCount` incremented in plant_counters
- [ ] After 20, should receive rare instead

#### TC-NFT-004: Rare Rarity (AstralShard - max 50)
**Objective**: Verify rare distribution limit

**Setup**: Plant's epic count = 20, rare count < 50

**Steps**:
1. Discover plant

**Expected Results**:
- [ ] NFT rarity = "AstralShard"
- [ ] `rareCount` incremented
- [ ] After 50, should receive common

#### TC-NFT-005: Common Rarity (GenesisFragment - unlimited)
**Objective**: Verify common fallback

**Setup**: Plant's epic = 20, rare = 50

**Steps**:
1. Discover plant

**Expected Results**:
- [ ] NFT rarity = "GenesisFragment"
- [ ] `commonCount` incremented
- [ ] No limit on commons

#### TC-NFT-006: Quiz Winner NFT (AscendantSeal)
**Objective**: Verify quiz winner gets mastery NFT

**Steps**:
1. Complete a plant quiz
2. Answer all questions correctly

**Expected Results**:
- [ ] NFT rarity = "AscendantSeal"
- [ ] NFT linked to quiz/plant

#### TC-NFT-007: Quiz Participation NFT (CodexOfInsight)
**Objective**: Verify quiz participation gets knowledge NFT

**Steps**:
1. Complete a plant quiz
2. Answer at least one question wrong

**Expected Results**:
- [ ] NFT rarity = "CodexOfInsight"
- [ ] NFT linked to quiz/plant

---

### 6. NFT Collection Display Tests

#### TC-COL-001: View NFT Collection
**Objective**: Verify NFT cards screen displays correctly

**Steps**:
1. Connect wallet with existing NFTs
2. Navigate to Collections → NFT Cards

**Expected Results**:
- [ ] Stats header shows totals (Total, Unique Plants, Legendary)
- [ ] Rarity filter chips work
- [ ] NFT cards display with correct gradient colors
- [ ] Tap card shows detail sheet

#### TC-COL-002: Real-time NFT Updates
**Objective**: Verify NFT collection updates in real-time

**Steps**:
1. Open NFT cards screen
2. In another session, mint a new NFT for same wallet

**Expected Results**:
- [ ] New NFT appears without refresh
- [ ] Stats update automatically

#### TC-COL-003: NFT Card Details
**Objective**: Verify NFT detail bottom sheet

**Steps**:
1. Tap on an NFT card
2. View detail sheet

**Expected Results**:
- [ ] Plant name displayed
- [ ] Rarity displayed with color
- [ ] Mint date shown
- [ ] Explorer link (if available) opens Solana explorer

---

### 7. Integration Flow Tests

#### TC-INT-001: Complete Discovery → Auto-Verify → NFT Flow
**Objective**: Test complete happy path

**Steps**:
1. Connect wallet
2. Navigate to a level
3. Scan a plant (≥60% confidence)
4. Save treasure

**Expected Results**:
- [ ] Plant identified successfully
- [ ] Treasure saved
- [ ] Auto-verified (status: verified)
- [ ] NFT minted
- [ ] Success dialog shows NFT
- [ ] NFT appears in collection

#### TC-INT-002: Complete Discovery → Community → NFT Flow
**Objective**: Test community verification path

**Steps**:
1. Connect wallet
2. Scan plant (<60% confidence)
3. Save treasure
4. Have 4 users upvote

**Expected Results**:
- [ ] Treasure saved as pending
- [ ] Verification visible in community feed
- [ ] After 4 upvotes: status changes to verified
- [ ] NFT minted for original discoverer
- [ ] NFT appears in discoverer's collection

#### TC-INT-003: Discovery Without Wallet
**Objective**: Test discovery flow without connected wallet

**Steps**:
1. Ensure no wallet connected
2. Scan and save a plant

**Expected Results**:
- [ ] Discovery saved successfully
- [ ] Treasure marked for NFT minting later
- [ ] Message shown to connect wallet for NFT
- [ ] After connecting wallet, can claim NFT

---

### 8. Edge Case Tests

#### TC-EDGE-001: Network Failure During Mint
**Objective**: Handle network errors gracefully

**Steps**:
1. Start NFT minting
2. Disconnect network mid-process

**Expected Results**:
- [ ] Error displayed to user
- [ ] Treasure remains saved
- [ ] Can retry minting later

#### TC-EDGE-002: Duplicate Plant Discovery
**Objective**: Handle same plant discovered twice by same user

**Steps**:
1. Discover and save a plant
2. Scan and try to save same plant again

**Expected Results**:
- [ ] First discovery creates NFT
- [ ] Second discovery still saves treasure
- [ ] Rarity may be lower (already first discovery)

#### TC-EDGE-003: Concurrent Voting
**Objective**: Handle race conditions in voting

**Steps**:
1. Two users vote simultaneously
2. Check final counts

**Expected Results**:
- [ ] Both votes recorded
- [ ] No race condition
- [ ] Firestore transactions ensure consistency

---

## Firestore Data Verification

### Treasure Document Structure
```javascript
{
  id: "treasure_uuid",
  userId: "user_id",
  plantName: "Rose",
  scientificName: "Rosa",
  confidence: 0.75,
  verified: true,
  nftMinted: true,
  nftMint: "nft_card_id",
  nftRarity: "MythicCrest",
  isNewSpecies: false,
  location: {
    latitude: 27.7172,
    longitude: 85.3240
  },
  discoveredAt: Timestamp
}
```

### Verification Document Structure
```javascript
{
  id: "verification_uuid",
  treasureId: "treasure_id",
  plantName: "Rose",
  userId: "discoverer_id",
  confidence: 0.45,
  status: "pending" | "verified" | "rejected",
  upvotes: 0,
  downvotes: 0,
  voters: [],
  walletAddress: "ABC...XYZ",
  imageUrl: "base64_or_url",
  createdAt: Timestamp
}
```

### Plant Counter Document Structure
```javascript
{
  plantNameKey: "rose_rosa",
  plantName: "Rose",
  scientificName: "Rosa",
  totalDiscoveries: 100,
  epicCount: 20,
  rareCount: 50,
  commonCount: 30,
  isNewSpecies: false,
  firstDiscoveredBy: "user_id",
  discoverers: ["user1", "user2", ...]
}
```

### NFT Card Document Structure
```javascript
{
  id: "nft_uuid",
  nftMint: "simulated_mint_address",
  ownerAddress: "wallet_address",
  plantName: "Rose",
  rarity: "mythicCrest",
  discoveryType: "plant",
  mintedAt: Timestamp,
  treasureId: "treasure_id",
  transactionSignature: "simulated_sig"
}
```

---

## Rarity Distribution Matrix

| Condition | Rarity | Max Per Plant | Visual |
|-----------|--------|---------------|--------|
| First ever species | AuroraSeed | 1 | 🌟 Gold/Rainbow |
| First personal discovery | PrimordialRelic | Unlimited | ⭐ Purple/Gold |
| Epic count < 20 | MythicCrest | 20 | 💜 Purple |
| Rare count < 50 | AstralShard | 50 | 💙 Blue |
| Common | GenesisFragment | Unlimited | ⚪ Gray |
| Quiz Winner | AscendantSeal | Per Quiz | 🏆 Orange |
| Quiz Participant | CodexOfInsight | Per Quiz | 📚 Teal |

---

## Verification Threshold Summary

| Metric | Threshold | Result |
|--------|-----------|--------|
| AI Confidence | ≥ 60% | Auto-verified |
| AI Confidence | < 60% | Pending (community) |
| Community Upvotes | ≥ 4 | Verified |
| Community Downvotes | ≥ 2 | Rejected |

---

## Troubleshooting

### Common Issues

1. **Wallet won't connect**
   - Ensure Phantom is installed
   - Check deep link URL scheme configuration
   - Verify iOS/Android deep link setup

2. **NFT not minting**
   - Check wallet is connected
   - Verify Firebase rules allow writes
   - Check network connectivity

3. **Verification not appearing in feed**
   - Confirm status is "pending"
   - Check query excludes user's own discoveries
   - Verify Firestore indexes

4. **Rarity seems wrong**
   - Check plant_counters document
   - Verify epic/rare counts
   - Confirm isNewSpecies logic

### Debug Logging
Enable debug prints in:
- `TreasureService.saveTreasure()` - prints verification status
- `NFTMintingService.mintPlantDiscoveryNFT()` - prints rarity decision
- `VerificationService.submitVote()` - prints vote processing

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024 | Initial MVP with Firestore-backed minting |

---

## Notes

- **MVP Mode**: Uses Firestore for NFT records instead of actual Solana transactions
- **Production**: Will switch to NFTApiService with backend server for real Solana minting
- **Program ID**: Must match biodex-main Solana program for production
