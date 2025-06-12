#!/bin/bash

# Simple EpiBus Deployment Script
# Deploys Frappe + ERPNext + EpiBus only

set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

log "Starting EpiBus deployment (Frappe + ERPNext + EpiBus)"

# Check directory
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"

# Complete cleanup
log "Complete cleanup"
docker compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -af --volumes >/dev/null 2>&1

# Create .env for custom image
log "Creating .env for EpiBus"
cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
CUSTOM_IMAGE=frappe-epibus
CUSTOM_TAG=latest
PULL_POLICY=never
EOF

# Build EpiBus image
log "Building EpiBus custom image (this may take a few minutes)"
if ! ./development/build-epibus-image.sh; then
    error "EpiBus image build failed"
fi

# Create deployment compose file (based on pwd.yml but with EpiBus)
log "Creating deployment compose file"
cp pwd.yml deploy-epibus.yml

# Update the compose file to use custom image and install EpiBus
sed -i.bak 's|frappe/erpnext:v15.64.1|${CUSTOM_IMAGE:-frappe/erpnext}:${CUSTOM_TAG:-v15.64.1}|g' deploy-epibus.yml
sed -i.bak 's|--install-app erpnext|--install-app erpnext --install-app epibus|g' deploy-epibus.yml
rm -f deploy-epibus.yml.bak

# Deploy
log "Starting deployment"
docker compose -f deploy-epibus.yml up -d

# Wait for site creation to complete
log "Waiting for site creation to complete"
for i in {1..600}; do
    if docker compose -f deploy-epibus.yml ps create-site 2>/dev/null | grep -q "Exited (0)"; then
        log "Site creation completed"
        break
    fi
    
    # Show progress every 30 seconds
    if [ $((i % 30)) -eq 0 ]; then
        STATUS=$(docker compose -f deploy-epibus.yml logs create-site 2>/dev/null | tail -3 | head -1 || echo "Installing...")
        log "Progress: $STATUS"
    fi
    
    sleep 1
    if [ $i -eq 600 ]; then 
        log "Site creation taking longer than expected, checking status..."
        docker compose -f deploy-epibus.yml logs create-site | tail -10
        break
    fi
done

# Get port and test
PORT=$(docker compose -f deploy-epibus.yml port frontend 8080 2>/dev/null | cut -d: -f2 || echo "8080")

# Test deployment
log "Testing deployment"
sleep 10
if curl -f -s "http://localhost:$PORT" >/dev/null 2>&1; then
    # Test CSS to ensure it's working
    CSS_URL=$(curl -s "http://localhost:$PORT" | grep -o '/assets/frappe/dist/css/website\.bundle\.[^"]*\.css' | head -1)
    if [ -n "$CSS_URL" ] && curl -f -s "http://localhost:$PORT$CSS_URL" >/dev/null 2>&1; then
        CSS_STATUS="✅ Working"
    else
        CSS_STATUS="⚠️  Issues detected"
    fi
    
    log "SUCCESS! EpiBus deployment completed"
    echo "=================================="
    echo "Access: http://localhost:$PORT"
    echo "Login: Administrator / admin"
    echo "Apps: Frappe + ERPNext + EpiBus"
    echo "CSS Status: $CSS_STATUS"
    echo "=================================="
    
    # Check what apps are actually installed
    log "Verifying installed apps:"
    sleep 5
    docker compose -f deploy-epibus.yml exec backend bench --site frontend list-apps || echo "Will be available once fully started"
    
else
    log "Frontend not responding yet. Check http://localhost:$PORT in a moment."
    echo "Logs from create-site:"
    docker compose -f deploy-epibus.yml logs create-site | tail -10
fi

# Show service status
log "Service status:"
docker compose -f deploy-epibus.yml ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"

# Cleanup
rm -f deploy-epibus.yml

log "EpiBus deployment script completed"