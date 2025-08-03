#!/bin/bash

BLUE_URL="http://localhost:3001/health"
GREEN_URL="http://localhost:3002/health"
LB_URL="http://localhost/health"

echo "=== Health Monitoring ==="
echo "Timestamp: $(date)"
echo "========================"

# Check blue environment
echo -n "Blue Environment: "
if curl -f -s $BLUE_URL > /dev/null 2>&1; then
    echo "✓ HEALTHY"
    BLUE_STATUS=$(curl -s $BLUE_URL | jq -r '.status')
    echo "  Status: $BLUE_STATUS"
else
    echo "✗ UNHEALTHY"
fi

# Check green environment
echo -n "Green Environment: "
if curl -f -s $GREEN_URL > /dev/null 2>&1; then
    echo "✓ HEALTHY"
    GREEN_STATUS=$(curl -s $GREEN_URL | jq -r '.status')
    echo "  Status: $GREEN_STATUS"
else
    echo "✗ UNHEALTHY"
fi

# Check load balancer
echo -n "Load Balancer: "
if curl -f -s $LB_URL > /dev/null 2>&1; then
    echo "✓ HEALTHY"
else
    echo "✗ UNHEALTHY"
fi

echo "========================"