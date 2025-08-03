#!/bin/bash

echo "=== Simulating CI Pipeline Performance Tests ==="
echo "This script simulates the GitHub Actions workflow locally"
echo

# Set up environment
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CI_RESULTS_DIR="ci-simulation-${TIMESTAMP}"
mkdir -p ${CI_RESULTS_DIR}

echo "Results will be saved to: ${CI_RESULTS_DIR}"
echo

# Step 1: Build images
echo "Step 1: Building Docker images..."
docker build -f Dockerfile.webapp -t test-webapp:ci . > ${CI_RESULTS_DIR}/build.log 2>&1
docker build -f Dockerfile.ab -t apache-bench:ci . >> ${CI_RESULTS_DIR}/build.log 2>&1
docker build -f Dockerfile.siege -t siege-bench:ci . >> ${CI_RESULTS_DIR}/build.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Docker images built successfully"
else
    echo "❌ Failed to build Docker images"
    exit 1
fi

# Step 2: Create network and start application
echo "Step 2: Starting test environment..."
docker network create ci-perf-network > /dev/null 2>&1

docker run -d \
    --name test-webapp-ci \
    --network ci-perf-network \
    -p 3001:3000 \
    test-webapp:ci

# Wait for application to be ready
echo "Waiting for application to start..."
sleep 10

# Health check
for i in {1..5}; do
    if curl -s http://localhost:3001/ > /dev/null; then
        echo "✅ Application is ready"
        break
    else
                echo "Waiting for application... (attempt $i)"
        sleep 5
    fi
    if [ "$i" -eq 5 ]; then
        echo "❌ Application failed to start"
        docker logs test-webapp-ci > ${CI_RESULTS_DIR}/webapp.log
        exit 1
    fi
done

# Step 3: Run Apache Bench tests
echo "Step 3: Running Apache Bench tests..."
docker run --rm \
    --network ci-perf-network \
    apache-bench:ci -n 1000 -c 50 http://test-webapp-ci:3000/ > ${CI_RESULTS_DIR}/ab_results.txt

echo "✅ Apache Bench test completed"

# Step 4: Run Siege tests
echo "Step 4: Running Siege load tests..."
docker run --rm \
    --network ci-perf-network \
    siege-bench:ci -c50 -t30S http://test-webapp-ci:3000/ > ${CI_RESULTS_DIR}/siege_results.txt

echo "✅ Siege test completed"

# Step 5: Cleanup
echo "Step 5: Cleaning up..."
docker stop test-webapp-ci > /dev/null
docker rm test-webapp-ci > /dev/null
docker network rm ci-perf-network > /dev/null

echo
echo "=== CI Pipeline Simulation Complete ==="
echo "Results saved in directory: ${CI_RESULTS_DIR}"
