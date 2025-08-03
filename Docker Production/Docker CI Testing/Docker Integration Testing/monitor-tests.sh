#!/bin/bash

# Monitor test results script
echo "=== Docker CI Integration Test Monitor ==="
echo "Timestamp: $(date)"
echo

# Check if containers are running
echo "=== Container Status ==="
docker-compose -f docker-compose.test.yml ps
echo

# Check application health
echo "=== Application Health ==="
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✓ Application is healthy"
    curl -s http://localhost:3000/health | jq .
else
    echo "✗ Application is not responding"
fi
echo

# Check database connectivity
echo "=== Database Status ==="
if curl -s http://localhost:3000/db-status > /dev/null; then
    echo "✓ Database is connected"
    curl -s http://localhost:3000/db-status | jq .
else
    echo "✗ Database connection failed"
fi
echo

# Show recent logs
echo "=== Recent Application Logs ==="
docker-compose -f docker-compose.test.yml logs --tail=10 app
echo

echo "=== Recent Test Logs ==="
docker-compose -f docker-compose.test.yml logs --tail=10 tests
echo

# Resource usage
echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"