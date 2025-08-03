#!/bin/bash

# Docker-based Jenkins build monitor
echo "=== Jenkins Build Monitor ==="
echo "Monitoring Jenkins builds from Docker container..."

# Function to check Jenkins API
check_jenkins_status() {
    local jenkins_url="http://host.docker.internal:8080"
    local job_name="docker-ci-pipeline"
    
    echo "Checking Jenkins status..."
    
    # Get last build info
    curl -s "${jenkins_url}/job/${job_name}/lastBuild/api/json" | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f'Last Build: #{data[\"number\"]}')
    print(f'Status: {data[\"result\"] or \"RUNNING\"}')
    print(f'Duration: {data[\"duration\"]/1000:.1f}s')
    print(f'Timestamp: {data[\"timestamp\"]}')
except:
    print('Unable to fetch build information')
"
}

# Function to monitor Docker containers
monitor_containers() {
    echo -e "\n=== Active Docker Containers ==="
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n=== Docker Images ==="
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Function to check resource usage
check_resources() {
    echo -e "\n=== System Resources ==="
    echo "Docker System Info:"
    docker system df
    
    echo -e "\nContainer Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Main monitoring loop
while true; do
    clear
    echo "$(date): Jenkins Docker CI/CD Monitor"
    echo "======================================"
    
    check_jenkins_status
    monitor_containers
    check_resources
    
    echo -e "\nPress Ctrl+C to exit. Refreshing in 30 seconds..."
    sleep 30
done