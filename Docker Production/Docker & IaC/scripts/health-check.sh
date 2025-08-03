#!/bin/bash

set -e

ENVIRONMENT=${1:-development}
MAX_RETRIES=30
RETRY_INTERVAL=5

echo "Running health checks for $ENVIRONMENT environment..."

case $ENVIRONMENT in
  "development")
    URLS=("http://localhost/health")
    ;;
  "staging")
    URLS=("http://localhost/health")
    ;;
  "production")
    URLS=("http://localhost:5001/health" "http://localhost:5002/health")
    ;;
esac

for url in "${URLS[@]}"; do
  echo "Checking $url..."
  
  for i in $(seq 1 $MAX_RETRIES); do
    if curl -f -s "$url" > /dev/null; then
      echo "✓ $url is healthy"
      break
    else
      if [ $i -eq $MAX_RETRIES ]; then
        echo "✗ $url failed health check after $MAX_RETRIES attempts"
        exit 1
      fi
      echo "Attempt $i/$MAX_RETRIES failed, retrying in ${RETRY_INTERVAL}s..."
      sleep $RETRY_INTERVAL
    fi
  done
done

echo "All health checks passed!"