#!/bin/bash

echo "=== Docker Service Update Monitor ==="
echo "Starting monitoring at $(date)"
echo "======================================"

# Function to check service status
check_service_status() {
    echo -e "\n--- Service Status ---"
    docker service ls
    
    echo -e "\n--- Service Tasks ---"
    docker service ps webapp --no-trunc
    
    echo -e "\n--- Service Details ---"
    docker service inspect webapp --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
}

# Function to test application availability
test_availability() {
    echo -e "\n--- Availability Test ---"
    for i in {1..5}; do
        response=$(curl -s -w "%{http_code}" http://localhost:8080 -o /dev/null)
        if [ "$response" = "200" ]; then
            version=$(curl -s http://localhost:8080 | grep -o 'Version [0-9.]*' | head -1)
            echo "Test $i: SUCCESS - $version"
        else
            echo "Test $i: FAILED - HTTP $response"
        fi
        sleep 1
    done
}

# Main monitoring loop
while true; do
    clear
    echo "=== Update Monitor - $(date) ==="
    check_service_status
    test_availability
    echo -e "\n--- Press Ctrl+C to stop monitoring ---"
    sleep 10
done