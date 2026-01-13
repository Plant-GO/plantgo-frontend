# PlantGO NFT Backend

Backend server for minting PlantGO NFTs on Solana.

## Setup

### 1. Install dependencies
```bash
cd backend
npm install
```

### 2. Generate mint authority keypair
```bash
npm run keygen
```

This will generate a new Solana keypair. Copy the secret key to your `.env` file.

### 3. Create .env file
```bash
cp .env.example .env
```

Edit `.env` and add your `MINT_AUTHORITY_SECRET_KEY`.

### 4. Fund the mint authority (Devnet)
```bash
# Using Solana CLI
solana airdrop 2 <YOUR_PUBLIC_KEY> --url devnet

# Or use the faucet
# https://faucet.solana.com/
```

### 5. Start the server
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Health Check
```
GET /health
```

### Get Mint Authority
```
GET /api/mint-authority
```

### Mint NFT
```
POST /api/nft/mint
Content-Type: application/json

{
  "walletAddress": "...",
  "plantName": "Rose",
  "rarity": "mythicCrest",
  "treasureId": "...",
  "imageUrl": "...",
  "scientificName": "Rosa",
  "description": "A beautiful rose",
  "location": { "lat": 27.7, "lng": 85.3 }
}
```

**Rarity values:**
- `auroraSeed` - New species discovery (Legendary)
- `primordialRelic` - First discovery (Legendary)
- `mythicCrest` - Early discovery (Epic)
- `astralShard` - Discovery (Rare)
- `genesisFragment` - Discovery (Common)
- `codexOfInsight` - Quiz participation (Uncommon)
- `ascendantSeal` - Quiz victory (Epic)

## Deployment

### Railway
1. Create a new project on Railway
2. Connect your GitHub repo
3. Add environment variables
4. Deploy

### Render
1. Create a new Web Service
2. Connect your repo, set root to `backend`
3. Add environment variables
4. Deploy

### Docker
```bash
docker build -t plantgo-backend .
docker run -p 3001:3001 --env-file .env plantgo-backend
```

## Security Notes

1. **Never commit `.env`** - It contains your secret key!
2. **Keep `.keypair-backup.json` secure** - Delete after setup
3. **Use HTTPS in production**
4. **Set proper CORS origins**
