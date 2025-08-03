#!/bin/bash

set -e

IMAGE_TAG=${1:-latest}
ENVIRONMENT=${2:-development}
STRATEGY=${3:-rolling}

echo "Updating containers to $IMAGE_TAG in $ENVIRONMENT environment using $STRATEGY strategy..."

case $STRATEGY in
  "rolling")
    echo "Performing rolling update..."
    case $ENVIRONMENT in
      "development")
        docker-compose pull
        docker-compose up -d --no-deps web
        ;;
      "production")
        # Update containers one by one
        containers=$(docker ps --format "table {{.Names}}" | grep "terraform-web" | tail -n +2)
        for container in $containers; do
          echo "Updating $container..."
          docker stop "$container"
          docker rm "$container"
          # Terraform will recreate the container
          cd ../infrastructure
          terraform apply -auto-approve
          sleep 10
        done
        ;;
    esac
    ;;
  "blue-green")
    echo "Performing blue-green deployment..."
    # Create new version alongside existing
    docker-compose -f docker-compose.blue-green.yml up -d
    echo "New version deployed. Manual verification required before switching traffic."
    ;;
esac

echo "Update completed!"