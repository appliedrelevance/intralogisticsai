#!/bin/bash

# Frappe Docker Setup Script for Mac M4 (ARM64)
# This script sets up Frappe Docker with ARM64 compatibility and port collision prevention

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker availability..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Buildx is available
check_buildx() {
    print_status "Checking Docker Buildx availability..."
    if ! docker buildx version >/dev/null 2>&1; then
        print_error "Docker Buildx is not available. Please update Docker Desktop."
        exit 1
    fi
    print_success "Docker Buildx is available"
}

# Function to create buildx builder for ARM64
setup_buildx() {
    print_status "Setting up Docker Buildx for ARM64..."
    
    # Create a new builder instance if it doesn't exist
    if ! docker buildx ls | grep -q "frappe-mac-m4"; then
        print_status "Creating new buildx builder for ARM64..."
        docker buildx create --name frappe-mac-m4 --platform linux/arm64 --use
    else
        print_status "Using existing buildx builder..."
        docker buildx use frappe-mac-m4
    fi
    
    print_success "Buildx builder configured for ARM64"
}

# Function to build ARM64 images
build_images() {
    print_status "Building ARM64-compatible images..."
    print_warning "This may take several minutes on first run..."
    
    # Build the images with ARM64 platform
    if docker buildx build --platform linux/arm64 --load -t frappe/erpnext:latest .; then
        print_success "ARM64 images built successfully"
    else
        print_error "Failed to build ARM64 images"
        exit 1
    fi
}

# Function to generate the final compose file
generate_compose() {
    print_status "Generating final compose configuration..."
    
    # Create the final compose file with overrides
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        config > docker-compose.mac-m4.generated.yaml
    
    if [ $? -eq 0 ]; then
        print_success "Generated docker-compose.mac-m4.generated.yaml"
    else
        print_error "Failed to generate compose file"
        exit 1
    fi
}

# Function to start services
start_services() {
    print_status "Starting Frappe Docker services..."
    
    # Start services using the override
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        up -d
    
    if [ $? -eq 0 ]; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for the configurator to complete
    print_status "Waiting for configurator to complete..."
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        wait configurator
    
    # Wait a bit more for other services to stabilize
    sleep 10
    
    print_success "Services are ready"
}

# Function to discover assigned port
discover_port() {
    print_status "Discovering assigned port..."
    
    # Get the assigned port for the frontend service
    ASSIGNED_PORT=$(docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        port frontend 8080 2>/dev/null | cut -d: -f2)
    
    if [ -n "$ASSIGNED_PORT" ]; then
        print_success "Frontend is available on port: $ASSIGNED_PORT"
        echo ""
        echo "🎉 Frappe Docker is now running!"
        echo "📱 Access URL: http://localhost:$ASSIGNED_PORT"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Open http://localhost:$ASSIGNED_PORT in your browser"
        echo "   2. Complete the Frappe setup wizard"
        echo "   3. Use './get-access-url.sh' to get the URL anytime"
        echo ""
    else
        print_warning "Could not determine assigned port. Use 'docker compose ps' to check service status."
    fi
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        ps
}

# Main execution
main() {
    echo ""
    echo "🚀 Frappe Docker Setup for Mac M4 (ARM64)"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    check_docker
    check_buildx
    
    # Setup buildx for ARM64
    setup_buildx
    
    # Build images (optional - comment out if using pre-built images)
    # build_images
    
    # Generate compose file
    generate_compose
    
    # Start services
    start_services
    
    # Wait for services
    wait_for_services
    
    # Discover port and show access information
    discover_port
    
    # Show final status
    show_status
    
    echo ""
    print_success "Setup completed successfully!"
    echo ""
}

# Handle script arguments
case "${1:-}" in
    "build")
        print_status "Building ARM64 images only..."
        check_docker
        check_buildx
        setup_buildx
        build_images
        ;;
    "start")
        print_status "Starting services only..."
        check_docker
        start_services
        wait_for_services
        discover_port
        show_status
        ;;
    "stop")
        print_status "Stopping services..."
        docker compose \
            -f compose.yaml \
            -f overrides/compose.mac-m4.yaml \
            down
        print_success "Services stopped"
        ;;
    "status")
        show_status
        ;;
    *)
        main
        ;;
esac