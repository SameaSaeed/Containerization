#!/bin/bash
echo "=== Container Resource Monitoring ==="
echo "Timestamp: $(date)"
echo ""
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}"
echo ""
echo "=== Container Limits ==="
for container in tenant-a-container tenant-b-container tenant-c-container shared-database; do
    echo "Container: $container"
    docker inspect $container | grep -A 3 '"Memory":'
    echo ""
done