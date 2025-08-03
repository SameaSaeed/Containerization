#!/bin/bash

echo "=== Registry Monitoring Report ==="
echo "Date: $(date)"
echo

echo "Registry Container Status:"
docker ps | grep registry

echo -e "\nRegistry Storage Usage:"
du -sh /opt/docker-registry/data

echo -e "\nRegistry Repositories:"
curl -s -k -u testuser:testpass https://localhost:5000/v2/_catalog | jq -r '.repositories[]' 2>/dev/null || echo "No repositories found"

echo -e "\nRegistry Health Check:"
curl -s -k https://localhost:5000/v2/ > /dev/null && echo "Registry is healthy" || echo "Registry health check failed"

echo -e "\nDocker System Information:"
docker system df

echo "=== End of Report ==="