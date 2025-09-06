const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const { promisify } = require('util');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
require('dotenv').config();

const app = express();
const execAsync = promisify(exec);
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3001',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use(limiter);

// Logging
app.use(morgan('combined'));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static(path.join(__dirname, 'frontend/build')));

// File upload configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = '/etc/easy-rsa/pending-requests';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Sanitize filename
    const sanitizedName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
    cb(null, `${Date.now()}_${sanitizedName}`);
  }
});

const upload = multer({ 
  storage,
  fileFilter: (req, file, cb) => {
    if (file.originalname.endsWith('.csr') || file.mimetype === 'application/pkcs10') {
      cb(null, true);
    } else {
      cb(new Error('Only .csr files are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB max
  }
});

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'default-secret', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Helper function to execute cert-manager commands safely
const executeCertCommand = async (command, args = []) => {
  try {
    // Validate command to prevent injection
    const allowedCommands = [
      'check-ca',
      'create-ca',
      'create-server',
      'create-client',
      'list-certificates',
      'renew-certificate',
      'process-csr'
    ];
    
    if (!allowedCommands.includes(command)) {
      throw new Error('Invalid command');
    }

    const sanitizedArgs = args.map(arg => arg.replace(/[;&|`$]/g, ''));
    const cmd = `/opt/cert-manager/cert-manager-api ${command} ${sanitizedArgs.join(' ')}`;
    
    const { stdout, stderr } = await execAsync(cmd, {
      cwd: '/etc/easy-rsa',
      timeout: 30000,
      env: { ...process.env, PATH: '/usr/local/bin:/usr/bin:/bin' }
    });

    return { success: true, output: stdout, error: stderr };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Helper function to extract variable from vars file
const extractVar = (content, varName) => {
  const regex = new RegExp(`set_var\\s+${varName}\\s+["']?([^"'\\n]+)["']?`, 'i');
  const match = content.match(regex);
  return match ? match[1].trim() : null;
};

// API Routes

// Authentication
app.post('/api/auth/login', [
  body('username').isLength({ min: 3 }).escape(),
  body('password').isLength({ min: 6 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;
    
    // Simple authentication (in production, use proper user management)
    const validUsername = process.env.ADMIN_USER || 'admin';
    const validPassword = process.env.ADMIN_PASS || 'admin123';
    
    if (username === validUsername && password === validPassword) {
      const token = jwt.sign(
        { username, role: 'admin' },
        process.env.JWT_SECRET || 'default-secret',
        { expiresIn: '24h' }
      );
      
      res.json({ token, user: { username, role: 'admin' } });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Authentication failed' });
  }
});

// CA Status
app.get('/api/ca/status', authenticateToken, async (req, res) => {
  try {
    const caExists = fs.existsSync('/etc/easy-rsa/pki/ca.crt') && fs.existsSync('/etc/easy-rsa/pki/private/ca.key');
    
    if (!caExists) {
      return res.json({
        success: false,
        status: 'inactive',
        message: 'CA not found. Please create a CA first.',
        caFile: false,
        keyFile: false
      });
    }

    // Se la CA esiste, leggi i suoi dettagli
    try {
      const { stdout } = await execAsync('openssl x509 -in /etc/easy-rsa/pki/ca.crt -text -noout', {
        timeout: 5000
      });
      
      // Leggi anche la configurazione vars se disponibile
      let varsConfig = {};
      if (fs.existsSync('/etc/easy-rsa/vars')) {
        const varsContent = fs.readFileSync('/etc/easy-rsa/vars', 'utf8');
        varsConfig = {
          country: extractVar(varsContent, 'EASYRSA_REQ_COUNTRY') || 'N/A',
          province: extractVar(varsContent, 'EASYRSA_REQ_PROVINCE') || 'N/A',
          city: extractVar(varsContent, 'EASYRSA_REQ_CITY') || 'N/A',
          org: extractVar(varsContent, 'EASYRSA_REQ_ORG') || 'N/A',
          email: extractVar(varsContent, 'EASYRSA_REQ_EMAIL') || 'N/A',
          ou: extractVar(varsContent, 'EASYRSA_REQ_OU') || 'N/A'
        };
      }

      res.json({
        success: true,
        status: 'active',
        message: 'CA is active and valid',
        caFile: true,
        keyFile: true,
        details: stdout,
        vars: varsConfig
      });
    } catch (opensslError) {
      res.json({
        success: false,
        status: 'error',
        message: 'CA files exist but cannot read certificate details',
        caFile: true,
        keyFile: true,
        error: opensslError.message
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get vars configuration
app.get('/api/config/vars', authenticateToken, async (req, res) => {
  try {
    const varsPath = '/etc/easy-rsa/vars';
    if (!fs.existsSync(varsPath)) {
      return res.json({
        exists: false,
        config: {
          country: 'IT',
          province: 'Rome',
          city: 'Rome',
          org: 'My Organization',
          email: 'admin@example.com',
          ou: 'IT Department',
          keySize: 2048,
          caExpire: 3650,
          certExpire: 365,
          digest: 'sha256'
        }
      });
    }

    const content = fs.readFileSync(varsPath, 'utf8');
    const config = {
      country: extractVar(content, 'EASYRSA_REQ_COUNTRY') || 'IT',
      province: extractVar(content, 'EASYRSA_REQ_PROVINCE') || 'Rome',
      city: extractVar(content, 'EASYRSA_REQ_CITY') || 'Rome',
      org: extractVar(content, 'EASYRSA_REQ_ORG') || 'My Organization',
      email: extractVar(content, 'EASYRSA_REQ_EMAIL') || 'admin@example.com',
      ou: extractVar(content, 'EASYRSA_REQ_OU') || 'IT Department',
      keySize: parseInt(extractVar(content, 'EASYRSA_KEY_SIZE')) || 2048,
      caExpire: parseInt(extractVar(content, 'EASYRSA_CA_EXPIRE')) || 3650,
      certExpire: parseInt(extractVar(content, 'EASYRSA_CERT_EXPIRE')) || 365,
      digest: extractVar(content, 'EASYRSA_DIGEST') || 'sha256'
    };

    res.json({ exists: true, config });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update vars configuration
app.post('/api/config/vars', authenticateToken, [
  body('country').isLength({ min: 2, max: 2 }).isAlpha(),
  body('province').isLength({ min: 1 }).escape(),
  body('city').isLength({ min: 1 }).escape(),
  body('org').isLength({ min: 1 }).escape(),
  body('email').isEmail(),
  body('ou').optional().isLength({ min: 1 }).escape(),
  body('keySize').optional().isInt({ min: 1024, max: 4096 }),
  body('caExpire').optional().isInt({ min: 1, max: 10950 }),
  body('certExpire').optional().isInt({ min: 1, max: 3650 }),
  body('digest').optional().isIn(['sha256', 'sha384', 'sha512'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      country, province, city, org, email,
      ou = 'IT Department',
      keySize = 2048,
      caExpire = 3650,
      certExpire = 365,
      digest = 'sha256'
    } = req.body;

    const varsContent = `set_var EASYRSA_REQ_COUNTRY     "${country}"
set_var EASYRSA_REQ_PROVINCE    "${province}"
set_var EASYRSA_REQ_CITY        "${city}"
set_var EASYRSA_REQ_ORG         "${org}"
set_var EASYRSA_REQ_EMAIL       "${email}"
set_var EASYRSA_REQ_OU          "${ou}"
set_var EASYRSA_KEY_SIZE        ${keySize}
set_var EASYRSA_CA_EXPIRE       ${caExpire}
set_var EASYRSA_CERT_EXPIRE     ${certExpire}
set_var EASYRSA_DIGEST          "${digest}"
`;

    const varsPath = '/etc/easy-rsa/vars';
    fs.writeFileSync(varsPath, varsContent, 'utf8');
    
    res.json({ 
      success: true, 
      message: 'Configuration updated successfully',
      config: { country, province, city, org, email, ou, keySize, caExpire, certExpire, digest }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create CA
app.post('/api/ca/create', authenticateToken, [
  body('country').isLength({ min: 2, max: 2 }).isAlpha(),
  body('province').isLength({ min: 1 }).escape(),
  body('city').isLength({ min: 1 }).escape(),
  body('org').isLength({ min: 1 }).escape(),
  body('email').isEmail()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { country, province, city, org, email, ou } = req.body;
    const result = await executeCertCommand('create-ca', [
      country, province, city, org, email, ou || 'IT Department'
    ]);
    
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// List certificates
app.get('/api/certificates', authenticateToken, async (req, res) => {
  try {
    const issuedDir = '/etc/easy-rsa/pki/issued';
    
    // Check if directory exists
    if (!fs.existsSync(issuedDir)) {
      return res.json({ success: true, certificates: [] });
    }

    // Read all .crt files from issued directory
    const files = fs.readdirSync(issuedDir).filter(file => file.endsWith('.crt'));
    const certificates = [];
    
    for (const file of files) {
      try {
        const name = file.replace('.crt', '');
        const certPath = path.join(issuedDir, file);
        
        // Get certificate details using openssl - including extensions
        const [basicInfo, extInfo] = await Promise.all([
          execAsync(`openssl x509 -in "${certPath}" -noout -startdate -enddate -subject`, { timeout: 5000 }),
          execAsync(`openssl x509 -in "${certPath}" -text -noout | grep -A3 "Extended Key Usage"`, { timeout: 5000 }).catch(() => ({ stdout: '' }))
        ]);
        
        // Parse basic certificate info
        const lines = basicInfo.stdout.split('\n');
        let created = null;
        let expires = null;
        let subject = null;
        
        for (const line of lines) {
          if (line.startsWith('notBefore=')) {
            created = new Date(line.replace('notBefore=', ''));
          } else if (line.startsWith('notAfter=')) {
            expires = new Date(line.replace('notAfter=', ''));
          } else if (line.startsWith('subject=')) {
            subject = line.replace('subject=', '');
          }
        }
        
        // Determine certificate type using multiple criteria
        let type = 'server'; // default
        
        // Check Extended Key Usage first (most reliable)
        if (extInfo.stdout.includes('TLS Web Client Authentication')) {
          type = 'client';
        } else if (extInfo.stdout.includes('TLS Web Server Authentication')) {
          type = 'server';
        } else {
          // Fallback to name-based detection
          if (name.includes('client') || name.includes('user') || name.includes('admin') || subject?.includes('@')) {
            type = 'client';
          }
        }
        
        certificates.push({
          name,
          type,
          created: created ? created.toISOString() : null,
          expires: expires ? expires.toISOString() : null,
          subject: subject,
          status: 'active'
        });
        
      } catch (error) {
        console.error(`Error processing certificate ${file}:`, error);
        // Add basic info even if we can't parse details
        const name = file.replace('.crt', '');
        certificates.push({
          name,
          type: 'server',
          created: null,
          expires: null,
          subject: null,
          status: 'unknown'
        });
      }
    }
    
    res.json({
      success: true,
      certificates: certificates
    });
  } catch (error) {
    console.error('Error fetching certificates:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create server certificate
app.post('/api/certificates/server', authenticateToken, [
  body('name').isLength({ min: 1 }).matches(/^[a-z0-9._-]+$/),
  body('ip').optional().isIP(),
  body('dns').optional().isFQDN()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, ip, dns } = req.body;
    const result = await executeCertCommand('create-server', [name, ip || '', dns || '']);
    
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create client certificate
app.post('/api/certificates/client', authenticateToken, [
  body('name').isLength({ min: 1 }).matches(/^[a-zA-Z0-9._-]+$/),
  body('email').optional().isEmail()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email } = req.body;
    const result = await executeCertCommand('create-client', [name, email || '']);
    
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Upload and process CSR
app.post('/api/csr/upload', authenticateToken, upload.single('csr'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No CSR file uploaded' });
    }

    const { type } = req.body; // 'server' or 'client'
    if (!['server', 'client'].includes(type)) {
      return res.status(400).json({ error: 'Invalid certificate type' });
    }

    const result = await executeCertCommand('process-csr', [req.file.filename, type]);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Renew certificate
app.post('/api/certificates/:name/renew', authenticateToken, async (req, res) => {
  try {
    const { name } = req.params;
    const sanitizedName = name.replace(/[^a-zA-Z0-9._-]/g, '');
    
    const result = await executeCertCommand('renew-certificate', [sanitizedName]);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Export/sync certificates to accessible directory
app.post('/api/certificates/sync', authenticateToken, async (req, res) => {
  try {
    const { execSync } = require('child_process');
    
    // Create export directories
    execSync('mkdir -p /data/certificates/server /data/certificates/client');
    
    // Copy CA if exists
    if (fs.existsSync('/etc/easy-rsa/pki/ca.crt')) {
      execSync('cp /etc/easy-rsa/pki/ca.crt /data/certificates/ca.crt');
    }
    
    // Copy all issued certificates
    if (fs.existsSync('/etc/easy-rsa/pki/issued')) {
      try {
        const issuedFiles = fs.readdirSync('/etc/easy-rsa/pki/issued');
        let copiedCount = 0;
        
        issuedFiles.forEach(file => {
          if (file.endsWith('.crt')) {
            const certName = file.replace('.crt', '');
            // Try to determine if it's server or client cert (simplified logic)
            const destDir = '/data/certificates/server'; // Default to server for now
            execSync(`cp "/etc/easy-rsa/pki/issued/${file}" "${destDir}/${file}"`);
            copiedCount++;
          }
        });
        
        res.json({
          success: true,
          message: `Synchronized ${copiedCount} certificates to export directory`,
          exported: copiedCount
        });
      } catch (dirError) {
        res.json({
          success: false,
          message: 'No certificates to sync',
          exported: 0
        });
      }
    } else {
      res.json({
        success: false,
        message: 'No certificates directory found',
        exported: 0
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Download CA certificate
app.get('/api/ca/download', authenticateToken, (req, res) => {
  try {
    const caFilePath = '/etc/easy-rsa/pki/ca.crt';
    
    if (fs.existsSync(caFilePath)) {
      res.download(caFilePath, 'ca.crt');
    } else {
      res.status(404).json({ error: 'CA certificate not found. Please create a CA first.' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Download CA private key - CRITICAL SECURITY WARNING
app.get('/api/ca/download-key', authenticateToken, (req, res) => {
  try {
    const caKeyPath = '/etc/easy-rsa/pki/private/ca.key';
    
    if (fs.existsSync(caKeyPath)) {
      // Add security headers and warning
      res.setHeader('X-Security-Warning', 'PRIVATE-KEY-DOWNLOAD');
      res.setHeader('Content-Disposition', 'attachment; filename="ca.key"');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
      
      res.download(caKeyPath, 'ca.key');
    } else {
      res.status(404).json({ error: 'CA private key not found. Please create a CA first.' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Download certificate
app.get('/api/certificates/:name/download/:type', authenticateToken, (req, res) => {
  try {
    const { name, type } = req.params;
    const sanitizedName = name.replace(/[^a-zA-Z0-9._-]/g, '');
    
    let filePath;
    let filename;
    
    if (type === 'cert') {
      filePath = `/etc/easy-rsa/pki/issued/${sanitizedName}.crt`;
      filename = `${sanitizedName}.crt`;
    } else if (type === 'key') {
      filePath = `/etc/easy-rsa/pki/private/${sanitizedName}.key`;
      filename = `${sanitizedName}.key`;
    } else if (type === 'ca') {
      filePath = `/etc/easy-rsa/pki/ca.crt`;
      filename = 'ca.crt';
    } else {
      return res.status(400).json({ error: 'Invalid file type. Use: cert, key, or ca' });
    }

    if (fs.existsSync(filePath)) {
      res.download(filePath, filename);
    } else {
      res.status(404).json({ 
        error: `File not found: ${filename}`,
        hint: type === 'key' ? 'Private keys may not be accessible via web interface for security reasons' : 'Certificate may not exist or may not have been created successfully'
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete certificate (both cert and key)
app.delete('/api/certificates/:name', authenticateToken, async (req, res) => {
  try {
    const { name } = req.params;
    
    // Validate certificate name
    if (!name || !name.match(/^[a-zA-Z0-9._-]+$/)) {
      return res.status(400).json({ error: 'Invalid certificate name' });
    }
    
    const certPath = `/etc/easy-rsa/pki/issued/${name}.crt`;
    const keyPath = `/etc/easy-rsa/pki/private/${name}.key`;
    const reqPath = `/etc/easy-rsa/pki/reqs/${name}.req`;
    
    let deletedFiles = [];
    let errors = [];
    
    // Delete certificate file
    if (fs.existsSync(certPath)) {
      try {
        fs.unlinkSync(certPath);
        deletedFiles.push('certificate');
      } catch (error) {
        errors.push(`Failed to delete certificate: ${error.message}`);
      }
    } else {
      errors.push('Certificate file not found');
    }
    
    // Delete private key file
    if (fs.existsSync(keyPath)) {
      try {
        fs.unlinkSync(keyPath);
        deletedFiles.push('private key');
      } catch (error) {
        errors.push(`Failed to delete private key: ${error.message}`);
      }
    } else {
      errors.push('Private key file not found');
    }
    
    // Delete request file (optional)
    if (fs.existsSync(reqPath)) {
      try {
        fs.unlinkSync(reqPath);
        deletedFiles.push('certificate request');
      } catch (error) {
        // Not critical if request file can't be deleted
        console.warn(`Failed to delete request file: ${error.message}`);
      }
    }
    
    // Also try to revoke the certificate using Easy-RSA
    try {
      const { stdout, stderr } = await execAsync(`cd /etc/easy-rsa && ./easyrsa revoke ${name}`, { timeout: 10000 });
      console.log('Certificate revoked:', stdout);
      deletedFiles.push('revoked from CA');
    } catch (revokeError) {
      // Revocation might fail if already revoked or if files are missing
      console.warn('Failed to revoke certificate:', revokeError.message);
    }
    
    if (deletedFiles.length > 0) {
      res.json({
        success: true,
        message: `Successfully deleted: ${deletedFiles.join(', ')}`,
        deleted: deletedFiles,
        warnings: errors.length > 0 ? errors : undefined
      });
    } else {
      res.status(404).json({
        success: false,
        message: `Certificate '${name}' not found or could not be deleted`,
        errors: errors
      });
    }
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Logout endpoint
app.post('/api/logout', authenticateToken, (req, res) => {
  // In a real app, you might invalidate the token here
  // For simplicity, we'll just return success and let the frontend handle it
  res.json({ 
    success: true, 
    message: 'Logged out successfully' 
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Serve React app for any other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/build/index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Initialize Easy-RSA on startup
const initializeEasyRSA = () => {
  const fs = require('fs');
  const { execSync } = require('child_process');
  
  try {
    // Ensure easyrsa symlink exists
    const symlinkPath = '/etc/easy-rsa/easyrsa';
    const targetPath = '/usr/share/easy-rsa/easyrsa';
    
    if (!fs.existsSync(symlinkPath) && fs.existsSync(targetPath)) {
      execSync(`ln -sf ${targetPath} ${symlinkPath}`);
      console.log('✓ Easy-RSA symlink created');
    }
    
    // Copy template files if they don't exist
    if (!fs.existsSync('/etc/easy-rsa/vars') && fs.existsSync('/opt/cert-manager/templates/vars')) {
      execSync('cp /opt/cert-manager/templates/vars /etc/easy-rsa/');
      console.log('✓ Vars file copied');
    }
    
    if (!fs.existsSync('/etc/easy-rsa/openssl-easyrsa.cnf') && fs.existsSync('/opt/cert-manager/templates/openssl-easyrsa.cnf')) {
      execSync('cp /opt/cert-manager/templates/openssl-easyrsa.cnf /etc/easy-rsa/');
      console.log('✓ OpenSSL config copied');
    }
  } catch (error) {
    console.error('Warning: Failed to initialize Easy-RSA:', error.message);
  }
};

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Certificate Manager Web Interface running on port ${PORT}`);
  console.log(`📱 Frontend: http://localhost:${PORT}`);
  console.log(`🔧 API: http://localhost:${PORT}/api`);
  
  // Initialize Easy-RSA after server start
  setTimeout(initializeEasyRSA, 1000);
});

module.exports = app;