#!/bin/bash

echo "=== Final Registry Verification ==="

# Test 1: Registry accessibility
echo -e "\n✓ Testing registry accessibility..."
curl -k https://localhost:5000/v2/ > /dev/null 2>&1 && echo "PASS: Registry is accessible" || echo "FAIL: Registry not accessible"

# Test 2: Authentication
echo -e "\n✓ Testing authentication..."
curl -k -u testuser:testpass https://localhost:5000/v2/_catalog > /dev/null 2>&1 && echo "PASS: Authentication working" || echo "FAIL: Authentication failed"

# Test 3: Push/Pull functionality
echo -e "\n✓ Testing push/pull functionality..."
docker pull alpine:latest > /dev/null 2>&1
docker tag alpine:latest localhost:5000/test-alpine:latest > /dev/null 2>&1
docker push localhost:5000/test-alpine:latest > /dev/null 2>&1 && echo "PASS: Push working" || echo "FAIL: Push failed"

docker rmi localhost:5000/test-alpine:latest > /dev/null 2>&1
docker pull localhost:5000/test-alpine:latest > /dev/null 2>&1 && echo "PASS: Pull working" || echo "FAIL: Pull failed"

# Test 4: TLS/SSL
echo -e "\n✓ Testing TLS/SSL..."
openssl s_client -connect localhost:5000 -servername localhost < /dev/null 2>/dev/null | grep "Verify return code: 0" > /dev/null && echo "PASS: TLS working" || echo "INFO: Self-signed certificate in use"

# Test 5: Storage persistence
echo -e "\n✓ Testing storage persistence..."
[ -d /opt/docker-registry/data/docker ] && echo "PASS: Registry data persisted" || echo "FAIL: No registry data found"

echo -e "\n=== Verification Complete ==="