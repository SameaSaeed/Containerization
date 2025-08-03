#!/bin/bash

echo "Testing Docker Restart Policies with Health Checks"
echo "=================================================="

containers=("no-restart-policy" "always-restart" "restart-on-failure" "restart-unless-stopped")
ports=(5003 5004 5005 5006)

# Function to make container unhealthy
make_unhealthy() {
    local port=$1
    local container=$2
    echo "Making $container unhealthy..."
    curl -s http://localhost:$port/make-unhealthy > /dev/null
}

# Function to check container status
check_status() {
    local container=$1
    local status=$(docker inspect $container --format='{{.State.Status}}' 2>/dev/null || echo "not found")
    local health=$(docker inspect $container --format='{{.State.Health.Status}}' 2>/dev/null || echo "no health check")
    local restart_count=$(docker inspect $container --format='{{.RestartCount}}' 2>/dev/null || echo "0")
    
    echo "$container: Status=$status, Health=$health, Restarts=$restart_count"
}

# Make all containers unhealthy
echo "Step 1: Making all containers unhealthy..."
for i in "${!containers[@]}"; do
    make_unhealthy ${ports[$i]} ${containers[$i]}
done

echo ""
echo "Step 2: Monitoring container behavior over time..."

# Monitor for 3 minutes
for minute in {1..3}; do
    echo ""
    echo "Minute $minute:"
    echo "----------"
    for container in "${containers[@]}"; do
        check_status $container
    done
    sleep 60
done

echo ""
echo "Test completed!"