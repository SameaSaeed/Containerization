#!/bin/bash

echo "Container Resource Usage Monitoring"
echo "=================================="

while true; do
    echo "Timestamp: $(date)"
    echo "Docker Container Stats:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    echo ""
    
    echo "Host System Resources:"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "=================================="
    sleep 5
done