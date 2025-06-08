#!/bin/bash

# Script to get the auto-generated OpenPLC web interface port
# Usage: ./get-openplc-port.sh

echo "OpenPLC Service Port Information:"
echo "================================="

# Check if OpenPLC service is running
if docker-compose -f compose.yaml -f overrides/compose.openplc.yaml ps openplc | grep -q "Up"; then
    # Get the auto-generated port for web interface
    WEB_PORT=$(docker-compose -f compose.yaml -f overrides/compose.openplc.yaml ps openplc | grep "8080/tcp" | sed 's/.*0.0.0.0:\([0-9]*\)->8080\/tcp.*/\1/')
    
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
    echo "To start OpenPLC:"
    echo "  docker-compose -f compose.yaml -f overrides/compose.openplc.yaml up -d"
fi