#!/bin/bash

set -e

PREVIOUS_TAG=${1:-previous}
ENVIRONMENT=${2:-development}

echo "Rolling back to $PREVIOUS_TAG in $ENVIRONMENT environment..."

case $ENVIRONMENT in
  "development")
    # Update docker-compose to use previous tag
    sed -i "s/docker-iac-web:latest/docker-iac-web:$PREVIOUS_TAG/g" ../docker-compose.yml
    docker-compose up -d --no-deps web
    ;;
  "production")
    echo "Rolling back Terraform deployment..."
    cd ../infrastructure
    terraform apply -auto-approve
    ;;
esac

echo "Rollback completed!"