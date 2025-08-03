#!/bin/bash

BACKUP_DIR="/opt/docker-registry/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="registry_backup_${TIMESTAMP}.tar.gz"

echo "Creating registry backup..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Stop registry for consistent backup
docker stop registry-configured

# Create compressed backup
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
  -C /opt/docker-registry \
  data auth certs config.yml config-advanced.yml

# Restart registry
docker start registry-configured

echo "Backup created: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "Backup size: $(du -sh ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)"