#!/bin/bash
echo "Starting load test on all tenant applications..."

# Test Tenant A
echo "Testing Tenant A (Python Flask)..."
for i in {1..10}; do
    curl -s http://localhost:8081 > /dev/null &
done

# Test Tenant B
echo "Testing Tenant B (Node.js)..."
for i in {1..10}; do
    curl -s http://localhost:8082 > /dev/null &
done

# Test Tenant C
echo "Testing Tenant C (Nginx)..."
for i in {1..10}; do
    curl -s http://localhost:8083 > /dev/null &
done

wait
echo "Load test completed. Check resource usage:"
docker stats --no-stream