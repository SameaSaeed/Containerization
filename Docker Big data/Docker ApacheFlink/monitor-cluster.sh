#!/bin/bash

echo "=== Flink Cluster Monitoring ==="
echo "Timestamp: $(date)"
echo ""

echo "=== Container Status ==="
docker-compose -f docker-compose-scaled.yml ps
echo ""

echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

echo "=== Running Jobs ==="
docker exec flink-jobmanager flink list -r
echo ""

echo "=== Task Manager Count ==="
echo "Active Task Managers: $(docker ps --filter "name=flink-taskmanager" --format "{{.Names}}" | wc -l)"
echo ""

echo "=== Disk Usage ==="
du -sh logs/ data/ jobs/
echo ""