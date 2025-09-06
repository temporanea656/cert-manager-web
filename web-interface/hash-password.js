#!/usr/bin/env node
/**
 * Password Hash Generator for Certificate Manager
 * 
 * Usage:
 *   node hash-password.js "your-password"
 *   npm run hash-password "your-password"
 */

const bcrypt = require('bcryptjs');

function generatePasswordHash(password) {
  if (!password) {
    console.error('❌ Error: Password is required');
    console.log('\n📖 Usage:');
    console.log('  node hash-password.js "your-secure-password"');
    console.log('  npm run hash-password "your-secure-password"');
    process.exit(1);
  }

  if (password.length < 6) {
    console.error('❌ Error: Password must be at least 6 characters long');
    process.exit(1);
  }

  console.log('🔐 Generating secure password hash...\n');

  // Generate salt and hash (12 rounds for good security/performance balance)
  const saltRounds = 12;
  const hash = bcrypt.hashSync(password, saltRounds);

  console.log('✅ Password hash generated successfully!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`🔑 Hash: ${hash}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  console.log('📋 Next steps:');
  console.log('1. Copy the hash above');
  console.log('2. Add to your .env file:');
  console.log(`   ADMIN_PASS_HASH=${hash}`);
  console.log('3. Remove or comment out ADMIN_PASS (if present)');
  console.log('4. Restart your application: docker-compose restart cert-manager-web\n');

  console.log('🔒 Security Notes:');
  console.log('• Your original password is never stored');
  console.log('• The hash is safe to store in configuration files');
  console.log('• Use the original password to login, not the hash');
  console.log('• Keep your original password secure and memorable\n');

  return hash;
}

// Get password from command line argument
const password = process.argv[2];

if (require.main === module) {
  generatePasswordHash(password);
}

module.exports = { generatePasswordHash };