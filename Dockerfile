# Multi-stage build for production optimization
FROM node:18-alpine AS frontend-builder

# Set working directory for frontend build
WORKDIR /app/frontend

# Copy frontend package files
COPY web-interface/frontend/package*.json ./

# Install frontend dependencies
RUN npm install --only=production

# Copy frontend source code
COPY web-interface/frontend/ ./

# Build frontend for production
RUN npm run build

# Production image
FROM node:18-alpine AS production

# Install system dependencies for PKI operations
RUN apk add --no-cache \
    easy-rsa \
    openssl \
    bash \
    curl \
    shadow \
    sudo \
    tzdata && \
    # Create app user
    addgroup -g 1001 -S certmanager && \
    adduser -S certmanager -u 1001 -G certmanager && \
    # Give certmanager user sudo access for PKI operations
    echo 'certmanager ALL=(ALL) NOPASSWD: /usr/share/easy-rsa/easyrsa, /bin/mkdir, /bin/chown, /bin/chmod' >> /etc/sudoers

# Set timezone
ENV TZ=Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set working directory
WORKDIR /app

# Copy package files
COPY web-interface/package*.json ./

# Install production dependencies only
RUN npm install --only=production && npm cache clean --force

# Copy backend source code
COPY web-interface/server.js ./
COPY web-interface/hash-password.js ./
COPY web-interface/.env.example ./.env

# Copy built frontend from builder stage
COPY --from=frontend-builder /app/frontend/build ./frontend/build

# Copy original cert-manager scripts
COPY cert-manager /opt/cert-manager/
COPY modules/ /opt/cert-manager/modules/
COPY easyrsa /opt/cert-manager/templates/
COPY openssl-easyrsa.cnf /opt/cert-manager/templates/
COPY vars /opt/cert-manager/templates/

# Create cert-manager API wrapper script
RUN cat > /opt/cert-manager/cert-manager-api << 'EOF'
#!/bin/bash

# API wrapper for cert-manager commands
# This script provides a secure interface between the web API and cert-manager modules

set -euo pipefail

EASYRSA_DIR="/etc/easy-rsa"
MODULE_DIR="/opt/cert-manager/modules"

# Ensure Easy-RSA directory exists
mkdir -p "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# Source color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

case "${1:-}" in
  check-ca)
    source "$MODULE_DIR/verificaCA.sh"
    check_ca_files
    ;;
  create-ca)
    if [ $# -lt 6 ]; then
      echo "Usage: $0 create-ca COUNTRY PROVINCE CITY ORG EMAIL [OU]"
      exit 1
    fi
    # Set up vars file with provided parameters
    cat > "$EASYRSA_DIR/vars" << EOF_VARS
set_var EASYRSA_REQ_COUNTRY     "$2"
set_var EASYRSA_REQ_PROVINCE    "$3"
set_var EASYRSA_REQ_CITY        "$4"
set_var EASYRSA_REQ_ORG         "$5"
set_var EASYRSA_REQ_EMAIL       "$6"
set_var EASYRSA_REQ_OU          "${7:-IT Department}"
set_var EASYRSA_KEY_SIZE        2048
set_var EASYRSA_CA_EXPIRE       3650
set_var EASYRSA_CERT_EXPIRE     365
set_var EASYRSA_DIGEST          "sha256"
EOF_VARS
    # Create CA automatically (non-interactive)
    echo "Creating CA automatically..."
    cd "$EASYRSA_DIR"
    
    # Clean existing PKI
    if [ -d "pki" ]; then
      rm -rf pki
      echo "Removed existing PKI directory"
    fi
    
    # Initialize PKI
    echo "Initializing PKI..."
    ./easyrsa init-pki
    
    # Create CA without password (batch mode)
    echo "Creating CA certificate..."
    echo "" | ./easyrsa --batch build-ca nopass
    
    if [ -f "pki/ca.crt" ] && [ -f "pki/private/ca.key" ]; then
      echo "CA created successfully!"
      echo "CA certificate: pki/ca.crt"
      echo "CA private key: pki/private/ca.key"
      
      # Copy CA to export directory
      mkdir -p /data/certificates
      cp pki/ca.crt /data/certificates/ca.crt
      echo "CA copied to export directory"
    else
      echo "Error: CA creation failed"
      exit 1
    fi
    ;;
  create-server)
    if [ $# -lt 2 ]; then
      echo "Usage: $0 create-server NAME [IP] [DNS]"
      exit 1
    fi
    # Create server certificate automatically (non-interactive)
    echo "Creating server certificate: $2"
    cd "$EASYRSA_DIR"
    
    if [ ! -f "pki/ca.crt" ]; then
      echo "Error: CA not found. Please create a CA first."
      exit 1
    fi
    
    # Generate server certificate request
    echo "Generating certificate request for $2..."
    echo "" | ./easyrsa --batch gen-req "$2" nopass
    
    # Sign the server certificate
    echo "Signing server certificate..."
    echo "yes" | ./easyrsa --batch sign-req server "$2"
    
    if [ -f "pki/issued/$2.crt" ]; then
      echo "Server certificate created successfully!"
      echo "Certificate: pki/issued/$2.crt"
      echo "Private key: pki/private/$2.key"
      
      # Copy certificate to export directory
      mkdir -p /data/certificates/server
      cp "pki/issued/$2.crt" "/data/certificates/server/$2.crt"
      # Copy private key (optional, for security reasons)
      # cp "pki/private/$2.key" "/data/certificates/server/$2.key"
      echo "Certificate copied to export directory"
    else
      echo "Error: Server certificate creation failed"
      exit 1
    fi
    ;;
  create-client)
    if [ $# -lt 2 ]; then
      echo "Usage: $0 create-client NAME [EMAIL]"
      exit 1
    fi
    # Create client certificate automatically (non-interactive)
    echo "Creating client certificate: $2"
    cd "$EASYRSA_DIR"
    
    if [ ! -f "pki/ca.crt" ]; then
      echo "Error: CA not found. Please create a CA first."
      exit 1
    fi
    
    # Generate client certificate request
    echo "Generating certificate request for $2..."
    echo "" | ./easyrsa --batch gen-req "$2" nopass
    
    # Sign the client certificate
    echo "Signing client certificate..."
    echo "yes" | ./easyrsa --batch sign-req client "$2"
    
    if [ -f "pki/issued/$2.crt" ]; then
      echo "Client certificate created successfully!"
      echo "Certificate: pki/issued/$2.crt"
      echo "Private key: pki/private/$2.key"
      
      # Copy certificate to export directory
      mkdir -p /data/certificates/client
      cp "pki/issued/$2.crt" "/data/certificates/client/$2.crt"
      echo "Certificate copied to export directory"
    else
      echo "Error: Client certificate creation failed"
      exit 1
    fi
    ;;
  list-certificates)
    echo "Listing certificates..."
    cd "$EASYRSA_DIR"
    
    if [ ! -d "pki/issued" ]; then
      echo "No certificates found."
      exit 0
    fi
    
    echo "Issued certificates:"
    for cert in pki/issued/*.crt; do
      if [ -f "$cert" ]; then
        basename "$cert" .crt
      fi
    done
    ;;
  process-csr)
    if [ $# -lt 3 ]; then
      echo "Usage: $0 process-csr FILENAME TYPE"
      exit 1
    fi
    source "$MODULE_DIR/firmaCSR.sh"
    process_pending_requests
    ;;
  renew-certificate)
    if [ $# -lt 2 ]; then
      echo "Usage: $0 renew-certificate NAME"
      exit 1
    fi
    source "$MODULE_DIR/rinnovoCERTIFICATI.sh"
    renew_certificates
    ;;
  *)
    echo "Usage: $0 {check-ca|create-ca|create-server|create-client|list-certificates|process-csr|renew-certificate}"
    exit 1
    ;;
esac
EOF

# Make scripts executable
RUN chmod +x /opt/cert-manager/cert-manager-api && \
    chmod +x /opt/cert-manager/cert-manager && \
    find /opt/cert-manager/modules -name "*.sh" -exec chmod +x {} \;

# Set up Easy-RSA workspace
RUN mkdir -p /etc/easy-rsa && \
    ln -sf /usr/share/easy-rsa/easyrsa /etc/easy-rsa/easyrsa && \
    cp /opt/cert-manager/templates/openssl-easyrsa.cnf /etc/easy-rsa/ && \
    cp /opt/cert-manager/templates/vars /etc/easy-rsa/ && \
    mkdir -p /etc/easy-rsa/{client,server,pending-requests,signed-certificates,processed-requests} && \
    chown -R certmanager:certmanager /etc/easy-rsa /opt/cert-manager

# Create volume mount points
RUN mkdir -p /data/easy-rsa /data/logs && \
    chown -R certmanager:certmanager /data

# Switch to non-root user
USER certmanager

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV JWT_SECRET=change-this-in-production
ENV ADMIN_USER=admin
ENV ADMIN_PASS=change-this-password

# Start command
CMD ["node", "server.js"]