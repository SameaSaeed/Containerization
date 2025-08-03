#!/bin/bash

# Function to get container health info
get_health_info() {
    local container_name=$1
    
    if docker ps -q -f name="$container_name" > /dev/null 2>&1; then
        local status=$(docker inspect $container_name --format='{{.State.Status}}')
        local health_status=$(docker inspect $container_name --format='{{.State.Health.Status}}')
        local failing_streak=$(docker inspect $container_name --format='{{.State.Health.FailingStreak}}')
        
        echo "Container: $container_name"
        echo "  Status: $status"
        echo "  Health: $health_status"
        echo "  Failing Streak: $failing_streak"
        
        # Show recent health check logs
        echo "  Recent Health Checks:"
        docker inspect $container_name --format='{{range .State.Health.Log}}    {{.Start}} | Exit: {{.ExitCode}} | {{.Output}}{{end}}' | tail -3
        echo ""
    else
        echo "Container: $container_name - NOT RUNNING"
        echo ""
    fi
}

# Clear screen and show header
clear
echo "=========================================="
echo "    Docker Health Check Dashboard"
echo "=========================================="
echo "Timestamp: $(date)"
echo ""

# Monitor all containers with health checks
for container in $(docker ps --format '{{.Names}}'); do
    # Check if container has health check configured
    if docker inspect $container --format='{{.Config.Healthcheck}}' | grep -q 'Test'; then
        get_health_info $container
    fi
done

echo "=========================================="