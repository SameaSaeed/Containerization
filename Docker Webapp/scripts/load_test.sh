#!/bin/bash

echo "Starting load test..."
echo "Testing main page..."

for i in {1..10}; do
    echo "Request $i:"
    curl -s -w "Time: %{time_total}s, Status: %{http_code}\n" http://localhost/ > /dev/null
    sleep 1
done

echo "Testing health endpoint..."
for i in {1..5}; do
    echo "Health check $i:"
    curl -s http://localhost/health | jq '.status'
    sleep 1
done

echo "Load test completed!"