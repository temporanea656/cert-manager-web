# Certificate Manager - Windows Sync Script
# This script synchronizes certificates from the Docker container to the local Windows folder

Write-Host "Certificate Manager - Windows Sync Tool" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

$containerName = "cert-manager-web"

# Check if container is running
Write-Host "Checking container status..." -ForegroundColor Yellow
$containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}"

if (-not $containerStatus) {
    Write-Host "Error: Container '$containerName' is not running!" -ForegroundColor Red
    Write-Host "Start it with: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "Container is running: $containerStatus" -ForegroundColor Green

# Sync CA certificate
Write-Host "`nSyncing CA certificate..." -ForegroundColor Yellow
$caExists = docker exec $containerName test -f "/etc/easy-rsa/pki/ca.crt" 2>$null
if ($LASTEXITCODE -eq 0) {
    docker cp ${containerName}:/etc/easy-rsa/pki/ca.crt certificates/ca.crt
    Write-Host "✓ CA certificate synced" -ForegroundColor Green
} else {
    Write-Host "! No CA certificate found" -ForegroundColor Yellow
}

# Sync all certificates
Write-Host "`nSyncing certificates..." -ForegroundColor Yellow

# Create directories
New-Item -ItemType Directory -Path "certificates\server" -Force | Out-Null
New-Item -ItemType Directory -Path "certificates\client" -Force | Out-Null

# Copy all issued certificates
$certsExist = docker exec $containerName test -d "/etc/easy-rsa/pki/issued" 2>$null
if ($LASTEXITCODE -eq 0) {
    docker cp ${containerName}:/etc/easy-rsa/pki/issued/. certificates/server/
    Write-Host "✓ All certificates synced to certificates/server/" -ForegroundColor Green
} else {
    Write-Host "! No certificates directory found" -ForegroundColor Yellow
}

# Show summary
Write-Host "`nSync Summary:" -ForegroundColor Cyan
$caFile = Test-Path "certificates\ca.crt"
$serverFiles = Get-ChildItem "certificates\server\*.crt" 2>$null
$serverCount = if ($serverFiles) { $serverFiles.Count } else { 0 }

Write-Host "CA Certificate: $(if ($caFile) { 'Present' } else { 'Missing' })" -ForegroundColor $(if ($caFile) { 'Green' } else { 'Red' })
Write-Host "Server Certificates: $serverCount" -ForegroundColor $(if ($serverCount -gt 0) { 'Green' } else { 'Yellow' })

if ($serverCount -gt 0) {
    Write-Host "`nAvailable certificates:" -ForegroundColor White
    $serverFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
}

Write-Host "`nCertificates are available in the 'certificates' folder" -ForegroundColor Green
Write-Host "Run this script again after creating new certificates to sync them" -ForegroundColor Yellow