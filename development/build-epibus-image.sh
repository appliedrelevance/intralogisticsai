#!/bin/bash

# Build custom Frappe image with EpiBus included
# This script follows the custom-apps.md documentation

set -e

echo "Building custom Frappe Docker image with EpiBus..."

# Check if we're in the right directory 
if [ ! -f "compose.yaml" ]; then
    echo "Error: Must be run from frappe_docker project directory."
    echo "Usage: cd frappe_docker && ./development/build-epibus-image.sh"
    exit 1
fi

# Create apps.json with EpiBus
cat > apps-epibus-build.json << EOF
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/appliedrelevance/epibus",
    "branch": "main"
  }
]
EOF

echo "Created apps.json for build:"
cat apps-epibus-build.json

# Generate base64 encoded apps.json - with better cross-platform compatibility
if command -v base64 >/dev/null 2>&1; then
    # Try different base64 command formats for different systems
    if base64 --help 2>&1 | grep -q "\-w"; then
        # GNU base64 (Linux)
        export APPS_JSON_BASE64=$(base64 -w 0 apps-epibus-build.json)
    elif base64 --help 2>&1 | grep -q "\-i"; then
        # BSD base64 (macOS)
        export APPS_JSON_BASE64=$(base64 -i apps-epibus-build.json)
    else
        # Standard base64
        export APPS_JSON_BASE64=$(cat apps-epibus-build.json | base64 | tr -d '\n')
    fi
else
    echo "Error: base64 command not found"
    exit 1
fi

echo "Base64 encoded apps.json:"
echo "$APPS_JSON_BASE64"

# Test decode - with better error handling
echo "Verifying base64 encoding:"
if echo "$APPS_JSON_BASE64" | base64 -d > /dev/null 2>&1; then
    echo "Base64 encoding verified successfully"
    echo "$APPS_JSON_BASE64" | base64 -d
else
    echo "Error: Base64 encoding verification failed"
    exit 1
fi

# Build custom image using layered approach for faster builds
echo "Building custom image with EpiBus..."

# Detect architecture and set platform
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    PLATFORM="--platform=linux/arm64"
else
    PLATFORM="--platform=linux/amd64"
fi

docker build \
  $PLATFORM \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-15 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=frappe-epibus:latest \
  --file=images/layered/Containerfile \
  .

echo "Custom image built successfully: frappe-epibus:latest"
echo ""
echo "To use this image, set these environment variables:"
echo "export CUSTOM_IMAGE=frappe-epibus"
echo "export CUSTOM_TAG=latest"
echo "export PULL_POLICY=never"
echo ""
echo "Then run:"
echo "docker compose -f compose.yaml -f overrides/compose.mariadb.yaml -f overrides/compose.redis.yaml up -d"