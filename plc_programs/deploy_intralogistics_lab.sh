#!/bin/bash

# Intralogistics Lab CODESYS Deployment Script
# Deploys the complete logistics learning lab project to CODESYS runtime

echo "🚀 Deploying Intralogistics Learning Lab to CODESYS..."

# Check if CODESYS is running
if docker ps | grep -q codesys; then
    echo "✅ CODESYS container is running"
else
    echo "❌ CODESYS container not found. Starting CODESYS..."
    cd /Volumes/Berthold/Code/active/intralogisticsai
    ./deploy.sh lab
    sleep 30
fi

# Get CODESYS port
CODESYS_PORT=$(docker ps | grep codesys | sed 's/.*:\([0-9]*\)->8080.*/\1/')
if [ -z "$CODESYS_PORT" ]; then
    echo "❌ Could not determine CODESYS port"
    exit 1
fi

echo "🔧 CODESYS Web Interface: http://localhost:$CODESYS_PORT"

# Create deployment directory on CODESYS container
echo "📁 Creating deployment directory..."
docker exec codesys mkdir -p /tmp/intralogistics_lab

# Copy project files to CODESYS container
echo "📋 Copying CODESYS project files..."
docker cp plc_programs/codesys_project/ codesys:/tmp/intralogistics_lab/

# List copied files
echo "📄 Copied files:"
docker exec codesys ls -la /tmp/intralogistics_lab/codesys_project/

echo ""
echo "🎯 DEPLOYMENT COMPLETE!"
echo ""
echo "📋 Next Steps:"
echo "1. Open CODESYS Web Interface: http://localhost:$CODESYS_PORT"
echo "2. Login with default credentials (admin/admin)"
echo "3. Import project: /tmp/intralogistics_lab/codesys_project/IntralogisticsLab.project"
echo "4. Compile and download to runtime"
echo "5. Access HMI visualization screens"
echo ""
echo "📊 MODBUS Integration:"
echo "   • MODBUS TCP Server: localhost:502"
echo "   • ERP Integration: Coils 2000-2011 (bin selection)"
echo "   • Status Monitoring: Registers 100-320"
echo ""
echo "🔧 Manual Testing:"
echo "   • Use Manual Control HMI screen for testing"
echo "   • Check Safety & Diagnostics for system status"
echo "   • Monitor Main Overview for system operation"
echo ""
echo "📖 Documentation:"
echo "   • See plc_programs/codesys_project/README.md"
echo "   • Installation guide: plc_programs/codesys_project/INSTALLATION_GUIDE.md"