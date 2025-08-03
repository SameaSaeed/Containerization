#!/bin/bash

echo "=== Kubernetes Autoscaling Monitor ==="
echo "Press Ctrl+C to stop monitoring"
echo

while true; do
    clear
    echo "=== Current Time: $(date) ==="
    echo
    
    echo "=== HPA Status ==="
    kubectl get hpa web-app-hpa
    echo
    
    echo "=== Pod Count and Status ==="
    kubectl get pods -l app=web-app -o wide
    echo
    
    echo "=== Resource Usage ==="
    kubectl top pods -l app=web-app 2>/dev/null || echo "Metrics not ready yet..."
    echo
    
    echo "=== Deployment Status ==="
    kubectl get deployment web-app
    echo
    
    sleep 10
done