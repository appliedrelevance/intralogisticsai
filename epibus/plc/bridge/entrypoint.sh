#!/bin/bash

# Ensure scripts directory exists
mkdir -p /app/scripts

# Copy any built-in scripts to the shared volume (if they don't exist)
if [ -d "/app/built-in-scripts" ]; then
    cp -n /app/built-in-scripts/* /app/scripts/ 2>/dev/null || true
fi

# Start the PLC bridge service (no API keys needed for guest endpoints)
echo "🚀 Starting PLC Bridge with guest API access"
python bridge.py --frappe-url "$FRAPPE_URL" --poll-interval "${PLC_POLL_INTERVAL:-1.0}"