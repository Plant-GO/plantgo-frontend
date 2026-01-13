/**
 * Request validation middleware
 */

function validateMintRequest(req, res, next) {
  const { walletAddress, plantName, rarity } = req.body;
  
  const errors = [];
  
  if (!walletAddress) {
    errors.push('walletAddress is required');
  } else if (typeof walletAddress !== 'string' || walletAddress.length < 32) {
    errors.push('walletAddress must be a valid Solana public key');
  }
  
  if (!plantName) {
    errors.push('plantName is required');
  } else if (typeof plantName !== 'string' || plantName.length < 1) {
    errors.push('plantName must be a non-empty string');
  }
  
  if (!rarity) {
    errors.push('rarity is required');
  } else {
    const validRarities = [
      'auroraSeed',
      'primordialRelic', 
      'mythicCrest',
      'astralShard',
      'genesisFragment',
      'codexOfInsight',
      'ascendantSeal',
    ];
    if (!validRarities.includes(rarity)) {
      errors.push(`rarity must be one of: ${validRarities.join(', ')}`);
    }
  }
  
  if (errors.length > 0) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors,
    });
  }
  
  next();
}

module.exports = {
  validateMintRequest,
};
