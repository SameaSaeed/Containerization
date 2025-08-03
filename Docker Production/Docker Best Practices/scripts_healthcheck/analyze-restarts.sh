#!/bin/bash

echo "Docker Restart Policy Analysis"
echo "=============================="

containers=("no-restart-policy" "always-restart" "restart-on-failure" "restart-unless-stopped")

for container in "${containers[@]}"; do
    echo ""
    echo "Container: $container"
    echo "Restart Policy: $(docker inspect $container --format='{{.HostConfig.RestartPolicy.Name}}:{{.HostConfig.RestartPolicy.MaximumRetryCount}}')"
    echo "Current Status: $(docker inspect $container --format='{{.State.Status}}')"
    echo "Health Status: $(docker inspect $container --format='{{.State.Health.Status}}')"
    echo "Restart Count: $(docker inspect $container --format='{{.RestartCount}}')"
    echo "Started At: $(docker inspect $container --format='{{.State.StartedAt}}')"
    
    # Show restart history if available
    echo "Exit Code: $(docker inspect $container --format='{{.State.ExitCode}}')"
    echo "----------------------------------------"
done

echo ""
echo "Summary of Restart Policies:"
echo "- no-restart-policy: Container stops when unhealthy, no restart"
echo "- always-restart: Container restarts regardless of exit code"
echo "- restart-on-failure: Container restarts only on non-zero exit codes"
echo "- restart-unless-stopped: Container restarts unless manually stopped"