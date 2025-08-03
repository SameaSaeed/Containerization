#!/bin/bash

# Performance Benchmarking Script
echo "=== Docker Performance Benchmarking Lab ==="
echo "Starting comprehensive performance tests..."
echo

# Test configuration
WEBAPP_URL="http://test-webapp:3000"
NETWORK="performance-test-network"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="results_${TIMESTAMP}"

# Create results directory
mkdir -p ${RESULTS_DIR}

echo "Results will be saved to: ${RESULTS_DIR}"
echo

# Test 1: Apache Bench - Basic Load Test
echo "=== Test 1: Apache Bench Basic Load Test ==="
docker run --rm \
    --network ${NETWORK} \
    apache-bench:latest \
    ab -n 1000 -c 10 ${WEBAPP_URL}/ > ${RESULTS_DIR}/ab_basic.txt

echo "Basic load test completed. Results saved to ${RESULTS_DIR}/ab_basic.txt"
echo

# Test 2: Apache Bench - High Concurrency Test
echo "=== Test 2: Apache Bench High Concurrency Test ==="
docker run --rm \
    --network ${NETWORK} \
    apache-bench:latest \
    ab -n 2000 -c 50 ${WEBAPP_URL}/ > ${RESULTS_DIR}/ab_high_concurrency.txt

echo "High concurrency test completed. Results saved to ${RESULTS_DIR}/ab_high_concurrency.txt"
echo

# Test 3: Apache Bench - CPU Intensive Endpoint
echo "=== Test 3: Apache Bench CPU Intensive Test ==="
docker run --rm \
    --network ${NETWORK} \
    apache-bench:latest \
    ab -n 200 -c 10 ${WEBAPP_URL}/cpu-intensive > ${RESULTS_DIR}/ab_cpu_intensive.txt

echo "CPU intensive test completed. Results saved to ${RESULTS_DIR}/ab_cpu_intensive.txt"
echo

# Test 4: Siege - Sustained Load Test
echo "=== Test 4: Siege Sustained Load Test ==="
docker run --rm \
    --network ${NETWORK} \
    siege-bench:latest \
    siege -c 20 -t 60s ${WEBAPP_URL}/ > ${RESULTS_DIR}/siege_sustained.txt

echo "Sustained load test completed. Results saved to ${RESULTS_DIR}/siege_sustained.txt"
echo

# Test 5: Container Resource Monitoring
echo "=== Test 5: Container Resource Monitoring ==="
echo "Monitoring container resources during load test..."

# Start monitoring in background
docker stats test-webapp --no-stream > ${RESULTS_DIR}/container_stats.txt &
STATS_PID=$!

# Run a load test while monitoring
docker run --rm \
    --network ${NETWORK} \
    apache-bench:latest \
    ab -n 1500 -c 25 ${WEBAPP_URL}/ > ${RESULTS_DIR}/ab_with_monitoring.txt

# Stop monitoring
kill $STATS_PID 2>/dev/null

echo "Resource monitoring completed. Results saved to ${RESULTS_DIR}/container_stats.txt"
echo

echo "=== All tests completed! ==="
echo "Check the ${RESULTS_DIR} directory for detailed results."