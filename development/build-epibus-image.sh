#!/bin/bash

# Build custom Frappe image with ERPNext + EpiBus + EpiTag
# Uses local epibus (source of truth), clones Frappe/ERPNext from GitHub

set -e

echo "Building Frappe + ERPNext + EpiBus + EpiTag image..."

# Check if we're in the right directory
if [ ! -f "compose.yaml" ]; then
    echo "Error: Must be run from project root directory."
    exit 1
fi

# Check that local epibus directory exists
if [ ! -d "epibus" ]; then
    echo "Error: epibus directory not found. Restore it with: git restore epibus/"
    exit 1
fi

# Parse --no-cache flag if provided
NO_CACHE=""
if [[ "$*" == *"--no-cache"* ]]; then
    NO_CACHE="--no-cache"
    echo "Building with --no-cache"
fi

# Build the image
echo "Using local epibus + GitHub Frappe v15 + GitHub ERPNext v15 + GitHub EpiTag..."
docker build \
  $NO_CACHE \
  --build-arg FRAPPE_BRANCH=version-15 \
  --tag frappe-epibus:latest \
  --file images/layered/Containerfile \
  .

echo ""
echo "✓ Image built successfully: frappe-epibus:latest"
echo ""
echo "To use this image:"
echo "  export CUSTOM_IMAGE=frappe-epibus"
echo "  export CUSTOM_TAG=latest"
echo "  docker compose up -d"
