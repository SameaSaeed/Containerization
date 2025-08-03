#!/bin/bash

set -e

ENVIRONMENT=${1:-development}
ACTION=${2:-deploy}

echo "Starting $ACTION for $ENVIRONMENT environment..."

case $ENVIRONMENT in
  "development")
    echo "Deploying to development with docker-compose..."
    docker-compose up -d
    ;;
  "staging")
    echo "Deploying to staging with docker-compose..."
    docker-compose -f docker-compose.staging.yml up -d
    ;;
  "production")
    echo "Deploying to production with Terraform..."
    cd ../infrastructure
    terraform init
    terraform apply -auto-approve
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "Deployment completed successfully!"