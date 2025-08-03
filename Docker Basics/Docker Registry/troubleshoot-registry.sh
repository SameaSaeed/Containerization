#!/bin/bash

echo "=== Docker Registry Troubleshooting Guide ==="

echo -e "\n1. Check if registry container is running:"
docker ps | grep registry || echo "No registry container found!"

echo -e "\n2. Check registry logs:"
echo "Recent registry logs:"
docker logs --tail 10 registry-configured 2>/dev/null || echo "Cannot access registry logs"

echo -e "\n3. Test registry connectivity:"
curl -k https://localhost:5000/v2/ 2>/dev/null && echo "Registry is accessible" || echo "Registry connection failed"

echo -e "\n4. Check certificate validity:"
openssl x509 -in /opt/docker-registry/certs/domain.crt -text -noout | grep "Not After" || echo "Cannot read certificate"

echo -e "\n5. Verify authentication file:"
[ -f /opt/docker-registry/auth/htpasswd ] && echo "Auth file exists" || echo "Auth file missing"

echo -e "\n6. Check disk space:"
df -h /opt/docker-registry/

echo -e "\n7. Test Docker daemon configuration:"
[ -f /etc/docker/certs.d/localhost:5000/ca.crt ] && echo "Docker certificate configured" || echo "Docker certificate missing"

echo -e "\n8. Network connectivity test:"
netstat -tlnp | grep :5000 || echo "Registry port not listening"

echo "=== End Troubleshooting ==="