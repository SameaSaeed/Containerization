#!/bin/bash

echo "=== Docker CI Pipeline Execution ==="
echo "Starting at: $(date)"

# Set environment variables
export DOCKER_COMPOSE_FILE="docker-compose.yml"
export TEST_RESULTS_DIR="test-results"

# Stage 1: Checkout
echo ""
echo "Stage 1: Checkout"
echo "=================="
echo "Source code checked out successfully"

# Stage 2: Build Images
echo ""
echo "Stage 2: Build Images"
echo "===================="
docker-compose build

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build Docker images"
    exit 1
fi

# Stage 3: Run Tests
echo ""
echo "Stage 3: Run Tests"
echo "=================="

echo "Running Python tests..."
docker-compose run --rm python-tests
PYTHON_TEST_RESULT=$?

echo "Running Node.js tests..."
docker-compose run --rm nodejs-tests
NODEJS_TEST_RESULT=$?

# Stage 4: Collect Test Results
echo ""
echo "Stage 4: Collect Test Results"
echo "============================="
echo "Test results directory contents:"
ls -la test-results/ 2>/dev/null || echo "No test results directory found"

# Stage 5: Deploy to Staging (if tests passed)
if [ $PYTHON_TEST_RESULT -eq 0 ] && [ $NODEJS_TEST_RESULT -eq 0 ]; then
    echo ""
    echo "Stage 5: Deploy to Staging"
    echo "=========================="
    echo "All tests passed. Deploying applications..."
    
    docker-compose up -d python-app nodejs-app
    
    echo "Waiting for applications to start..."
    sleep 15
    
    echo "Running health checks..."
    
    # Test Python app
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "✓ Python app health check passed"
    else
        echo "✗ Python app health check failed"
    fi
    
    # Test Node.js app
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✓ Node.js app health check passed"
    else
        echo "✗ Node.js app health check failed"
    fi
    
    echo ""
    echo "Applications are running:"
    echo "Python app: http://localhost:5000"
    echo "Node.js app: http://localhost:3000"
    
else
    echo ""
    echo "Tests failed. Skipping deployment."
    echo "Python tests result: $PYTHON_TEST_RESULT"
    echo "Node.js tests result: $NODEJS_TEST_RESULT"
fi

echo ""
echo "=== Pipeline Completed at: $(date) ==="
