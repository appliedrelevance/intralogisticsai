#!/bin/bash

# IntralogisticsAI Health Check Script
# Usage: ./scripts/health-check.sh [--verbose] [--format json|text]

set -e

# Default settings
VERBOSE=false
FORMAT="text"
EXIT_CODE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --format|-f)
            FORMAT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--format json|text]"
            echo "  --verbose    Show detailed output"
            echo "  --format     Output format (json or text)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    if [[ "$VERBOSE" == "true" ]] || [[ "$FORMAT" == "text" ]]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    EXIT_CODE=1
}

# Health check results
declare -A CHECKS
TOTAL_CHECKS=0
PASSED_CHECKS=0

run_check() {
    local name="$1"
    local command="$2"
    local description="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Running: $description"
    fi
    
    if eval "$command" >/dev/null 2>&1; then
        CHECKS["$name"]="PASS"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        if [[ "$VERBOSE" == "true" ]]; then
            log_info "✅ $description"
        fi
    else
        CHECKS["$name"]="FAIL"
        log_error "❌ $description"
    fi
}

# Container health checks
log_info "Checking container health..."

run_check "containers_running" \
    "docker compose ps --services --filter 'status=running' | wc -l | grep -q '[1-9]'" \
    "Docker containers are running"

run_check "database_healthy" \
    "docker compose exec -T db mysqladmin ping --silent" \
    "Database is responsive"

run_check "backend_healthy" \
    "docker compose exec -T backend bench --version" \
    "Backend service is healthy"

run_check "frontend_responding" \
    "curl -f -s -o /dev/null http://localhost:\$(docker compose ps frontend --format '{{.Ports}}' | grep -o '0\.0\.0\.0:[0-9]*' | cut -d: -f2 | head -1)/" \
    "Frontend web server responding"

# Service-specific checks
if docker compose ps --services | grep -q openplc; then
    log_info "Checking OpenPLC services..."
    
    run_check "openplc_web_responding" \
        "timeout 5 curl -f -s -o /dev/null http://localhost:8081/" \
        "OpenPLC web interface responding"
    
    run_check "modbus_tcp_accessible" \
        "timeout 3 bash -c 'echo > /dev/tcp/localhost/502'" \
        "MODBUS TCP port 502 accessible"
fi

if docker compose ps --services | grep -q plc-bridge; then
    log_info "Checking PLC Bridge services..."
    
    run_check "plc_bridge_responding" \
        "timeout 5 curl -f -s -o /dev/null http://localhost:7654/health" \
        "PLC Bridge health endpoint responding"
fi

# Application-level checks
log_info "Checking application health..."

# Get the site name (could be intralogistics.lab, intralogistics.localhost, or a web domain)
SITE_NAME=$(docker compose exec -T backend ls /home/frappe/frappe-bench/sites | grep -v assets | grep -v common | grep -v apps | head -1)
SITE_NAME=$(echo "$SITE_NAME" | tr -d '\r\n')

if [[ -n "$SITE_NAME" ]]; then
    run_check "site_accessible" \
        "docker compose exec -T backend bench --site '$SITE_NAME' list-apps" \
        "Frappe site '$SITE_NAME' accessible"
    
    run_check "database_connected" \
        "docker compose exec -T backend bench --site '$SITE_NAME' console --execute 'frappe.db.sql(\"SELECT 1\")'" \
        "Database connection working"
    
    run_check "erpnext_installed" \
        "docker compose exec -T backend bench --site '$SITE_NAME' list-apps | grep -q erpnext" \
        "ERPNext app is installed"
    
    if docker compose exec -T backend bench --site "$SITE_NAME" list-apps | grep -q epibus; then
        run_check "epibus_installed" \
            "docker compose exec -T backend bench --site '$SITE_NAME' list-apps | grep -q epibus" \
            "EpiBus app is installed"
    fi
else
    log_warn "No Frappe site found - skipping application checks"
fi

# Resource usage checks
log_info "Checking resource usage..."

MEMORY_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" | grep -o '[0-9.]*GiB' | head -1 | cut -d'G' -f1)
if [[ -n "$MEMORY_USAGE" ]] && (( $(echo "$MEMORY_USAGE > 6" | bc -l) )); then
    log_warn "High memory usage: ${MEMORY_USAGE}GiB"
fi

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
if [[ "$DISK_USAGE" -gt 80 ]]; then
    log_warn "High disk usage: ${DISK_USAGE}%"
fi

# Output results
if [[ "$FORMAT" == "json" ]]; then
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"total_checks\": $TOTAL_CHECKS,"
    echo "  \"passed_checks\": $PASSED_CHECKS,"
    echo "  \"health_score\": $(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc),"
    echo "  \"status\": \"$([ $EXIT_CODE -eq 0 ] && echo 'healthy' || echo 'unhealthy')\","
    echo "  \"checks\": {"
    first=true
    for check in "${!CHECKS[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        echo -n "    \"$check\": \"${CHECKS[$check]}\""
    done
    echo ""
    echo "  }"
    echo "}"
else
    echo ""
    echo "🏥 IntralogisticsAI Health Check Report"
    echo "======================================"
    echo "Timestamp: $(date)"
    echo "Health Score: $PASSED_CHECKS/$TOTAL_CHECKS ($(echo "scale=0; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)%)"
    echo ""
    
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}🎉 System is healthy!${NC}"
    else
        echo -e "${RED}⚠️  System has health issues${NC}"
        echo ""
        echo "Failed checks:"
        for check in "${!CHECKS[@]}"; do
            if [[ "${CHECKS[$check]}" == "FAIL" ]]; then
                echo "  - $check"
            fi
        done
    fi
    
    echo ""
    echo "Quick fixes:"
    echo "  - Restart unhealthy services: docker compose restart"
    echo "  - Check logs: docker compose logs [service-name]"
    echo "  - Full system restart: ./deploy.sh stop && ./deploy.sh [deployment-type]"
fi

exit $EXIT_CODE