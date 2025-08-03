#!/bin/bash

set -e

CURRENT_ENV=${1:-green}
BACKUP_ENV=${2:-blue}

echo "=== Automatic Failover Script ==="
echo "Current Environment: $CURRENT_ENV"
echo "Backup Environment: $BACKUP_ENV"
echo "================================"

# Function to check environment health
check_health() {
    local env=$1
    local port
    
    if [ "$env" = "blue" ]; then
        port=3001
    else
        port=3002
    fi
    
    if curl -f -s http://localhost:$port/health > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check current environment health
if check_health $CURRENT_ENV; then
    echo "$CURRENT_ENV environment is healthy"
else
    echo "$CURRENT_ENV environment is unhealthy - initiating failover"
    
    # Check if backup environment is healthy
    if check_health $BACKUP_ENV; then
        echo "$BACKUP_ENV environment is healthy - switching traffic"
        ./scripts/switch-traffic.sh $BACKUP_ENV
        echo "Failover completed successfully"
    else
        echo "ERROR: Both environments are unhealthy!"
        exit 1
    fi
fi