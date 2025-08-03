#!/bin/bash

echo "=== Registry Performance Monitoring ==="

echo -e "\n1. Container resource usage:"
docker stats --no-stream registry-configured 2>/dev/null || echo "Cannot get container stats"

echo -e "\n2. Registry response time test:"
time curl -s -k -u testuser:testpass https://localhost:5000/v2/_catalog > /dev/null

echo -e "\n3. Storage I/O statistics:"
iostat -x 1 1 2>/dev/null | tail -n +4 || echo "iostat not available"

echo -e "\n4. Memory usage:"
free -h

echo -e "\n5. Registry data directory size:"
du -sh /opt/docker-registry/data

echo "=== End Performance Report ==="