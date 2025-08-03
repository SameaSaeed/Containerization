#!/bin/bash

echo "Docker Container Health Monitor"
echo "==============================="

containers=("healthcheck-advanced" "failing-container")

for container in "${containers[@]}"; do
    if docker ps -q -f name="$container" > /dev/null 2>&1; then
        echo ""
        echo "Container: $container"
        echo "Status: $(docker inspect $container --format='{{.State.Status}}')"
        echo "Health Status: $(docker inspect $container --format='{{.State.Health.Status}}')"
        echo "Failed Health Checks: $(docker inspect $container --format='{{len .State.Health.Log}}')"
        
        # Show last health check result
        echo "Last Health Check:"
        docker inspect $container --format='{{range .State.Health.Log}}{{.Start}} - {{.ExitCode}} - {{.Output}}{{end}}' | tail -1
    else
        echo "Container $container is not running"
    fi
done