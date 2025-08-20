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

show_help() {
    cat << EOF
Clean Frappe Docker Deployment Script

USAGE:
    ./deploy.sh [OPTION] [FLAGS]

OPTIONS:
    (no option)         Basic Frappe/ERPNext deployment
    with-epibus         EpiBus only deployment  
    with-plc            Complete industrial automation (recommended)
    lab                 Training lab deployment with custom domains
    --help, -h          Show this help message

FLAGS:
    --rebuild           Force rebuild of custom images (even if they exist)
    --force-rebuild     Same as --rebuild

DEPLOYMENT TYPES:

    Basic Deployment:
        ./deploy.sh
        - Standard Frappe/ERPNext ERP system
        - MariaDB database
        - Redis caching
        - Web interface at http://localhost:[dynamic-port]

    EpiBus Deployment:
        ./deploy.sh with-epibus
        - Includes everything from basic deployment
        - EpiBus industrial integration app
        - Custom Frappe app for MODBUS communication

    Complete Industrial Automation:
        ./deploy.sh with-plc
        - Includes everything from EpiBus deployment
        - OpenPLC simulator for PLC programming
        - MODBUS TCP server (port 502)
        - PLC Bridge for real-time communication
        - Web interfaces for both ERPNext and OpenPLC

    Training Lab:
        ./deploy.sh lab
        - Complete industrial automation setup
        - Custom domain configuration (*.lab)
        - Traefik reverse proxy
        - Optimized for training environments
        
    Web:
        ./deploy.sh web [DOMAIN]
        - Complete industrial automation setup
        - Real domain configuration with subdomains
        - Traefik reverse proxy for web deployment
        - Specify custom domain: ./deploy.sh web mydomain.com
        - Default domain: intralogisticsai.online

    Stop:
        ./deploy.sh stop
        - Stop all running services
        - Remove containers, networks, and volumes
        - Complete cleanup of the deployment

REQUIREMENTS:
    - Docker and Docker Compose installed
    - .env file configured (copy from example.env)
    - Required environment variables: DB_PASSWORD, ERPNEXT_VERSION
    - For with-plc deployments: PULL_POLICY must be set

ACCESS:
    - ERPNext: http://localhost:[dynamic-port] (use 'docker compose ps' to check port)
    - OpenPLC: http://localhost:8081 (for with-plc deployments)
    - Default login: Administrator / admin

For more information, see CLAUDE.md in the repository root.
EOF
}

# Parse arguments
DEPLOY_TYPE=""
FORCE_REBUILD=false
WEB_DOMAIN=""

for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            exit 0
            ;;
        --rebuild|--force-rebuild)
            FORCE_REBUILD=true
            ;;
        with-epibus|with-plc|lab|web|stop)
            DEPLOY_TYPE="$arg"
            ;;
        *)
            if [[ -z "$DEPLOY_TYPE" && "$arg" != "--rebuild" && "$arg" != "--force-rebuild" ]]; then
                DEPLOY_TYPE="$arg"
            elif [[ "$DEPLOY_TYPE" = "web" && -z "$WEB_DOMAIN" && "$arg" != "--rebuild" && "$arg" != "--force-rebuild" ]]; then
                WEB_DOMAIN="$arg"
            fi
            ;;
    esac
done

# Set default domain for web deployment
if [[ "$DEPLOY_TYPE" = "web" && -z "$WEB_DOMAIN" ]]; then
    WEB_DOMAIN="intralogisticsai.online"
fi

# Export web domain early if set
if [[ -n "$WEB_DOMAIN" ]]; then
    export WEB_DOMAIN
fi

source .env
set -e

# Docker health check and recovery
check_docker() {
    log "Checking Docker health..."
    if ! docker ps >/dev/null 2>&1; then
        log "Docker appears to be unavailable. Attempting to start Docker..."
        if command -v docker-desktop >/dev/null 2>&1; then
            docker-desktop --restart
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open -a Docker
        fi
        
        # Wait for Docker to be ready
        for i in {1..30}; do
            if docker ps >/dev/null 2>&1; then
                log "Docker is now available"
                return 0
            fi
            log "Waiting for Docker to start... ($i/30)"
            sleep 2
        done
        error "Docker failed to start after 60 seconds"
    fi
    log "Docker is healthy"
}

log() { echo "[$(date +'%H:%M:%S')] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

verify_no_containers_exist() {
    if docker ps -aq --filter "label=com.docker.compose.project=intralogisticsai" | grep -q .; then
        error "Failed to stop all intralogisticsai containers."
    fi
}

verify_no_networks_exist() {
    if docker network ls --filter "name=intralogisticsai" --filter "name=frappe" -q | grep -q .; then
        error "Failed to remove all intralogisticsai/frappe networks."
    fi
}

verify_no_volumes_exist() {
    if docker volume ls --filter "name=intralogisticsai" -q | grep -q .; then
        error "Failed to remove all intralogisticsai volumes."
    fi
}

verify_no_images_exist() {
    if docker images -q --filter "label=com.docker.compose.project=intralogisticsai" | grep -q .; then
        error "Failed to remove all intralogisticsai images."
    fi
}

: ${DB_PASSWORD:?Error: DB_PASSWORD is not set in .env or environment. Please set it.}
: ${ERPNEXT_VERSION:?Error: ERPNEXT_VERSION is not set in .env or environment. Please set it.}


DEPLOY_TYPE=${DEPLOY_TYPE:-"basic"}
log "Starting deployment: $DEPLOY_TYPE"
if [[ "$FORCE_REBUILD" == "true" ]]; then
    log "Force rebuild mode enabled"
fi

# Check Docker health before proceeding
check_docker

# Detect platform and set compose overrides
PLATFORM_OVERRIDE=""
ARCH=$(uname -m)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        log "Detected macOS ARM64 (Apple Silicon) - using ARM64 optimizations"
        PLATFORM_OVERRIDE="-f overrides/compose.arm64.yaml"
    else
        log "Detected macOS Intel - using standard configuration"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
        log "Detected Linux ARM64 - using ARM64 optimizations"
        PLATFORM_OVERRIDE="-f overrides/compose.arm64.yaml"
    else
        log "Detected Linux x86_64 - using standard configuration"
    fi
else
    log "Unknown platform: $OSTYPE - using standard configuration"
fi

if [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    log "Deploying with EpiBus application"
    build_epibus_if_needed
fi

# Check directory
[ ! -f "compose.yaml" ] && error "Must run from frappe_docker directory"

# Complete cleanup with error handling
log "Complete cleanup"
docker compose down --volumes --remove-orphans 2>/dev/null || true

# Targeted cleanup - only remove intralogistics-related resources
log "Cleaning up intralogistics containers, networks, and volumes"

# Clean up any remaining intralogistics containers
docker ps -aq --filter "label=com.docker.compose.project=intralogisticsai" | xargs -r docker rm -f 2>/dev/null || true

# Clean up intralogistics networks
docker network ls --filter "name=intralogisticsai" --filter "name=frappe" -q | xargs -r docker network rm 2>/dev/null || true

# Clean up intralogistics volumes
docker volume ls --filter "name=intralogisticsai" -q | xargs -r docker volume rm 2>/dev/null || true

# Clean up intralogistics images
docker images -q --filter "label=com.docker.compose.project=intralogisticsai" | xargs -r docker rmi -f 2>/dev/null || true

log "Targeted cleanup completed"

# Function to check if custom image exists
check_custom_image() {
    local image_name="$1"
    local tag="$2"
    
    if docker image inspect "${image_name}:${tag}" >/dev/null 2>&1; then
        log "Custom image ${image_name}:${tag} already exists - skipping build"
        return 0
    else
        log "Custom image ${image_name}:${tag} not found - building required"
        return 1
    fi
}

# Function to build custom image if needed
build_epibus_if_needed() {
    if [[ "$FORCE_REBUILD" == "true" ]]; then
        log "Force rebuild requested - building frappe-epibus image..."
        ./development/build-epibus-image.sh || error "EpiBus image build failed. Exiting."
    elif check_custom_image "frappe-epibus" "latest"; then
        log "Using existing frappe-epibus:latest image"
    else
        log "Building frappe-epibus image..."
        ./development/build-epibus-image.sh || error "EpiBus image build failed. Exiting."
    fi
}

# Function to retry docker compose with network resilience
retry_compose_up() {
    local max_attempts=3
    for attempt in $(seq 1 $max_attempts); do
        log "Starting deployment attempt $attempt of $max_attempts"
        
        # Ensure environment variables are available to docker compose
        if [ -n "$CUSTOM_IMAGE" ]; then
            log "Using custom image: $CUSTOM_IMAGE:$CUSTOM_TAG with pull policy: $PULL_POLICY"
            export CUSTOM_IMAGE CUSTOM_TAG PULL_POLICY
        fi
        
        if docker compose "$@" up -d; then
            log "Deployment successful on attempt $attempt"
            return 0
        else
            log "Deployment attempt $attempt failed"
            if [ $attempt -eq $max_attempts ]; then
                error "Deployment failed after $max_attempts attempts. Please check your internet connection and try again."
            else
                log "Retrying in 30 seconds..."
                sleep 30
                # Clean up any partial containers before retry
                docker compose "$@" down --volumes --remove-orphans 2>/dev/null || true
            fi
        fi
    done
}


# Handle stop command
if [ "$DEPLOY_TYPE" = "stop" ]; then
    log "Stopping all services and cleaning up..."

    # Stop and remove containers, networks, volumes
    docker compose down --volumes --remove-orphans 2>/dev/null || true

    # Clean up any remaining containers
    docker ps -aq --filter "label=com.docker.compose.project=intralogisticsai" | xargs -r docker rm -f 2>/dev/null || true

    # Clean up networks
    docker network ls --filter "name=intralogisticsai" --filter "name=frappe" -q | xargs -r docker network rm 2>/dev/null || true

    # Clean up volumes
    docker volume ls --filter "name=intralogisticsai" -q | xargs -r docker volume rm 2>/dev/null || true

    # Verification functions
    verify_no_containers_exist() {
        if docker ps -aq --filter "label=com.docker.compose.project=intralogisticsai" | grep -q .; then
            error "Failed to stop all intralogisticsai containers."
        fi
    }

    verify_no_networks_exist() {
        if docker network ls --filter "name=intralogisticsai" --filter "name=frappe" -q | grep -q .; then
            error "Failed to remove all intralogisticsai/frappe networks."
        fi
    }

    verify_no_volumes_exist() {
        if docker volume ls --filter "name=intralogisticsai" -q | grep -q .; then
            error "Failed to remove all intralogisticsai volumes."
        fi
    }

    log "Verifying cleanup..."
    verify_no_containers_exist
    verify_no_networks_exist
    verify_no_volumes_exist

    # Clean up any remaining images
    docker images -q --filter "label=com.docker.compose.project=intralogisticsai" | xargs -r docker rmi -f 2>/dev/null || true

    log "Verifying cleanup..."
    verify_no_containers_exist
    verify_no_networks_exist
    verify_no_volumes_exist
    verify_no_images_exist

    log "Cleanup completed successfully"
    exit 0
fi

# Validate required environment variables

# Build EpiBus image if needed for deployments that require it
if [ "$DEPLOY_TYPE" = "lab" ] || [ "$DEPLOY_TYPE" = "web" ] || [ "$DEPLOY_TYPE" = "with-plc" ] || [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    build_epibus_if_needed
    
    # Export environment variables for docker compose
    export CUSTOM_IMAGE=frappe-epibus
    export CUSTOM_TAG=latest
    export PULL_POLICY=never
    
    # Log environment variables
    if [[ "$DEPLOY_TYPE" = "web" ]]; then
        log "Environment variables set: CUSTOM_IMAGE=$CUSTOM_IMAGE, CUSTOM_TAG=$CUSTOM_TAG, PULL_POLICY=$PULL_POLICY, WEB_DOMAIN=$WEB_DOMAIN"
    else
        log "Environment variables set: CUSTOM_IMAGE=$CUSTOM_IMAGE, CUSTOM_TAG=$CUSTOM_TAG, PULL_POLICY=$PULL_POLICY"
    fi
fi

# Deploy based on type
if [ "$DEPLOY_TYPE" = "lab" ]; then
    log "Deploying training lab environment with custom domains"
    
    retry_compose_up \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.openplc.yaml \
      -f overrides/compose.plc-bridge.yaml \
      -f overrides/compose.lab.yaml \
      -f overrides/compose.create-site.yaml \
      $PLATFORM_OVERRIDE
elif [ "$DEPLOY_TYPE" = "web" ]; then
    log "Deploying web environment with real domains: $WEB_DOMAIN"
    
    retry_compose_up \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.openplc.yaml \
      -f overrides/compose.plc-bridge.yaml \
      -f overrides/compose.web.yaml \
      -f overrides/compose.create-site-web.yaml \
      $PLATFORM_OVERRIDE
elif [ "$DEPLOY_TYPE" = "with-plc" ]; then
    log "Deploying with PLC features using compose.yaml with overrides"
    
    retry_compose_up \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.openplc.yaml \
      -f overrides/compose.plc-bridge.yaml \
      -f overrides/compose.create-site.yaml \
      $PLATFORM_OVERRIDE
elif [ "$DEPLOY_TYPE" = "with-epibus" ]; then
    log "Deploying with EpiBus application using compose.yaml with overrides"
    
    retry_compose_up \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.create-site.yaml \
      $PLATFORM_OVERRIDE
else
    log "Deploying basic Frappe using compose.yaml with overrides"
    retry_compose_up \
      -f compose.yaml \
      -f overrides/compose.mariadb.yaml \
      -f overrides/compose.redis.yaml \
      -f overrides/compose.create-site.yaml \
      $PLATFORM_OVERRIDE
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
if [ "$DEPLOY_TYPE" = "with-plc" ] || [ "$DEPLOY_TYPE" = "with-epibus" ] || [ "$DEPLOY_TYPE" = "lab" ]; then
    log "Installing EpiBus on site"
    sleep 30 # Give extra time for site creation to complete
    
    # Wait for site to be fully ready with retry logic
    for i in {1..60}; do
        if docker compose exec backend bench --site intralogistics.localhost install-app epibus 2>/dev/null; then
            log "EpiBus installation completed successfully"
            break
        else
            log "EpiBus installation attempt $i failed, retrying in 10 seconds..."
            sleep 10
            if [ $i -eq 60 ]; then
                log "EpiBus installation failed after 60 attempts. Manual installation may be required:"
                log "Run: docker compose exec backend bench --site intralogistics.localhost install-app epibus"
                break
            fi
        fi
    done
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
        OPENPLC_PORT=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep openplc | sed 's/.*:\([0-9]*\)->8080.*/\1/' || echo "8081")
        echo "Lab Environment URLs:"
        echo "  - ERPNext Interface: http://localhost:$PORT"
        echo "  - OpenPLC Simulator: http://localhost:$OPENPLC_PORT"
        echo "  - Traefik Dashboard: http://localhost:8080"
        echo "  - Lab Domains (configure in /etc/hosts):"
        echo "    127.0.0.1 intralogistics.lab openplc.intralogistics.lab dashboard.intralogistics.lab"
        echo "MODBUS TCP: localhost:502 (for real PLC connections)"
        echo "PLC Bridge: localhost:7654 (real-time events)"
        echo "EpiBus: Installed and integrated"
    elif [ "$DEPLOY_TYPE" = "web" ]; then
        echo "Web Environment URLs:"
        echo "  - ERPNext: http://$WEB_DOMAIN"
        echo "  - OpenPLC: http://openplc.$WEB_DOMAIN"
        echo "  - Traefik Dashboard: http://dashboard.$WEB_DOMAIN"
        echo "MODBUS TCP: $WEB_DOMAIN:502 (for real PLC connections)"
        echo "PLC Bridge: $WEB_DOMAIN:7654 (real-time events)"
        echo "EpiBus: Installed and integrated"
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