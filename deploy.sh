#!/bin/bash

# Simple Frappe Docker Deployment Script
# Clean deployment from scratch every time

set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

DEPLOY_TYPE=${1:-"standard"}
log "Starting deployment: $DEPLOY_TYPE"

# Check directory
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"

# Complete cleanup - everything must go
log "Complete cleanup"
docker compose down --volumes 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker system prune -af --volumes >/dev/null 2>&1
docker volume prune -f >/dev/null 2>&1

# Fresh .env
log "Creating fresh .env"
rm -f .env .env.bak
cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
FRAPPE_SITE_NAME_HEADER=localhost
EOF

# Add custom image settings for EpiBus
if [ "$DEPLOY_TYPE" = "epibus" ]; then
    log "Building EpiBus image"
    cat >> .env << EOF
CUSTOM_IMAGE=frappe-epibus
CUSTOM_TAG=latest
PULL_POLICY=never
EOF
    ./development/build-epibus-image.sh
fi

# Deploy
log "Deploying stack"
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml up -d

# Wait for database
log "Waiting for database"
for i in {1..30}; do
    if docker compose exec db mysql -u root -p123 -e "SELECT 1" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Create site
log "Creating site"
if [ "$DEPLOY_TYPE" = "epibus" ]; then
    docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext --install-app epibus
else
    docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext
fi

# Build assets
log "Building assets"
docker compose exec backend bench --site localhost build

# Restart frontend
log "Restarting frontend"
docker compose restart frontend
sleep 10

# Get port
PORT=$(docker compose port frontend 8080 2>/dev/null | cut -d: -f2 || echo "unknown")

log "SUCCESS!"
echo "=================================="
echo "Access: http://localhost:$PORT"
echo "Login: Administrator / admin"
echo "=================================="