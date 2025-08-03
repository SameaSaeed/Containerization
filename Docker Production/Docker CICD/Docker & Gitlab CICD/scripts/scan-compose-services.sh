#!/bin/bash

# Script to scan all docker-compose services
set -e

echo "Scanning all docker-compose services..."

# Extract service images from docker-compose.yml
SERVICES=$(docker-compose config --services)

for service in $SERVICES; do
    echo "Scanning service: $service"
    
    # Get the image for this service
    IMAGE=$(docker-compose config | grep -A 10 "^  $service:" | grep "image:" | awk '{print $2}' | head -1)
    
    if [ ! -z "$IMAGE" ]; then
        echo "Scanning image: $IMAGE"
        trivy image --exit-code 0 --severity HIGH,CRITICAL --format table $IMAGE
        echo "---"
    else
        echo "Service $service uses build context, skipping image scan"
    fi
done

echo "All service scans completed!"