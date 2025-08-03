#!/bin/bash

set -e

SERVICE=${1:-web}
REPLICAS=${2:-3}
ENVIRONMENT=${3:-development}

echo "Scaling $SERVICE to $REPLICAS replicas in $ENVIRONMENT environment..."

case $ENVIRONMENT in
  "development")
    echo "Scaling with docker-compose..."
    docker-compose up -d --scale $SERVICE=$REPLICAS
    ;;
  "production")
    echo "Scaling with Terraform..."
    cd ../infrastructure
    terraform apply -var="web_replicas=$REPLICAS" -auto-approve
    ;;
  *)
    echo "Manual scaling for $ENVIRONMENT..."
    for i in $(seq 1 $REPLICAS); do
      container_name="${ENVIRONMENT}-${SERVICE}-${i}"
      if ! docker ps -q -f name="$container_name" | grep -q .; then
        echo "Starting $container_name..."
        docker run -d \
          --name "$container_name" \
          --network "${ENVIRONMENT}-network" \
          -p "$((5000 + i)):5000" \
          docker-iac-web:latest
      fi
    done
    ;;
esac

echo "Scaling completed!"