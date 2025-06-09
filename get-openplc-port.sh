#!/bin/bash

# Script to get the auto-generated OpenPLC web interface port
# Usage: ./get-openplc-port.sh

echo "OpenPLC Service Port Information:"
echo "================================="

# Detect if we're on Mac M4/ARM64 and set compose command accordingly
if [[ $(uname -m) == "arm64" ]] && [[ $(uname -s) == "Darwin" ]]; then
    COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.mac-m4.yaml"
    echo "Detected Mac M4/ARM64 system"
else
    COMPOSE_CMD="docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml"
    echo "Using standard configuration"
fi

# Check if OpenPLC service is running
if $COMPOSE_CMD ps openplc | grep -q "Up"; then
    # Get the auto-generated port for web interface
    WEB_PORT=$($COMPOSE_CMD ps openplc | grep "8080/tcp" | sed 's/.*0.0.0.0:\([0-9]*\)->8080\/tcp.*/\1/')
    
    if [ -n "$WEB_PORT" ]; then
        echo "✅ OpenPLC Web Interface: http://localhost:$WEB_PORT"
    else
        echo "⚠️  OpenPLC web interface port not found (service may be starting)"
    fi
    
    echo "✅ OpenPLC MODBUS TCP: localhost:502"
    echo ""
    echo "Default Login:"
    echo "  Username: openplc"
    echo "  Password: openplc"
else
    echo "❌ OpenPLC service is not running"
    echo ""
    echo "To start the complete system with OpenPLC:"
    if [[ $(uname -m) == "arm64" ]] && [[ $(uname -s) == "Darwin" ]]; then
        echo "  docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml -f overrides/compose.mac-m4.yaml up -d"
    else
        echo "  docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml -f overrides/compose.openplc.yaml -f overrides/compose.plc-bridge.yaml up -d"
    fi
fi