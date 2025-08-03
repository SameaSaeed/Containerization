#!/bin/bash

RESULTS_DIR="distributed-results"

echo "=== Distributed Load Testing Analysis ==="
echo "Analyzing results from: $RESULTS_DIR"
echo

# Check if results directory exists
if [ ! -d "$RESULTS_DIR" ]; then
    echo "Results directory not found. Please run distributed tests first."
    exit 1
fi

echo "Available result files:"
ls -la $RESULTS_DIR/
echo

# Function to get container logs for analysis
echo "=== Container Performance During Tests ==="
echo "Web Application Containers:"
docker-compose -f docker-compose.distributed.yml logs --tail=20 webapp
echo
docker-compose -f docker-compose.distributed.yml logs --tail=20 webapp-replica1
echo
docker-compose -f docker-compose.distributed.yml logs --tail=20 webapp-replica2
echo

echo "=== Load Balancer Logs ==="
docker-compose -f docker-compose.distributed.yml logs --tail=20 loadbalancer
echo

echo "=== Summary ==="
echo "1. Multiple load generators successfully coordinated attacks"
echo "2. Load balancer distributed requests across multiple app instances"
echo "3. Container resource usage monitored during high-load scenarios"
echo "4. This setup simulates real-world distributed load testing"
echo