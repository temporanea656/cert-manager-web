# Certificate Manager Web Interface

Modern web interface for the Certificate Manager PKI system. Provides a secure, user-friendly way to manage Certificate Authority operations, generate certificates, and monitor PKI infrastructure through a responsive web dashboard.

## 🚀 Features

### Web Dashboard
- **Real-time PKI Overview**: Live status of CA and certificates
- **Interactive Charts**: Visual representation of certificate types and expiration status
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Dark/Light Theme**: User preference support

### Certificate Management
- **CA Operations**: Create and manage Certificate Authority
- **Server Certificates**: Generate certificates with Subject Alternative Names (SAN)
- **Client Certificates**: User and device certificates
- **CSR Processing**: Upload and sign external certificate requests
- **Batch Operations**: Multiple certificate management

### Security Features
- **JWT Authentication**: Secure token-based authentication
- **Role-based Access**: Admin and operator roles
- **Rate Limiting**: API protection against abuse
- **Input Validation**: Comprehensive security validation
- **Audit Logging**: Complete operation tracking

### Docker Integration
- **Container Ready**: Full Docker support with multi-stage builds
- **Volume Persistence**: Certificate data persistence
- **Health Checks**: Built-in health monitoring
- **Reverse Proxy Ready**: Nginx integration for HTTPS

## 📋 Prerequisites

### For Docker Deployment (Recommended)
- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

### For Manual Deployment
- Node.js 18+
- Easy-RSA 3.x
- OpenSSL
- Linux/Unix environment

## 🔧 Quick Start with Docker

### 1. Clone and Setup
```bash
git clone <repository-url> cert-manager-web
cd cert-manager-web
```

### 2. Configure Environment
```bash
# Copy and edit environment file
cp .env.example .env

# Edit configuration
nano .env
```

**Important Environment Variables:**
```env
# Security (CHANGE THESE!)
JWT_SECRET=your-super-secret-jwt-key
ADMIN_USER=admin
ADMIN_PASS=your-secure-password

# Server
PORT=3000
NODE_ENV=production

# Docker
HOST_PORT=3000
RESTART_POLICY=unless-stopped
```

### 3. Deploy with Docker Compose
```bash
# Create volume directories
mkdir -p volumes/{cert-data,logs}

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### 4. Access Web Interface
Open browser to: `http://localhost:3000`

**Default Credentials:**
- Username: `admin`
- Password: `change-this-password` (change in `.env`)

## 🏗️ Architecture

### Container Structure
```
cert-manager-web/
├── 📦 Frontend (React 18)
│   ├── Dashboard & Analytics
│   ├── Certificate Management
│   ├── CSR Processing
│   └── User Authentication
├── 🔧 Backend (Node.js/Express)
│   ├── RESTful API
│   ├── JWT Authentication
│   ├── File Upload Handling
│   └── Script Integration
├── 📜 Original Scripts
│   ├── cert-manager modules
│   ├── Easy-RSA integration
│   └── PKI operations
└── 🐳 Docker Infrastructure
    ├── Multi-stage builds
    ├── Volume persistence
    └── Health monitoring
```

### API Endpoints
```
Authentication:
POST /api/auth/login        # User login

CA Management:
GET  /api/ca/status         # CA status check
POST /api/ca/create         # Create new CA

Certificates:
GET  /api/certificates                    # List all certificates
POST /api/certificates/server            # Generate server cert
POST /api/certificates/client            # Generate client cert
POST /api/certificates/:name/renew       # Renew certificate
GET  /api/certificates/:name/download/:type  # Download cert files

CSR Processing:
POST /api/csr/upload        # Upload and process CSR

System:
GET  /api/health           # Health check
```

## 🔐 Security

### Authentication & Authorization
- **JWT Tokens**: Secure, stateless authentication
- **Password Hashing**: bcrypt with salt rounds
- **Session Management**: Secure token refresh
- **Role-based Access**: Granular permission control

### API Security
- **Rate Limiting**: Prevents API abuse
- **Input Validation**: Comprehensive sanitization
- **CORS Protection**: Cross-origin request control
- **Helmet.js**: Security headers protection

### Container Security
- **Non-root User**: Containers run as unprivileged user
- **Read-only Filesystem**: Immutable container layers
- **Secrets Management**: Environment-based configuration
- **Network Isolation**: Private Docker networks

## 📊 Monitoring & Logging

### Health Checks
```bash
# Container health
docker-compose ps

# Application health
curl http://localhost:3000/api/health

# Detailed status
docker-compose logs cert-manager-web
```

### Log Files
```bash
# Application logs
docker-compose logs -f cert-manager-web

# Access logs (with nginx proxy)
docker-compose logs -f nginx-proxy

# System logs
docker-compose exec cert-manager-web cat /var/log/cert-manager.log
```

## 🔄 Production Deployment

### 1. SSL/HTTPS Setup
```bash
# Generate certificates (using your own CA!)
mkdir -p nginx/ssl

# Copy SSL certificates
cp your-domain.crt nginx/ssl/
cp your-domain.key nginx/ssl/

# Enable reverse proxy
docker-compose --profile with-proxy up -d
```

### 2. Backup Strategy
```bash
# Create backup script
cat > backup-cert-data.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "cert-backup-$DATE.tar.gz" -C volumes cert-data
echo "Backup created: cert-backup-$DATE.tar.gz"
EOF

chmod +x backup-cert-data.sh

# Schedule with cron
crontab -e
# Add: 0 2 * * * /path/to/backup-cert-data.sh
```

### 3. Monitoring Setup
```bash
# Enable monitoring stack
docker-compose --profile monitoring up -d

# View aggregated logs
docker-compose logs log-aggregator
```

## 🛠️ Development

### Local Development Setup
```bash
# Install dependencies
npm run install:all

# Start development mode
docker-compose -f docker-compose.yml -f docker-compose.override.yml up

# Or run locally
npm run dev
```

### Development Features
- **Hot Reload**: Auto-restart on code changes
- **Debug Mode**: Node.js debugger on port 9229
- **Development Database**: PostgreSQL for user management
- **Development Tools**: Interactive container shell

### Testing
```bash
# Run tests
npm test

# API testing with curl
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your-password"}'
```

## 📦 Docker Commands Reference

### Basic Operations
```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Complete cleanup
docker-compose down -v --remove-orphans
```

### Maintenance
```bash
# Update containers
docker-compose pull
docker-compose up -d

# Restart single service
docker-compose restart cert-manager-web

# Execute commands in container
docker-compose exec cert-manager-web bash
```

### Backup & Restore
```bash
# Backup volumes
docker run --rm -v cert-manager-web_cert-data:/data -v $(pwd):/backup alpine tar czf /backup/cert-data-backup.tar.gz -C /data .

# Restore volumes
docker run --rm -v cert-manager-web_cert-data:/data -v $(pwd):/backup alpine tar xzf /backup/cert-data-backup.tar.gz -C /data
```

## 🚀 Deployment Options

### Option 1: Single Container (Simple)
```bash
docker run -d \
  --name cert-manager-web \
  -p 3000:3000 \
  -v cert-data:/etc/easy-rsa \
  -e JWT_SECRET=your-secret \
  -e ADMIN_USER=admin \
  -e ADMIN_PASS=your-password \
  cert-manager-web:latest
```

### Option 2: Docker Compose (Recommended)
```bash
docker-compose up -d
```

### Option 3: Docker Swarm (Clustering)
```bash
docker stack deploy -c docker-compose.yml cert-manager-stack
```

### Option 4: Kubernetes (Enterprise)
```bash
# Convert to Kubernetes manifests
kompose convert

# Deploy to Kubernetes
kubectl apply -f .
```

## 🔧 Troubleshooting

### Common Issues

**1. Container won't start**
```bash
# Check logs
docker-compose logs cert-manager-web

# Check file permissions
ls -la volumes/
```

**2. Authentication fails**
```bash
# Verify environment variables
docker-compose exec cert-manager-web env | grep ADMIN

# Reset admin password
docker-compose exec cert-manager-web node -e "
const bcrypt = require('bcryptjs');
console.log('New hash:', bcrypt.hashSync('newpassword', 12));
"
```

**3. Certificates not persisting**
```bash
# Check volume mounts
docker inspect cert-manager-web | grep -A 10 Mounts

# Verify permissions
docker-compose exec cert-manager-web ls -la /etc/easy-rsa
```

**4. API not responding**
```bash
# Test health endpoint
curl http://localhost:3000/api/health

# Check port binding
netstat -tulpn | grep 3000
```

### Performance Tuning
```bash
# Increase memory limits
# Edit docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 1G
    reservations:
      memory: 512M
```

## 📖 API Documentation

### Authentication
All API endpoints (except `/api/auth/login` and `/api/health`) require JWT authentication:

```bash
# Get token
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your-password"}' | jq -r .token)

# Use token
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/ca/status
```

### Examples

**Create CA:**
```bash
curl -X POST http://localhost:3000/api/ca/create \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "country": "IT",
    "province": "Tuscany", 
    "city": "Prato",
    "org": "MyOrganization",
    "email": "admin@example.com"
  }'
```

**Generate Server Certificate:**
```bash
curl -X POST http://localhost:3000/api/certificates/server \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server",
    "ip": "192.168.1.100",
    "dns": "example.com"
  }'
```

## 🤝 Contributing

### Development Workflow
1. Fork repository
2. Create feature branch
3. Make changes
4. Test locally with Docker
5. Submit pull request

### Code Standards
- **ESLint**: Code linting
- **Prettier**: Code formatting  
- **Jest**: Testing framework
- **Conventional Commits**: Commit messages

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Documentation
- [Original cert-manager README](../README.md)
- [Easy-RSA Documentation](https://easy-rsa.readthedocs.io/)
- [Docker Documentation](https://docs.docker.com/)

### Issues & Bugs
- Check existing issues first
- Provide full error logs
- Include environment details
- Use issue templates

### Community
- Discussions for questions
- Issues for bugs
- Pull requests for contributions

---

**Certificate Manager Web Interface v1.0**  
*Secure • Scalable • Docker-Ready*