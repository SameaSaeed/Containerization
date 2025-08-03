#!/bin/bash

echo "=== GitLab CI Pipeline Simulation ==="
echo "Starting at: $(date)"

# Simulate GitLab CI environment variables
export CI=true
export GITLAB_CI=true
export CI_PIPELINE_ID="12345"
export CI_JOB_ID="67890"

# Stage: Build
echo ""
echo "🔨 Stage: Build"
echo "==============="
echo "Building Docker images..."
docker-compose build

if [ $? -ne 0 ]; then
    echo "❌ Build stage failed"
    exit 1
fi

echo "✅ Build stage completed successfully"

# Stage: Test - Python
echo ""
echo "🧪 Stage: Test - Python"
echo "======================="
echo "Running Python tests..."
docker-compose run --rm python-tests
PYTHON_EXIT_CODE=$?

if [ $PYTHON_EXIT_CODE -eq 0 ]; then
    echo "✅ Python tests passed"
else
    echo "❌ Python tests failed"
fi

# Stage: Test - Node.js
echo ""
echo "🧪 Stage: Test - Node.js"
echo "======================="
echo "Running Node.js tests..."
docker-compose run --rm nodejs-tests
NODEJS_EXIT_CODE=$?

if [ $NODEJS_EXIT_CODE -eq 0 ]; then
    echo "✅ Node.js tests passed"
else
    echo "❌ Node.js tests failed"
fi

# Stage: Deploy (only if all tests pass)
if [ $PYTHON_EXIT_CODE -eq 0 ] && [ $NODEJS_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🚀 Stage: Deploy"
    echo "==============="
    echo "All tests passed. Deploying to staging..."
    
    docker-compose up -d python-app nodejs-app
    
    echo "Waiting for applications to start..."
    sleep 15
    
    echo "Running health checks..."
    
    # Health check for Python app
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "✅ Python app health check passed"
        PYTHON_HEALTH=0
    else
        echo "❌ Python app health check failed"
        PYTHON_HEALTH=1
    fi
    
    # Health check for Node.js app
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Node.js app health check passed"
        NODEJS_HEALTH=0
    else
        echo "❌ Node.js app health check failed"
        NODEJS_HEALTH=1
    fi
    
    if [ $PYTHON_HEALTH -eq 0 ] && [ $NODEJS_HEALTH -eq 0 ]; then
        echo "✅ Deployment successful"
        echo ""
        echo "🌐 Applications are now running:"
        echo "   Python app: http://localhost:5000"
        echo "   Node.js app: http://localhost:3000"
    else
        echo "❌ Deployment health checks failed"
    fi
    
else
    echo ""
    echo "❌ Tests failed. Skipping deployment stage."
    echo "   Python tests: $([ $PYTHON_EXIT_CODE -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
    echo "   Node.js tests: $([ $NODEJS_EXIT_CODE -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
fi

# Cleanup
echo ""
echo "🧹 Cleanup"
echo "========="
echo "Cleaning up resources..."
# Note: Keeping containers running for demonstration
# docker-compose down || true
# docker system prune -f || true

echo ""
echo "=== GitLab CI Pipeline Completed at: $(date) ==="

# Show final status
if [ $PYTHON_EXIT_CODE -eq 0 ] && [ $NODEJS_EXIT_CODE -eq 0 ]; then
    echo "🎉 Pipeline Status: SUCCESS"
    exit 0
else
    echo "💥 Pipeline Status: FAILED"
    exit 1
fi