/**
 * Generate a new Solana keypair for mint authority
 * 
 * Run with: npm run keygen
 */

const { Keypair } = require('@solana/web3.js');
const bs58 = require('bs58');
const fs = require('fs');
const path = require('path');

function generateKeypair() {
  console.log('🔑 Generating new Solana keypair...\n');
  
  const keypair = Keypair.generate();
  
  const publicKey = keypair.publicKey.toBase58();
  const secretKey = bs58.encode(keypair.secretKey);
  
  console.log('='.repeat(60));
  console.log('PUBLIC KEY (Share this):');
  console.log(publicKey);
  console.log('='.repeat(60));
  console.log('\n⚠️  SECRET KEY (Keep this PRIVATE! Never share!):');
  console.log(secretKey);
  console.log('='.repeat(60));
  
  console.log('\n📝 Instructions:');
  console.log('1. Copy the SECRET KEY above');
  console.log('2. Add it to your .env file:');
  console.log(`   MINT_AUTHORITY_SECRET_KEY=${secretKey}`);
  console.log('\n3. For devnet, fund this wallet with SOL:');
  console.log(`   solana airdrop 2 ${publicKey} --url devnet`);
  console.log('   Or use: https://faucet.solana.com/');
  
  // Save to file for backup
  const backupPath = path.join(__dirname, '..', '.keypair-backup.json');
  fs.writeFileSync(backupPath, JSON.stringify({
    publicKey,
    secretKey,
    generatedAt: new Date().toISOString(),
    warning: 'KEEP THIS FILE SECURE! Delete after copying to .env',
  }, null, 2));
  
  console.log(`\n💾 Backup saved to: ${backupPath}`);
  console.log('   ⚠️  Delete this file after copying the secret key to .env!');
}

generateKeypair();
