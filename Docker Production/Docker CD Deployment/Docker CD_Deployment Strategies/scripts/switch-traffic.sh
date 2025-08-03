#!/bin/bash

set -e

TARGET_ENV=${1:-blue}

echo "=== Traffic Switching Script ==="
echo "Switching traffic to: $TARGET_ENV"
echo "==============================="

if [ "$TARGET_ENV" != "blue" ] && [ "$TARGET_ENV" != "green" ]; then
    echo "Error: Environment must be 'blue' or 'green'"
    exit 1
fi

# Copy the appropriate nginx configuration
cp nginx/conf/nginx-$TARGET_ENV.conf nginx/conf/nginx.conf

# Reload nginx configuration
docker exec nginx-lb nginx -s reload

echo "Traffic switched to $TARGET_ENV environment"

# Verify the switch
echo "Testing new configuration..."
sleep 2
RESPONSE=$(curl -s http://localhost | jq -r '.environment' 2>/dev/null || echo "Could not parse response")
echo "Current active environment: $RESPONSE"