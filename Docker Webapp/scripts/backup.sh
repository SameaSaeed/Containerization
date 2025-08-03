#!/bin/bash

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup application data
docker run --rm \
  -v flask-docker-app_app-data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar czf /backup/app-data-$TIMESTAMP.tar.gz -C /data .

# Backup Redis data
docker run --rm \
  -v flask-docker-app_redis-data:/data \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine tar czf /backup/redis-data-$TIMESTAMP.tar.gz -C /data .

echo "Backup completed: $TIMESTAMP"
ls -la $BACKUP_DIR/