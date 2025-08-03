#!/bin/bash

echo "=== Test Results Analysis ==="
echo "Generated at: $(date)"
echo ""

# Check if test results directory exists
if [ ! -d "test-results" ]; then
    echo "❌ No test results directory found"
    echo "Please run the CI pipeline first"
    exit 1
fi

echo "📊 Test Results Summary"
echo "======================"

# Analyze Python test results
if [ -f "test-results/python-results.xml" ]; then
    echo "✅ Python test results found"
    PYTHON_TESTS=$(grep -o 'tests="[0-9]*"' test-results/python-results.xml | cut -d'"' -f2)
    PYTHON_FAILURES=$(grep -o 'failures="[0-9]*"' test-results/python-results.xml | cut -d'"' -f2)
    PYTHON_ERRORS=$(grep -o 'errors="[0-9]*"' test-results/python-results.xml | cut -d'"' -f2)
    
    echo "   Total tests: ${PYTHON_TESTS:-0}"
    echo "   Failures: ${PYTHON_FAILURES:-0}"
    echo "   Errors: ${PYTHON_ERRORS:-0}"
    echo "   Success rate: $(echo "scale=2; (${PYTHON_TESTS:-0} - ${PYTHON_FAILURES:-0} - ${PYTHON_ERRORS:-0}) * 100 / ${PYTHON_TESTS:-1}" | bc)%"
else
    echo "❌ Python test results not found"
fi

echo ""

# Analyze Node.js test results
if [ -f "test-results/nodejs-results.xml" ]; then
    echo "✅ Node.js test results found"
    NODEJS_TESTS=$(grep -o 'tests="[0-9]*"' test-results/nodejs-results.xml | cut -d'"' -f2)
    NODEJS_FAILURES=$(grep -o 'failures="[0-9]*"' test-results/nodejs-results.xml | cut -d'"' -f2)
    NODEJS_ERRORS=$(grep -o 'errors="[0-9]*"' test-results/nodejs-results.xml | cut -d'"' -f2)
    
    echo "   Total tests: ${NODEJS_TESTS:-0}"
    echo "   Failures: ${NODEJS_FAILURES:-0}"
    echo "   Errors: ${NODEJS_ERRORS:-0}"
    echo "   Success rate: $(echo "scale=2; (${NODEJS_TESTS:-0} - ${NODEJS_FAILURES:-0} - ${NODEJS_ERRORS:-0}) * 100 / ${NODEJS_TESTS:-1}" | bc)%"
else
    echo "❌ Node.js test results not found"
fi

echo ""
echo "📁 Available Result Files"
echo "========================"
ls -la test-results/ 2>/dev/null || echo "No files found"

echo ""
echo "🐳 Docker Images Status"
echo "======================"
docker images | grep -E "(python-ci-app|nodejs-ci-app)"

echo ""
echo "📦 Running Containers"
echo "===================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔍 Quick Application Tests"
echo "========================="

# Test Python app if running
# Test Python app if running
if docker ps | grep -q python-ci-app; then
    echo "🔗 Testing Python app endpoint..."
    PYTHON_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
    if [ "$PYTHON_RESPONSE" -eq 200 ]; then
        echo "✅ Python app is healthy (HTTP 200)"
    else
        echo "❌ Python app health check failed (HTTP $PYTHON_RESPONSE)"
    fi
else
    echo "⚠️ Python app container is not running"
fi

# Test Node.js app if running
if docker ps | grep -q nodejs-ci-app; then
    echo "🔗 Testing Node.js app endpoint..."
    NODEJS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
    if [ "$NODEJS_RESPONSE" -eq 200 ]; then
        echo "✅ Node.js app is healthy (HTTP 200)"
    else
        echo "❌ Node.js app health check failed (HTTP $NODEJS_RESPONSE)"
    fi
else
    echo "⚠️ Node.js app container is not running"
fi

echo ""
echo "✅ Test results analysis complete."