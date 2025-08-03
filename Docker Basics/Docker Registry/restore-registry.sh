#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la /opt/docker-registry/backups/
    exit 1
fi

BACKUP_FILE=$1

echo "Restoring registry from backup: $BACKUP_FILE"

# Stop registry
docker stop registry-configured

# Backup current state
mv /opt/docker-registry/data /opt/docker-registry/data.old.$(date +%Y%m%d_%H%M%S)

# Restore from backup
tar -xzf "$BACKUP_FILE" -C /opt/docker-registry

# Restart registry
docker start registry-configured

echo "Registry restored successfully"