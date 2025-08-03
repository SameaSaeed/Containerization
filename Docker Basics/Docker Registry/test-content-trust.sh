#!/bin/bash

echo "Testing with content trust enabled..."
export DOCKER_CONTENT_TRUST=1
docker pull localhost:5000/my-nginx:v1.0 2>&1 | head -5

echo -e "\nTesting with --disable-content-trust flag..."
docker pull --disable-content-trust localhost:5000/my-nginx:v1.0 2>&1 | head -5

echo -e "\nTesting with content trust disabled..."
export DOCKER_CONTENT_TRUST=0
docker pull localhost:5000/my-nginx:v1.0 2>&1 | head -5