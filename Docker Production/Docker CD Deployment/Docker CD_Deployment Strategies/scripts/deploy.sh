#!/bin/bash

set -e

ENVIRONMENT=${1:-blue}
ACTION=${2:-deploy}

echo "=== Blue-Green Deployment Script ==="
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo "=================================="

case $ACTION in
    "deploy")
        echo "Deploying $ENVIRONMENT environment..."
        docker-compose -f docker-compose.$ENVIRONMENT.yml up -d --build
        echo "Waiting for $ENVIRONMENT environment to be healthy..."
        sleep 10
        
        # Health check
        if [ "$ENVIRONMENT" = "blue" ]; then
            PORT=3001
        else
            PORT=3002
        fi
        
        for i in {1..30}; do
            if curl -f http://localhost:$PORT/health > /dev/null 2>&1; then
                echo "$ENVIRONMENT environment is healthy!"
                break
            fi
            echo "Waiting for $ENVIRONMENT environment... ($i/30)"
            sleep 2
        done
        ;;
    "stop")
        echo "Stopping $ENVIRONMENT environment..."
        docker-compose -f docker-compose.$ENVIRONMENT.yml down
        ;;
    "status")
        echo "Status of $ENVIRONMENT environment:"
        docker-compose -f docker-compose.$ENVIRONMENT.yml ps
        ;;
    *)
        echo "Usage: $0 {blue|green} {deploy|stop|status}"
        exit 1
        ;;
esac