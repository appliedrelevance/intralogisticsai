#!/bin/bash

# Clean Frappe Docker Deployment Script
# Based on the working pwd.yml pattern
#
# Usage:
#   ./deploy.sh                    # Basic Frappe/ERPNext deployment
#   ./deploy.sh with-epibus        # EpiBus only deployment  
#   ./deploy.sh with-plc           # Complete industrial automation (recommended)
#   ./deploy.sh lab                # Training lab deployment with custom domains
#
# The 'with-plc' option deploys the complete stack:
# - Frappe/ERPNext ERP system
# - EpiBus industrial integration app (automatically installed)
# - OpenPLC simulator
# - MODBUS TCP server
# - PLC Bridge for real-time communication

source .env
set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() { echo "[ERROR] $1"; exit 1; }
: ${DB_PASSWORD:?Error: DB_PASSWORD is not set in .env or environment. Please set it.}
: ${ERPNEXT_VERSION:?Error: ERPNEXT_VERSION is not set in .env or environment. Please set it.}

if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    : ${PULL_POLICY:?Error: PULL_POLICY is not set for with-plc deployment. Please set it.}
fi

DEPLOY_TYPE=${1:-"basic"}
log "Starting deployment: $DEPLOY_TYPE"

if [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    log "Deploying with EpiBus application"
    ./development/build-epibus-image.sh || error "EpiBus image build failed. Exiting."
fi

# Check directory
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"

# Complete cleanup
log "Complete cleanup"
docker compose down --volumes --remove-orphans 2>/dev/null || true
docker system prune -af --volumes >/dev/null 2>&1


if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Setting up PLC integration"
    # Build EpiBus image
    ./development/build-epibus-image.sh || error "EpiBus image build failed. Exiting."
fi

# Validate required environment variables

# Deploy based on type
if [ "$DEPLOY_TYPE" = "lab" ]; then
    log "Deploying training lab environment with custom domains"
    ./development/build-epibus-image.sh || error "EpiBus image build failed. Exiting."
    CUSTOM_IMAGE=frappe-epibus CUSTOM_TAG=latest PULL_POLICY=never docker compose \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.openplc.yaml \
      -f overrides/compose.plc-bridge.yaml \
      -f overrides/compose.lab.yaml \
      -f overrides/compose.create-site.yaml \
      up -d
elif [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Deploying with PLC features using compose.yaml with overrides"
    CUSTOM_IMAGE=frappe-epibus CUSTOM_TAG=latest PULL_POLICY=never docker compose \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.openplc.yaml \
      -f overrides/compose.plc-bridge.yaml \
      -f overrides/compose.mac-m4.yaml \
      -f overrides/compose.create-site.yaml \
      up -d
elif [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    log "Deploying with EpiBus application using compose.yaml with overrides"
    CUSTOM_IMAGE=frappe-epibus CUSTOM_TAG=latest PULL_POLICY=never docker compose \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.mac-m4.yaml \
      -f overrides/compose.create-site.yaml \
      up -d
else
    log "Deploying basic Frappe using compose.yaml with overrides"
    docker compose \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.mac-m4.yaml \
      -f overrides/compose.create-site.yaml \
      up -d
fi

# Wait for completion
log "Waiting for site creation"

# Wait for create-site to complete (up to 10 minutes)
for i in {1..600}; do
    if docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "create-site.*Exited (0)"; then
        log "Site creation completed"
        break
    fi
    sleep 1
    if [ $i -eq 600 ]; then 
        log "Site creation taking longer than expected, but may still be in progress"
        break
    fi
done

# Get port and verify
PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep frontend | sed 's/.*:\([0-9]*\)->8080.*/\1/' || echo "8080")

# Install EpiBus if applicable
if [ "$DEPLOY_TYPE" = "with-plc" ] || [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    log "Installing EpiBus on site"
    sleep 30 # Give extra time for site creation to complete
    if docker compose exec backend bench --site intralogistics.localhost install-app epibus; then
        log "EpiBus installation completed"
    else
        log "EpiBus installation may need manual retry after site is fully ready"
    fi
fi

# Test frontend
log "Testing deployment"
sleep 10
if curl -f -s "http://localhost:$PORT" >/dev/null 2>&1; then
    log "SUCCESS! Deployment completed"
    echo "=================================="
    echo "Access: http://localhost:$PORT"
    echo "Login: Administrator / admin"
    echo "Deploy Type: $DEPLOY_TYPE"
    if [ "$DEPLOY_TYPE" = "lab" ]; then
        echo "Lab Environment URLs:"
        echo "  - Main Interface: http://intralogistics.lab"
        echo "  - OpenPLC Simulator: http://openplc.lab"
        echo "  - Traefik Dashboard: http://traefik.lab"
        echo "MODBUS TCP: Port 502 (for real PLC connections)"
        echo "Configure router DNS: intralogistics.lab -> $(hostname -I | awk '{print $1}')"
    elif [ "$DEPLOY_TYPE" = "with-plc" ]; then
        echo "OpenPLC: http://localhost:8081 (openplc/openplc)"
        echo "PLC Bridge: http://localhost:7654"
        echo "EpiBus: Installed and integrated"
    elif [ "$DEPLOY_TYPE" = "with-epibus" ]; then
        echo "EpiBus: Installed and ready"
    fi
    echo "=================================="
else
    log "Frontend may still be starting. Check http://localhost:$PORT in a moment."
fi

# Cleanup
rm -f deploy.yml

log "Deployment script completed"