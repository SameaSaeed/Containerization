#!/bin/bash

echo "=== Cleaning up Selenium Docker Test Environment ==="

# Stop and remove containers
echo "Stopping containers..."
docker-compose down

# Remove individual containers if they exist
docker stop selenium-chrome jenkins 2>/dev/null || true
docker rm selenium-chrome jenkins 2>/dev/null || true

# Clean up dangling images
echo "Cleaning up Docker images..."
docker image prune -f

# Clean up volumes (optional - uncomment if needed)
# docker volume prune -f

# Clean up networks
docker network prune -f

# Show remaining Docker resources
echo ""
echo "Remaining Docker resources:"
echo "Containers:"
docker ps -a
echo ""
echo "Images:"
docker images
echo ""
echo "Volumes:"
docker volume ls
echo ""

echo "Cleanup completed!"