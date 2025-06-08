#!/bin/bash

# Frappe Docker Access URL Helper for Mac M4
# This script discovers the dynamically assigned port and provides access information

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_url() {
    echo -e "${CYAN}$1${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
}

# Function to check if services are running
check_services() {
    print_status "Checking service status..."
    
    # Check if any frappe services are running
    if ! docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        ps --services --filter "status=running" | grep -q .; then
        print_error "No Frappe Docker services are running."
        echo ""
        echo "To start services, run:"
        echo "  ./setup-mac-m4.sh start"
        echo ""
        exit 1
    fi
}

# Function to get service status
get_service_status() {
    print_status "Service Status:"
    echo ""
    
    # Get detailed service status
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
}

# Function to discover and display access information
get_access_info() {
    print_status "Discovering access information..."
    
    # Get the assigned port for the frontend service
    ASSIGNED_PORT=$(docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        port frontend 8080 2>/dev/null | cut -d: -f2)
    
    if [ -n "$ASSIGNED_PORT" ] && [ "$ASSIGNED_PORT" != "8080" ]; then
        echo ""
        echo "🎉 Frappe Docker Access Information"
        echo "=================================="
        echo ""
        print_success "Frontend service is running on port: $ASSIGNED_PORT"
        echo ""
        echo "🌐 Access URLs:"
        print_url "   Primary: http://localhost:$ASSIGNED_PORT"
        print_url "   Alternative: http://127.0.0.1:$ASSIGNED_PORT"
        echo ""
        
        # Check if the service is responding
        print_status "Checking service health..."
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ASSIGNED_PORT" | grep -q "200\|302\|404"; then
            print_success "Service is responding to HTTP requests"
        else
            print_warning "Service may still be starting up. Please wait a moment and try again."
        fi
        
    elif [ "$ASSIGNED_PORT" = "8080" ]; then
        echo ""
        echo "🎉 Frappe Docker Access Information"
        echo "=================================="
        echo ""
        print_success "Frontend service is running on default port: 8080"
        echo ""
        echo "🌐 Access URLs:"
        print_url "   Primary: http://localhost:8080"
        print_url "   Alternative: http://127.0.0.1:8080"
        echo ""
        
    else
        print_error "Could not determine the assigned port for the frontend service."
        echo ""
        echo "This could mean:"
        echo "  1. The frontend service is not running"
        echo "  2. The service is still starting up"
        echo "  3. There was an error during startup"
        echo ""
        echo "Try running:"
        echo "  ./setup-mac-m4.sh status"
        echo ""
        return 1
    fi
}

# Function to show container logs
show_logs() {
    local service="${1:-frontend}"
    print_status "Showing logs for $service service..."
    echo ""
    
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        logs --tail=20 "$service"
}

# Function to show all available commands
show_help() {
    echo ""
    echo "🔧 Frappe Docker Helper Commands"
    echo "==============================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (no args)  Show access URL and service status"
    echo "  status     Show detailed service status"
    echo "  logs       Show frontend service logs"
    echo "  logs <svc> Show logs for specific service"
    echo "  health     Check service health"
    echo "  help       Show this help message"
    echo ""
    echo "Available services:"
    echo "  frontend, backend, websocket, configurator"
    echo "  queue-short, queue-long, scheduler"
    echo ""
}

# Function to check service health
check_health() {
    print_status "Performing health check..."
    echo ""
    
    # Get the assigned port
    ASSIGNED_PORT=$(docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        port frontend 8080 2>/dev/null | cut -d: -f2)
    
    if [ -n "$ASSIGNED_PORT" ]; then
        print_status "Testing HTTP connectivity..."
        
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$ASSIGNED_PORT" || echo "000")
        
        case $HTTP_CODE in
            200|302)
                print_success "Service is healthy (HTTP $HTTP_CODE)"
                ;;
            404)
                print_warning "Service is responding but may need setup (HTTP $HTTP_CODE)"
                ;;
            000)
                print_error "Service is not responding"
                ;;
            *)
                print_warning "Service responded with HTTP $HTTP_CODE"
                ;;
        esac
    else
        print_error "Cannot perform health check - service port not found"
    fi
    
    echo ""
    print_status "Container health status:"
    docker compose \
        -f compose.yaml \
        -f overrides/compose.mac-m4.yaml \
        ps --format "table {{.Name}}\t{{.Status}}"
}

# Main execution
main() {
    echo ""
    echo "🔍 Frappe Docker Access Helper for Mac M4"
    echo "========================================="
    echo ""
    
    check_docker
    check_services
    get_service_status
    get_access_info
    
    echo ""
    echo "💡 Helpful commands:"
    echo "   View logs: $0 logs"
    echo "   Check health: $0 health"
    echo "   Service status: $0 status"
    echo ""
}

# Handle script arguments
case "${1:-}" in
    "status")
        check_docker
        get_service_status
        ;;
    "logs")
        check_docker
        show_logs "${2:-frontend}"
        ;;
    "health")
        check_docker
        check_health
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        main
        ;;
esac