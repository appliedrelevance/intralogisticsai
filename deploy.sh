#!/bin/bash

# Clean Frappe Docker Deployment Script
# Based on the working pwd.yml pattern

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
if [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Deploying with PLC features using compose.yaml with overrides"
    CUSTOM_IMAGE=frappe-epibus CUSTOM_TAG=latest docker compose \
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
    CUSTOM_IMAGE=frappe-epibus CUSTOM_TAG=latest docker compose \
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
COMPOSE_FILE="compose.yaml" # Always use compose.yaml for the base, overrides will be added

# Wait for create-site to complete (up to 10 minutes)
for i in {1..600}; do
    if docker compose -f "$COMPOSE_FILE" ps create-site 2>/dev/null | grep -q "Exited (0)"; then
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
PORT=$(docker compose -f "$COMPOSE_FILE" port frontend 8080 2>/dev/null | cut -d: -f2 || echo "8080")

# Test frontend
log "Testing deployment"
sleep 10
if curl -f -s "http://localhost:$PORT" >/dev/null 2>&1; then
    log "SUCCESS! Deployment completed"
    echo "=================================="
    echo "Access: http://localhost:$PORT"
    echo "Login: Administrator / admin"
    echo "Deploy Type: $DEPLOY_TYPE"
    if [ "$DEPLOY_TYPE" = "with-plc" ]; then
        echo "OpenPLC: http://localhost:8081 (openplc/openplc)"
        echo "PLC Bridge: http://localhost:7654"
    elif [ "$DEPLOY_TYPE" = "with-epibus" ]; then
        echo "EpiBus application deployed."
    fi
    echo "=================================="
else
    log "Frontend may still be starting. Check http://localhost:$PORT in a moment."
fi

# Cleanup
rm -f deploy.yml

log "Deployment script completed"