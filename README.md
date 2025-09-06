# Certificate Manager

**🏭 Dual Distribution PKI System for Hobby and Professional Use**

Certificate Manager è un sistema completo per la gestione di Certificate Authority (CA) distribuito in **due versioni complementari**:

## 📦 **Distribution Modes**

### 🖥️ **Command Line Interface** 
**Sistema modulare installabile tramite Make per uso tramite terminale**
- Installazione: `sudo make install` 
- Utilizzo: `cert-manager` (comando globale)
- Target: Amministratori di sistema e utenti CLI

### 🌐 **Web Application Interface**
**Interfaccia web moderna containerizzata tramite Docker**
- Deployment: `docker-compose up -d`
- Accesso: Browser web su `http://localhost:3000`
- Target: Utenti che preferiscono interfacce grafiche

---

## 🚀 Features Overview

### Core PKI Management
- **Complete CA Operations**: Creation, verification, and management of Certificate Authority
- **Server & Client Certificates**: Automated generation with Subject Alternative Names (SAN)
- **External CSR Signing**: Import and sign external certificate requests
- **Certificate Lifecycle**: List, monitor expiration, and renewal
- **Organized Structure**: Clean directory structure with automatic organization
- **Security-First**: Proper permissions, backup strategies, audit logging

### Web Interface Exclusive Features
- **Modern Dashboard**: Real-time PKI overview with interactive charts
- **JWT Authentication**: Secure token-based user authentication
- **API Integration**: RESTful API for programmatic access
- **Docker Ready**: Full containerization with multi-stage builds
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Health Monitoring**: Built-in system health checks

---

## 📋 Prerequisites

### For Command Line Installation
- **Easy-RSA**: PKI management system
- **OpenSSL**: Cryptographic operations
- **Bash**: Standard Unix/Linux shell
- **Linux/Unix Environment**

### For Web Application (Docker)
- **Docker Engine 20.10+**
- **Docker Compose 2.0+**
- **2GB RAM minimum**
- **10GB disk space**

### Installing Prerequisites
**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install easy-rsa openssl docker.io docker-compose
```

**CentOS/RHEL:**
```bash
sudo yum install easy-rsa openssl docker docker-compose
```

**Arch Linux:**
```bash
sudo pacman -S easy-rsa openssl docker docker-compose
```

---

## 🔧 Installation & Quick Start

## 📁 Project Structure
```
cert-manager/
├── 🐳 Docker Configuration
│   ├── Dockerfile                 # Container build configuration
│   ├── docker-compose.yml         # Multi-service orchestration
│   └── .dockerignore              # Build context exclusions
├── 🖥️ Command Line System
│   ├── cert-manager               # Main CLI script
│   ├── install.sh                # Installation script
│   ├── Makefile                   # Build automation
│   ├── easyrsa                    # Easy-RSA template script
│   ├── openssl-easyrsa.cnf        # OpenSSL configuration template
│   ├── vars                       # CA parameters template
│   └── modules/                   # Functional modules
│       ├── verificaCA.sh          # CA verification
│       ├── parametriVARS.sh       # VARS parameter management
│       ├── creazioneCA.sh         # Certificate Authority creation
│       ├── creazioneSERVER.sh     # Server certificate generation
│       ├── creazioneCLIENT.sh     # Client certificate generation
│       ├── firmaCSR.sh            # Certificate signing requests
│       ├── listaCERTIFICATI.sh    # Certificate listing & management
│       └── rinnovoCERTIFICATI.sh  # Certificate renewal
└── 🌐 Web Interface
    ├── web-interface/
    │   ├── server.js              # Node.js backend API
    │   ├── package.json           # Backend dependencies
    │   ├── .env.example           # Environment configuration template
    │   └── frontend/              # React frontend application
    │       ├── src/
    │       ├── public/
    │       └── package.json       # Frontend dependencies
    └── certificates/              # Generated certificates export directory
```

---

## 🖥️ Command Line Interface Installation

### Method 1: Makefile (Recommended)
```bash
# Clone repository
git clone https://github.com/yourusername/cert-manager.git
cd cert-manager

# Verify files
make check

# Install as system command
sudo make install

# Verify installation
cert-manager --version
```

### Method 2: Installation Script
```bash
# Make installation script executable
chmod +x install.sh

# Complete installation
sudo ./install.sh

# Workspace only setup
sudo ./install.sh setup-workspace

# Uninstall
sudo ./install.sh uninstall
```

### CLI Usage
```bash
# Start interactive menu
cert-manager

# System quick check
cert-manager --check

# Show help
cert-manager --help
```

### CLI Workflow
1. **Initial Setup**: `sudo make install`
2. **Configure VARS**: `cert-manager` → option 2 (country, organization, etc.)
3. **Create CA**: `cert-manager` → option 3
4. **Generate Certificates**: Options 4 (server) or 5 (client)
5. **Manage Certificates**: Option 7 (list, renew, monitor expiration)

---

## 🌐 Web Application Deployment

### Quick Docker Deployment
```bash
# Clone repository
git clone https://github.com/yourusername/cert-manager.git
cd cert-manager

# Configure environment
cp web-interface/.env.example web-interface/.env
# Edit .env with your settings

# Start web application
docker-compose up -d

# Check status
docker-compose ps
```

### Web Interface Access
- **URL**: http://localhost:3000
- **Default Username**: `admin`
- **Default Password**: `change-this-password` (configure in `.env`)

### Web Application Features
#### Dashboard
- **PKI Overview**: Real-time status of CA and certificates
- **Visual Analytics**: Charts showing certificate types and expiration status
- **Quick Actions**: Direct access to common operations

#### Certificate Management
- **CA Operations**: Create and manage Certificate Authority through web UI
- **Server Certificates**: Generate with Subject Alternative Names (SAN)
- **Client Certificates**: User and device certificate generation
- **CSR Processing**: Upload and sign external certificate requests
- **Download Center**: Secure certificate and key download

#### Security
- **JWT Authentication**: Secure token-based authentication
- **Rate Limiting**: API protection against abuse
- **Input Validation**: Comprehensive security validation
- **Audit Logging**: Complete operation tracking

---

## ⚙️ Configuration

### Environment Variables (Web Application)
```env
# Security (CHANGE THESE!)
JWT_SECRET=your-super-secret-jwt-key-change-this
ADMIN_USER=admin
ADMIN_PASS=your-secure-password-change-this

# Server Configuration
NODE_ENV=production
PORT=3000
HOST_PORT=3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload
MAX_FILE_SIZE=10485760

# Docker
RESTART_POLICY=unless-stopped
TZ=Europe/Rome
```

### VARS Configuration (Both Interfaces)
```bash
# File: /etc/easy-rsa/vars

# Organization Information
EASYRSA_REQ_COUNTRY="IT"
EASYRSA_REQ_PROVINCE="Tuscany" 
EASYRSA_REQ_CITY="Prato"
EASYRSA_REQ_ORG="MyOrganization"
EASYRSA_REQ_EMAIL="admin@example.com"
EASYRSA_REQ_OU="IT Department"

# Expiration Settings (in days)
EASYRSA_CA_EXPIRE=3650        # CA: 10 years
EASYRSA_CERT_EXPIRE=365       # Certificates: 1 year

# Security Settings
EASYRSA_KEY_SIZE=2048         # Key size (2048/4096)
EASYRSA_DIGEST="sha256"       # Hash algorithm
```

---

## 📊 Architecture

### Web Application Architecture
```
Frontend (React 18)
├── Dashboard & Analytics
├── Certificate Management UI  
├── CSR Processing Interface
└── Authentication System

Backend (Node.js/Express)
├── RESTful API Endpoints
├── JWT Authentication
├── File Upload Handling
└── CLI Script Integration

Docker Container
├── Multi-stage Build
├── Alpine Linux Base
├── Volume Persistence
└── Health Monitoring

PKI Integration
├── Easy-RSA Integration
├── Original cert-manager modules
└── OpenSSL Operations
```

### API Endpoints
```
Authentication:
POST /api/auth/login                    # User login

CA Management:
GET  /api/ca/status                     # CA status check
POST /api/ca/create                     # Create new CA
GET  /api/ca/download                   # Download CA certificate
GET  /api/ca/download-key               # Download CA private key

Certificates:
GET  /api/certificates                  # List all certificates
POST /api/certificates/server           # Generate server certificate
POST /api/certificates/client           # Generate client certificate  
POST /api/certificates/:name/renew      # Renew certificate
GET  /api/certificates/:name/download/:type # Download certificate files

CSR Processing:
POST /api/csr/upload                    # Upload and process CSR

System:
GET  /api/health                        # Health check endpoint
```

---

## 🔐 Security Features

### Command Line Security
- **Root Detection**: Automatic privilege verification
- **File Permissions**: Secure 600 permissions for private keys
- **Backup Strategy**: Automatic backup of existing files
- **Input Validation**: Safe parameter handling

### Web Application Security  
- **JWT Authentication**: Stateless secure tokens
- **Password Hashing**: bcrypt with salt rounds
- **Rate Limiting**: API abuse prevention
- **Input Sanitization**: Comprehensive validation
- **CORS Protection**: Cross-origin request control
- **Container Security**: Non-root user, read-only filesystem
- **Network Isolation**: Private Docker networks

---

## 🚀 Production Deployment

### SSL/HTTPS Setup (Web Application)
```bash
# Generate SSL certificates (using your CA!)
mkdir -p nginx/ssl
cp your-domain.crt nginx/ssl/
cp your-domain.key nginx/ssl/

# Enable reverse proxy with SSL
docker-compose --profile with-proxy up -d
```

### Backup Strategy
```bash
# Create backup script
cat > backup-cert-data.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)

# Backup CLI workspace
tar -czf "cli-backup-$DATE.tar.gz" /etc/easy-rsa

# Backup Docker volumes
docker run --rm -v cert-manager_cert-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/docker-backup-$DATE.tar.gz -C /data .

echo "Backups created: cli-backup-$DATE.tar.gz, docker-backup-$DATE.tar.gz"
EOF

chmod +x backup-cert-data.sh
```

### Monitoring
```bash
# CLI system check
cert-manager --check
make info

# Web application health
curl http://localhost:3000/api/health
docker-compose logs -f cert-manager-web

# Enable monitoring stack
docker-compose --profile monitoring up -d
```

---

## 🔧 Troubleshooting

### Common Issues

#### CLI Installation Issues
```bash
# Easy-RSA not found
sudo apt install easy-rsa     # Ubuntu/Debian
sudo yum install easy-rsa     # CentOS/RHEL

# Permission errors
sudo make install             # Use sudo for installation

# Workspace verification
make check                    # Verify workspace
cert-manager --check          # Test command
```

#### Web Application Issues
```bash
# Container won't start
docker-compose logs cert-manager-web

# Authentication fails  
docker-compose exec cert-manager-web env | grep ADMIN

# Certificates not persisting
docker inspect cert-manager-web | grep -A 10 Mounts

# API not responding
curl http://localhost:3000/api/health
```

### Reset Procedures
```bash
# CLI complete reset (DELETES ALL CERTIFICATES!)
sudo rm -rf /etc/easy-rsa
sudo make setup-workspace
cert-manager  # Recreate CA

# Web application reset
docker-compose down -v
docker-compose up -d
```

---

## 🛠️ Development

### Local Development Setup
```bash
# Install all dependencies
npm run install:all

# Start development mode
docker-compose -f docker-compose.yml -f docker-compose.override.yml up

# Or run locally
cd web-interface
npm run dev
```

### Testing
```bash
# CLI system test
make test

# Web application tests
cd web-interface
npm test

# API testing
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your-password"}' | jq -r .token)

curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/ca/status
```

---

## 📦 Docker Commands Reference

### Basic Operations
```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f cert-manager-web

# Stop services
docker-compose down

# Complete cleanup with volumes
docker-compose down -v --remove-orphans
```

### Maintenance
```bash
# Update containers
docker-compose pull
docker-compose up -d

# Execute commands in container
docker-compose exec cert-manager-web bash

# Backup Docker volumes
docker run --rm -v cert-manager_cert-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/cert-data-backup.tar.gz -C /data .
```

---

## 🎯 Use Cases & Examples

### Home Lab Setup (CLI)
```bash
sudo make install
cert-manager
# Option 2: Configure organization
# Option 3: Create CA
# Option 4: Generate server cert for home.local
```

### Enterprise Web Interface
```bash
# Production deployment with SSL
cp production.env .env
docker-compose --profile with-proxy up -d
# Access via https://cert-manager.company.com
```

### Development Environment
```bash
# Quick development CA
docker-compose up -d
# Login via web: http://localhost:3000
# Create CA, generate dev certificates
```

---

## 🤝 Contributing

### Development Workflow
1. Fork repository
2. Create feature branch  
3. Test both CLI and web interfaces
4. Submit pull request

### Code Standards
- **ESLint**: Code linting
- **Prettier**: Code formatting
- **Conventional Commits**: Commit messages
- **Docker**: All features must work in containers

---

## 📄 License

This project is licensed under the MIT License - open source for hobby and educational use.

---

## 🆘 Support & Documentation

### Quick Help
```bash
# CLI help
cert-manager --help
make help

# Web application 
curl http://localhost:3000/api/health
docker-compose logs cert-manager-web
```

### Resources
- **Easy-RSA Documentation**: https://easy-rsa.readthedocs.io/
- **Docker Documentation**: https://docs.docker.com/
- **OpenSSL Documentation**: https://www.openssl.org/docs/

### Community
- **Issues**: Bug reports and feature requests
- **Discussions**: Questions and community support
- **Pull Requests**: Code contributions

---

**Certificate Manager v1.0 - Dual Distribution PKI System**  
*🖥️ CLI Ready • 🌐 Web Ready • 🐳 Container Ready • 🔒 Security First*