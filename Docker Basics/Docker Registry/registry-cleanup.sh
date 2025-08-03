#!/bin/bash

echo "Registry cleanup starting..."

# Stop the registry
docker stop registry-configured

# Run garbage collection
docker run --rm \
  -v /opt/docker-registry/data:/var/lib/registry \
  registry:2 \
  garbage-collect /etc/docker/registry/config.yml

# Restart the registry
docker start registry-configured

echo "Registry cleanup completed."