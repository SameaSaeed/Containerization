
#!/bin/bash

# Update application script
VERSION=${1:-v1.1}
echo "Updating application to version: $VERSION"

# Build new version
docker build -t webapp-optimized:$VERSION -f Dockerfile.multistage .

# Tag for Harbor
docker tag webapp-optimized:$VERSION localhost/container-lab/webapp:$VERSION

# Push to Harbor
docker push localhost/container-lab/webapp:$VERSION

# Update Kubernetes deployment
kubectl set image deployment/webapp-deployment webapp=localhost/container-lab/webapp:$VERSION -n container-lab

# Wait for rollout to complete
kubectl rollout status deployment/webapp-deployment -n container-lab

echo "Application updated successfully to version: $VERSION"