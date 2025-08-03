#!/bin/bash

echo "=== Microservices Health Check ==="
echo "Timestamp: $(date)"
echo "=================================="

services=("user-service:3001" "product-service:3002" "order-service:3003")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d':' -f1)
    port=$(echo $service | cut -d':' -f2)
    
    echo -n "Checking $name... "
    
    if curl -s -f "http://localhost:$port/health" > /dev/null; then
        echo "✓ Healthy"
        # Get response time
        response_time=$(curl -s -w "%{time_total}" -o /dev/null "http://localhost:$port/health")
        echo "  Response time: ${response_time}s"
    else
        echo "✗ Unhealthy"
    fi
    echo
done

echo "=== Container Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo -e "\n=== Service Logs (Last 5 lines) ==="
for service in user-service product-service order-service; do
    echo "--- $service ---"
    docker logs --tail 5 $service 2>/dev/null || echo "Service not running"
    echo
done