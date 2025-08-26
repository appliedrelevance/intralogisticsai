#!/bin/bash
# Deploy Simple CODESYS Program to Runtime Container
# This script attempts to deploy a basic PLC program to activate MODBUS server

echo "🚀 Deploying Simple CODESYS Program..."

# Check if CODESYS container is running
if ! docker compose ps codesys | grep -q "running"; then
    echo "❌ CODESYS container is not running. Start with ./dev.sh first."
    exit 1
fi

echo "📋 Copying program files to container..."
# Copy our simple ST program to the container
docker compose exec codesys mkdir -p /plc_programs/simple
docker compose cp plc_programs/simple_modbus_server.st codesys:/plc_programs/simple/

echo "🔍 Exploring CODESYS runtime structure..."
# Investigate the container structure
docker compose exec codesys find /opt -name "*.xml" -o -name "*.pro" -o -name "*project*" 2>/dev/null | head -10
docker compose exec codesys find /data -type d 2>/dev/null | head -10

echo "📁 Checking PlcLogic directory..."
docker compose exec codesys ls -la /data/PlcLogic/ 2>/dev/null || echo "PlcLogic directory not found"

echo "🔧 Attempting to create minimal project structure..."
# Create basic project structure that CODESYS runtime might recognize
docker compose exec codesys sh -c "cat > /data/PlcLogic/Application.st << 'EOF'
PROGRAM PLC_PRG
VAR
    Conveyor1_Run AT %QX0.0: BOOL := FALSE;
    Conveyor1_Status AT %IX0.0: BOOL := FALSE;
    Test_Counter: INT := 0;
END_VAR

Test_Counter := Test_Counter + 1;
IF Test_Counter > 1000 THEN
    Test_Counter := 0;
END_IF

Conveyor1_Status := Conveyor1_Run;

END_PROGRAM
EOF"

echo "📊 Checking CODESYS control service status..."
docker compose exec codesys ps aux | grep -i codesys || echo "No CODESYS processes found"

echo "🌐 Testing MODBUS port accessibility..."
# Test if MODBUS port 502 is accessible
if nc -z localhost 502; then
    echo "✅ MODBUS TCP port 502 is accessible"
else
    echo "❌ MODBUS TCP port 502 is not accessible"
fi

echo "📝 Container logs (last 20 lines):"
docker compose logs --tail=20 codesys

echo "🏁 Deployment attempt completed. Check container logs for any runtime startup messages."
echo "   If MODBUS server is active, you should be able to connect to localhost:502"