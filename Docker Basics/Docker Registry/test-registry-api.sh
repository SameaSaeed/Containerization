#!/bin/bash

REGISTRY_URL="https://localhost:5000"
AUTH="testuser:testpass"

echo "=== Docker Registry API Testing ==="

echo -e "\n1. Check registry version:"
curl -s -k -u $AUTH $REGISTRY_URL/v2/ | jq '.' 2>/dev/null || echo "Registry API accessible"

echo -e "\n2. List all repositories:"
curl -s -k -u $AUTH $REGISTRY_URL/v2/_catalog | jq '.repositories[]' 2>/dev/null

echo -e "\n3. Get tags for my-nginx repository:"
curl -s -k -u $AUTH $REGISTRY_URL/v2/my-nginx/tags/list | jq '.' 2>/dev/null

echo -e "\n4. Get manifest for my-nginx:v1.0:"
curl -s -k -u $AUTH \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  $REGISTRY_URL/v2/my-nginx/manifests/v1.0 | jq '.schemaVersion' 2>/dev/null

echo -e "\n5. Registry statistics:"
echo "Total repositories: $(curl -s -k -u $AUTH $REGISTRY_URL/v2/_catalog | jq '.repositories | length' 2>/dev/null)"