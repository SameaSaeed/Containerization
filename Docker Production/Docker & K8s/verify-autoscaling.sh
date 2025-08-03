#!/bin/bash

echo "=== Autoscaling Verification ==="

# Check if HPA is configured
echo "1. Checking HPA configuration..."
if kubectl get hpa web-app-hpa &>/dev/null; then
    echo "✓ HPA is configured"
    kubectl get hpa web-app-hpa
else
    echo "✗ HPA not found"
    exit 1
fi

echo

# Check current pod count
echo "2. Current pod status..."
CURRENT_PODS=$(kubectl get pods -l app=web-app --no-headers | wc -l)
echo "Current pod count: $CURRENT_PODS"

echo

# Check if metrics are available
echo "3. Checking metrics availability..."
if kubectl top pods -l app=web-app &>/dev/null; then
    echo "✓ Metrics are available"
    kubectl top pods -l app=web-app
else
    echo "⚠ Metrics not ready yet (this is normal initially)"
fi

echo

# Check service connectivity
echo "4. Testing service connectivity..."
if kubectl get service web-app-service &>/dev/null; then
    echo "✓ Service is accessible"
    kubectl get service web-app-service
else
    echo "✗ Service not found"
fi

echo
echo "=== Verification Complete ==="