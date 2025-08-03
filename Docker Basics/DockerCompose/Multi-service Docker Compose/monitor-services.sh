#!/bin/bash

# monitor-services.sh - Real-time service monitoring

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check service health
check_service_health() {
    local service=$1
    local url=$2
    
    if curl -f "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $service"
        return 0
    else
        echo -e "${RED}✗${NC} $service"
        return 1
    fi
}

# Function to display service status
display_status() {
    clear
    echo "=== Multi-Service Application Health Monitor ==="
    echo "Last updated: $(date)"
        echo ""
    
    # Define services to monitor
    check_service_health "Web App" "http://localhost:8080/health"
    check_service_health "API Server" "http://localhost:5000/health"
    check_service_health "Database Admin Panel" "http://localhost:8081"

    echo ""
    echo "Press Ctrl+C to stop monitoring."
}

# Monitor loop
while true; do
    display_status
    sleep 5
done
