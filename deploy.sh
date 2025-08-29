#!/bin/bash

# Intralogistics AI Lab Deployment Script
# Deploys the complete industrial automation training lab environment
#
# Usage:
#   ./deploy.sh                    # Deploy lab environment
#   ./deploy.sh --rebuild          # Force rebuild of custom images
#   ./deploy.sh stop               # Stop and cleanup lab environment

show_help() {
    cat << EOF
Intralogistics AI Lab Deployment Script

USAGE:
    ./deploy.sh [FLAGS]

FLAGS:
    --rebuild           Force rebuild of custom images
    --force-rebuild     Same as --rebuild  
    --help, -h          Show this help message
    stop                Stop and cleanup lab environment

DEPLOYMENT:
    The lab environment includes:
    - Frappe/ERPNext ERP system
    - EpiBus industrial integration app
    - MODBUS TCP server (port 502)
    - PLC Bridge for real-time communication
    - Traefik reverse proxy with custom domains
    - Complete setup wizard automation

ACCESS:
    - ERPNext: http://intralogistics.lab
    - Traefik Dashboard: http://dashboard.intralogistics.lab
    - Default login: Administrator / admin

For more information, see CLAUDE.md in the repository root.
EOF
}

# Parse arguments
FORCE_REBUILD=false

for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            exit 0
            ;;
        --rebuild|--force-rebuild)
            FORCE_REBUILD=true
            ;;
        stop)
            DEPLOY_TYPE="stop"
            ;;
        *)
            if [[ -z "$DEPLOY_TYPE" ]]; then
                DEPLOY_TYPE="$arg"
            fi
            ;;
    esac
done

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

# Cross-platform hosts file management
get_hosts_file() {
    # Check if we're running in WSL2 on Windows
    if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        echo "/mnt/c/Windows/System32/drivers/etc/hosts"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "C:\\Windows\\System32\\drivers\\etc\\hosts"
    else
        echo "/etc/hosts"
    fi
}

# Check if we have required privileges for lab deployment
check_lab_privileges() {
    local hosts_file=$(get_hosts_file)
    
    # Skip check if domains already exist
    if grep -q "intralogistics.lab" "$hosts_file" 2>/dev/null; then
        return 0
    fi
    
    # Check if we're running in WSL2 on Windows
    if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        # WSL2 on Windows - test if we can write to Windows hosts file
        if ! touch "$hosts_file.test" 2>/dev/null; then
            echo ""
            echo "ERROR: Lab deployment requires permission to modify Windows hosts file."
            echo "Please ensure WSL2 has access to modify $hosts_file"
            echo "You may need to:"
            echo "  1. Run WSL as Administrator, or"
            echo "  2. Manually add this line to your Windows hosts file:"
            echo "     127.0.0.1 intralogistics.lab dashboard.intralogistics.lab"
            echo "  3. Then re-run: ./deploy.sh"
            echo ""
            exit 1
        else
            rm -f "$hosts_file.test" 2>/dev/null
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows - check if running as administrator
        if ! net session >/dev/null 2>&1; then
            echo ""
            echo "ERROR: Lab deployment requires Administrator privileges to modify hosts file."
            echo "Please run this script as Administrator:"
            echo "  Right-click Command Prompt or PowerShell → 'Run as Administrator'"
            echo "  Then run: ./deploy.sh"
            echo ""
            exit 1
        fi
    else
        # Unix-like systems (macOS, Linux) - check if we can sudo
        if ! sudo -n true 2>/dev/null; then
            echo ""
            echo "ERROR: Lab deployment requires sudo privileges to modify /etc/hosts file."
            echo "Please run this script with sudo:"
            echo "  sudo ./deploy.sh"
            echo ""
            echo "Or manually add this line to /etc/hosts and re-run without sudo:"
            echo "  127.0.0.1 intralogistics.lab dashboard.intralogistics.lab"
            echo ""
            exit 1
        fi
    fi
}

# Add lab domains to hosts file
add_lab_hosts() {
    local hosts_file=$(get_hosts_file)
    local lab_entry="127.0.0.1 intralogistics.lab dashboard.intralogistics.lab"
    
    log "Adding lab domains to hosts file: $hosts_file"
    
    # Check if entries already exist
    if grep -q "intralogistics.lab" "$hosts_file" 2>/dev/null; then
        log "Lab domains already exist in hosts file"
        return 0
    fi
    
    # Add entries (we know we have privileges from check_lab_privileges)
    if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        # WSL2 on Windows - direct file access
        echo "$lab_entry" >> "$hosts_file"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "$lab_entry" >> "$hosts_file"
    else
        echo "$lab_entry" | sudo tee -a "$hosts_file" >/dev/null
    fi
    
    log "Lab domains added successfully to hosts file"
    return 0
}

# Remove lab domains from hosts file
remove_lab_hosts() {
    local hosts_file=$(get_hosts_file)
    
    log "Removing lab domains from hosts file: $hosts_file"
    
    # Check if entries exist
    if ! grep -q "intralogistics.lab" "$hosts_file" 2>/dev/null; then
        log "No lab domains found in hosts file"
        return 0
    fi
    
    # Try to remove entries with appropriate privileges
    if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        # WSL2 on Windows - direct file access
        if ! touch "$hosts_file.test" 2>/dev/null; then
            log "WARNING: Cannot write to Windows hosts file. Please remove lab domain lines from $hosts_file manually."
            return 1
        else
            rm -f "$hosts_file.test" 2>/dev/null
            # Create temporary file without lab entries
            grep -v "intralogistics.lab" "$hosts_file" > "${hosts_file}.tmp" && mv "${hosts_file}.tmp" "$hosts_file"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows - check if running as administrator
        if ! net session >/dev/null 2>&1; then
            log "WARNING: Not running as Administrator. Please remove lab domain lines from $hosts_file manually."
            return 1
        fi
        # Create temporary file without lab entries
        grep -v "intralogistics.lab" "$hosts_file" > "${hosts_file}.tmp" && mv "${hosts_file}.tmp" "$hosts_file"
    else
        # Unix-like systems (macOS, Linux)
        if ! sudo -n true 2>/dev/null; then
            log "Removing lab domains from hosts file requires sudo privileges..."
            sudo sed -i.bak '/intralogistics\.lab/d' "$hosts_file" || {
                log "WARNING: Could not remove lab domains from hosts file. Please remove manually:"
                log "  sudo sed -i.bak '/intralogistics\.lab/d' $hosts_file"
                return 1
            }
        else
            sudo sed -i.bak '/intralogistics\.lab/d' "$hosts_file"
        fi
    fi
    
    log "Lab domains removed successfully from hosts file"
    return 0
}

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

# Set deployment type - always lab unless stopping
DEPLOY_TYPE=${DEPLOY_TYPE:-"lab"}
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

    # Remove lab domains from hosts file
    remove_lab_hosts

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

# Build EpiBus image for lab deployment
build_epibus_if_needed

# Export environment variables for docker compose
export CUSTOM_IMAGE=frappe-epibus
export CUSTOM_TAG=latest
export PULL_POLICY=never

log "Environment variables set: CUSTOM_IMAGE=$CUSTOM_IMAGE, CUSTOM_TAG=$CUSTOM_TAG, PULL_POLICY=$PULL_POLICY"

# Deploy lab environment
log "Deploying training lab environment with custom domains"

# Check if we have required privileges for hosts file modification
check_lab_privileges

# Add lab domains to hosts file
add_lab_hosts

retry_compose_up \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.plc-bridge.yaml \
  -f overrides/compose.lab.yaml \
  -f overrides/compose.create-site-lab.yaml \
  $PLATFORM_OVERRIDE

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

# Wait for site creation to complete
log "Waiting for site creation to complete..."
sleep 30

# Verify EpiBus installation (already installed during site creation)
log "Verifying EpiBus installation..."

# Check if EpiBus is already installed (it should be from site creation)
if docker compose exec backend bench --site intralogistics.lab list-apps 2>/dev/null | grep -q epibus; then
    log "EpiBus already installed during site creation"
else
    log "EpiBus not found, installing now..."
    for i in {1..30}; do
        if docker compose exec backend bench --site intralogistics.lab install-app epibus 2>/dev/null; then
            log "EpiBus installation completed successfully"
            break
        else
            log "EpiBus installation attempt $i failed, retrying in 10 seconds..."
            sleep 10
            if [ $i -eq 30 ]; then
                log "EpiBus installation failed after 30 attempts. Manual installation may be required:"
                log "Run: docker compose exec backend bench --site intralogistics.lab install-app epibus"
                break
            fi
        fi
    done
fi

# Comprehensive deployment testing
test_deployment() {
    local test_results=()
    local all_passed=true
    
    log "Running comprehensive deployment tests for lab environment..."
    log "Testing site: intralogistics.lab"
    
    # Test 1: Container health
    log "Testing container health..."
    local unhealthy_containers=$(docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -v "Up" | grep -v "Exited (0)" | tail -n +2)
    if [ -n "$unhealthy_containers" ]; then
        test_results+=("❌ Unhealthy containers found:")
        test_results+=("$unhealthy_containers")
        all_passed=false
    else
        test_results+=("✅ All containers are healthy")
    fi
    
    # Test 2: Basic HTTP connectivity
    log "Testing HTTP connectivity..."
    if curl --max-time 5 -f -s "http://intralogistics.lab" >/dev/null 2>&1; then
        test_results+=("✅ Frontend HTTP responding at http://intralogistics.lab")
    else
        test_results+=("❌ Frontend HTTP not responding at http://intralogistics.lab")
        all_passed=false
    fi
    
    # Test 3: ERPNext login page
    log "Testing ERPNext application..."
    local login_test=$(curl --max-time 5 -s "http://intralogistics.lab" | grep -i "login\|erpnext" | head -1)
    
    if [ -n "$login_test" ]; then
        test_results+=("✅ ERPNext application responding correctly")
    else
        test_results+=("❌ ERPNext application not responding correctly")
        all_passed=false
    fi
    
    # Test 4: Database connectivity
    log "Testing database connectivity..."
    if docker compose exec backend bench --site intralogistics.lab list-apps >/dev/null 2>&1; then
        test_results+=("✅ Database connectivity working")
    else
        test_results+=("❌ Database connectivity failed")
        all_passed=false
    fi
    
    # Test 5: Setup wizard completion validation
    log "Testing setup wizard completion..."
    local setup_complete_status=$(docker compose exec backend bash -c "cd /home/frappe/frappe-bench && ./env/bin/python -c \"
import frappe
import os
os.chdir('/home/frappe/frappe-bench')
frappe.init('intralogistics.lab')
frappe.connect()
print('SETUP_COMPLETE=' + str(frappe.db.get_single_value('System Settings', 'setup_complete') or 0))
print('COMPANY_EXISTS=' + str(frappe.db.exists('Company', 'Roots Intralogistics') or 0))
print('DEFAULT_CURRENCY=' + str(frappe.db.get_single_value('Global Defaults', 'default_currency') or 'None'))
print('TIMEZONE=' + str(frappe.db.get_single_value('System Settings', 'time_zone') or 'None'))
print('ADMIN_USER=' + str(frappe.db.exists('User', 'Administrator') or 0))
\"" 2>/dev/null)
    
    if echo "$setup_complete_status" | grep -q "SETUP_COMPLETE=1"; then
        test_results+=("✅ Setup wizard marked as complete")
    else
        test_results+=("❌ Setup wizard not completed")
        all_passed=false
    fi
    
    if echo "$setup_complete_status" | grep -q "COMPANY_EXISTS=Roots Intralogistics"; then
        test_results+=("✅ Company 'Roots Intralogistics' created")
    else
        test_results+=("❌ Company 'Roots Intralogistics' not found")
        all_passed=false
    fi
    
    if echo "$setup_complete_status" | grep -q "DEFAULT_CURRENCY=USD"; then
        test_results+=("✅ Default currency set to USD")
    else
        test_results+=("❌ Default currency not set to USD")
        all_passed=false
    fi
    
    if echo "$setup_complete_status" | grep -q "TIMEZONE=America/New_York"; then
        test_results+=("✅ Timezone set to America/New_York")
    else
        test_results+=("❌ Timezone not set to America/New_York")
        all_passed=false
    fi
    
    if echo "$setup_complete_status" | grep -q "ADMIN_USER=Administrator"; then
        test_results+=("✅ Administrator user exists")
    else
        test_results+=("❌ Administrator user not found")
        all_passed=false
    fi
    
    # Test 6: EpiBus availability
    log "Testing EpiBus installation..."
    local epibus_test=$(docker compose exec backend bench --site intralogistics.lab list-apps 2>/dev/null | grep epibus)
    if [ -n "$epibus_test" ]; then
        test_results+=("✅ EpiBus app installed and available")
    else
        test_results+=("❌ EpiBus app not found")
        all_passed=false
    fi
    
    # Test 7: MODBUS TCP port
    if timeout 3 bash -c "</dev/tcp/localhost/502" 2>/dev/null; then
        test_results+=("✅ MODBUS TCP port 502 accessible")
    else
        test_results+=("❌ MODBUS TCP port 502 not accessible")
        all_passed=false
    fi
    
    # Test 8: Lab domains
    log "Testing lab domain routing..."
    
    # First check hosts file configuration
    local hosts_file=$(get_hosts_file)
    if grep -q "intralogistics.lab" "$hosts_file" 2>/dev/null; then
        test_results+=("✅ Lab domains configured in hosts file")
    else
        test_results+=("❌ Lab domains missing from hosts file: $hosts_file")
        test_results+=("   Manual fix: Add '127.0.0.1 intralogistics.lab dashboard.intralogistics.lab' to hosts file")
        all_passed=false
    fi
    
    # Display results
    echo ""
    echo "🧪 DEPLOYMENT TEST RESULTS"
    echo "=================================="
    for result in "${test_results[@]}"; do
        echo "$result"
    done
    echo "=================================="
    
    return $( [ "$all_passed" = true ] && echo 0 || echo 1 )
}

# Run deployment tests
if test_deployment; then
    log "🎉 SUCCESS! All deployment tests passed"
    echo ""
    echo "🚀 LAB DEPLOYMENT COMPLETED SUCCESSFULLY"
    echo "=================================="
    echo "Login: Administrator / admin"
    echo "Lab Environment URLs:"
    echo "  - ERPNext Interface: http://intralogistics.lab"
    echo "  - Traefik Dashboard: http://dashboard.intralogistics.lab"
    echo "MODBUS TCP: localhost:502 (for real PLC connections)"
    echo "PLC Bridge: localhost:7654 (real-time events)"
    echo "EpiBus: Installed and integrated"
    echo "=================================="
else
    log "❌ DEPLOYMENT FAILED - Some tests did not pass"
    echo ""
    echo "🔧 TROUBLESHOOTING STEPS:"
    echo "1. Check container logs: docker compose logs"
    echo "2. Check container status: docker compose ps"
    echo "3. Try accessing directly: http://intralogistics.lab"
    echo "4. Verify hosts file entries"
    echo "5. Restart deployment: ./deploy.sh stop && ./deploy.sh"
    echo ""
    echo "If issues persist, check the troubleshooting guide in docs/"
    exit 1
fi

# Cleanup
rm -f deploy.yml

log "Deployment script completed"