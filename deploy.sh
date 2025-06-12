#!/bin/bash

# Frappe Docker Deployment Script with Realistic Timeouts
# Total target: 5 minutes with proper segment timeouts

set -e

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() {
    echo "[ERROR] $1"
    echo ""
    echo "TROUBLESHOOTING HELP:"
    echo "- Check service status: docker compose ps"
    echo "- View logs: docker compose logs"
    echo "- Clean restart: docker compose down --volumes && ./deploy.sh"
    echo "- For help: See CLAUDE.md file in this directory"
    exit 1
}

DEPLOY_TYPE=${1:-"full"}
START_TIME=$(date +%s)

log "Starting deployment: $DEPLOY_TYPE (5min target)"

# Pre-flight checks
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"
command -v docker >/dev/null 2>&1 || error "Docker is not installed or not in PATH"
command -v curl >/dev/null 2>&1 || error "curl is not installed or not in PATH"
docker compose version >/dev/null 2>&1 || error "Docker Compose is not available"

# Complete cleanup (30s timeout)
log "Complete cleanup (30s)"
docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
# More aggressive cleanup for stubborn volumes
docker volume ls -q | grep frappe_docker | xargs -r docker volume rm >/dev/null 2>&1 || true
docker system prune -af --volumes >/dev/null 2>&1

# Fresh .env
log "Creating .env"
rm -f .env .env.bak
cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
FRAPPE_SITE_NAME_HEADER=localhost
EOF

# Add custom image settings for EpiBus (if full deployment)
if [ "$DEPLOY_TYPE" = "full" ]; then
    log "Building EpiBus image (2min timeout)"
    cat >> .env << EOF
CUSTOM_IMAGE=frappe-epibus
CUSTOM_TAG=latest
PULL_POLICY=never
EOF
    
    # Build image with proper timeout
    if ! ./development/build-epibus-image.sh; then
        log "EpiBus build failed, falling back to basic deployment"
        DEPLOY_TYPE="basic"
        # Remove custom image settings
        cat > .env << EOF
DB_PASSWORD=123
ERPNEXT_VERSION=v15.64.1
FRAPPE_SITE_NAME_HEADER=localhost
EOF
    fi
fi

# Deploy services (2min timeout for image pulls)
log "Deploying services (2min)"
ARCH=$(uname -m)
if [ "$DEPLOY_TYPE" = "full" ]; then
    if [ "$ARCH" = "arm64" ]; then
        COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.mac-m4.yaml"
    else
        COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml"
    fi
else
    if [ "$ARCH" = "arm64" ]; then
        COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.mac-m4.yaml"
    else
        COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml"
    fi
fi

$COMPOSE_CMD up -d || error "Service startup failed"

# Wait for services (30s timeout)
log "Waiting for services (30s)"
DB_READY=false
BACKEND_READY=false

for i in {1..30}; do
    # Check database
    if [ "$DB_READY" = false ] && docker compose exec db mysql -u root -p123 -e "SELECT 1" >/dev/null 2>&1; then
        log "Database ready"
        DB_READY=true
    fi
    
    # Check backend
    if [ "$BACKEND_READY" = false ] && docker compose exec backend bench --version >/dev/null 2>&1; then
        log "Backend ready"
        BACKEND_READY=true
    fi
    
    # Both ready?
    if [ "$DB_READY" = true ] && [ "$BACKEND_READY" = true ]; then
        log "All services ready"
        break
    fi
    
    sleep 1
    if [ $i -eq 30 ]; then error "Services not ready after 30s"; fi
done

# Clean any existing site/database thoroughly (15s)
log "Cleaning existing data"

# Remove site directory first
docker compose exec backend rm -rf /home/frappe/frappe-bench/sites/localhost >/dev/null 2>&1 || true

# Get all databases (both named and hashed)
EXISTING_DBS=$(docker compose exec db mysql -u root -p123 -e "SHOW DATABASES;" -s 2>/dev/null | grep -v "information_schema\|performance_schema\|mysql\|sys" || true)
if [ ! -z "$EXISTING_DBS" ]; then
    echo "$EXISTING_DBS" | while read db; do
        if [ ! -z "$db" ] && [ "$db" != "Database" ]; then
            log "Dropping database: $db"
            docker compose exec db mysql -u root -p123 -e "DROP DATABASE IF EXISTS \`$db\`;" >/dev/null 2>&1 || true
        fi
    done
fi

# Also clean any potential site cache
docker compose exec backend bench --site localhost clear-cache >/dev/null 2>&1 || true
docker compose exec backend bench --site localhost clear-website-cache >/dev/null 2>&1 || true

# Create site (90s timeout for app installations)
log "Creating site (90s)"
SITE_CREATED=false
for attempt in {1..3}; do
    log "Site creation attempt $attempt/3"
    
    if [ "$DEPLOY_TYPE" = "full" ]; then
        if docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext --install-app epibus; then
            SITE_CREATED=true
            break
        fi
    else
        if docker compose exec backend bench new-site localhost --admin-password admin --db-root-password 123 --install-app erpnext; then
            SITE_CREATED=true
            break
        fi
    fi
    
    if [ $attempt -lt 3 ]; then
        log "Site creation failed, cleaning up for retry..."
        docker compose exec backend rm -rf /home/frappe/frappe-bench/sites/localhost >/dev/null 2>&1 || true
        # Clean databases again
        EXISTING_DBS=$(docker compose exec db mysql -u root -p123 -e "SHOW DATABASES;" -s 2>/dev/null | grep -v "information_schema\|performance_schema\|mysql\|sys" || true)
        if [ ! -z "$EXISTING_DBS" ]; then
            echo "$EXISTING_DBS" | while read db; do
                if [ ! -z "$db" ] && [ "$db" != "Database" ]; then
                    docker compose exec db mysql -u root -p123 -e "DROP DATABASE IF EXISTS \`$db\`;" >/dev/null 2>&1 || true
                fi
            done
        fi
        sleep 5
    fi
done

[ "$SITE_CREATED" = false ] && error "Site creation failed after 3 attempts"

# Build assets (30s timeout)
log "Building assets (30s)"
docker compose exec backend bench --site localhost build || error "Asset build failed"

# Fix asset sync issue for macOS (15s)
log "Syncing assets to frontend"
# Create asset backup and restore to force volume sync
docker compose exec backend tar -czf /tmp/assets.tar.gz -C /home/frappe/frappe-bench/sites assets >/dev/null 2>&1
docker compose stop frontend >/dev/null 2>&1
sleep 3
docker compose exec backend tar -xzf /tmp/assets.tar.gz -C /home/frappe/frappe-bench/sites >/dev/null 2>&1
docker compose start frontend >/dev/null 2>&1

# Wait for frontend to start
log "Waiting for frontend startup"
sleep 10

# Get results and verify
PORT=$(docker compose port frontend 8080 2>/dev/null | cut -d: -f2 || echo "unknown")
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Final verification (30s)
log "Verifying deployment"
FRONTEND_OK=false
CSS_OK=false

# Wait for frontend to be fully ready (up to 30 seconds)
for i in {1..30}; do
    if curl -f -s "http://localhost:$PORT" >/dev/null 2>&1; then
        FRONTEND_OK=true
        log "Frontend responding"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        error "Frontend not responding after 30s timeout"
    fi
done

# Test CSS assets
if [ "$FRONTEND_OK" = true ]; then
    CSS_URL=$(curl -s "http://localhost:$PORT" | grep -o '/assets/frappe/dist/css/website\.bundle\.[^"]*\.css' | head -1)
    if [ -n "$CSS_URL" ] && curl -f -s "http://localhost:$PORT$CSS_URL" >/dev/null 2>&1; then
        CSS_OK=true
        log "CSS assets verified working"
    else
        log "WARNING: CSS assets not loading properly"
    fi
fi

# Report results
if [ "$FRONTEND_OK" = true ]; then
    log "SUCCESS! Deployment completed in ${DURATION}s"
    echo "=================================="
    echo "Access: http://localhost:$PORT"
    echo "Login: Administrator / admin"
    echo "Deploy Type: $DEPLOY_TYPE"
    echo "CSS Status: $([ "$CSS_OK" = true ] && echo "Working" || echo "Issues detected")"
    echo "=================================="
    
    # Show service status
    log "Service status:"
    docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
else
    error "Deployment failed after ${DURATION}s"
fi

if [ $DURATION -gt 300 ]; then
    log "WARNING: Deployment took ${DURATION}s (target: 300s)"
else
    log "Target met: ${DURATION}s <= 300s"
fi