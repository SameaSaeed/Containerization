#!/bin/bash

echo "=== Distributed Load Testing ==="
echo "Starting coordinated load tests from multiple containers..."
echo

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="distributed-results"

# Test 1: Simultaneous load from multiple Apache Bench containers
echo "=== Test 1: Simultaneous Apache Bench Tests ==="

# Start load generator 1
docker-compose -f docker-compose.distributed.yml exec -d loadgen1 \
    ab -n 2000 -c 20 http://loadbalancer/ > ${RESULTS_DIR}/loadgen1_${TIMESTAMP}.txt &

# Start load generator 3 (also Apache Bench)
docker-compose -f docker-compose.distributed.yml exec -d loadgen3 \
    ab -n 2000 -c 20 http://loadbalancer/ > ${RESULTS_DIR}/loadgen3_${TIMESTAMP}.txt &

# Start Siege from load generator 2
docker-compose -f docker-compose.distributed.yml exec -d loadgen2 \
    siege -c 15 -t 60s http://loadbalancer/ > ${RESULTS_DIR}/siege_${TIMESTAMP}.txt &

echo "All load generators started. Tests will run for approximately 60 seconds..."

# Wait for tests to complete
sleep 70

echo "Distributed load tests completed!"
echo

# Test 2: Sequential high-intensity tests
echo "=== Test 2: Sequential High-Intensity Tests ==="

# High concurrency test
docker-compose -f docker-compose.distributed.yml exec loadgen1 \
    ab -n 5000 -c 100 http://loadbalancer/ > ${RESULTS_DIR}/high_concurrency_${TIMESTAMP}.txt

echo "High concurrency test completed!"

# CPU intensive endpoint test
docker-compose -f docker-compose.distributed.yml exec loadgen2 \
    siege -c 10 -t 30s http://loadbalancer/cpu-intensive > ${RESULTS_DIR}/cpu_intensive_distributed_${TIMESTAMP}.txt

echo "CPU intensive distributed test completed!"
echo

echo "=== All distributed tests completed! ==="
echo "Results saved in: ${RESULTS_DIR}/"