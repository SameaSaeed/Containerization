##### Docker Registry



1\.

\# Check Docker version and status

docker --version

docker info



\# Pull the official Docker registry image

docker pull registry:2



\# Create a directory for registry data persistence

sudo mkdir -p /opt/docker-registry/data

sudo mkdir -p /opt/docker-registry/certs

sudo mkdir -p /opt/docker-registry/auth



\# Set proper permissions

sudo chown -R $USER:$USER /opt/docker-registry



2\.

\# Run a simple registry on port 5000

docker run -d \\

&nbsp; --name registry-basic \\

&nbsp; --restart=always \\

&nbsp; -p 5000:5000 \\

&nbsp; -v /opt/docker-registry/data:/var/lib/registry \\

&nbsp; registry:2



\# Verify the registry is running

docker ps | grep registry-basic



\# Check registry health

curl http://localhost:5000/v2/



3\.

\# Pull a small test image

docker pull hello-world



\# Tag the image for your private registry

docker tag hello-world localhost:5000/hello-world



\# Push the image to your private registry

docker push localhost:5000/hello-world



\# Remove local images to test pull functionality

docker rmi hello-world localhost:5000/hello-world



\# Pull the image from your private registry

docker pull localhost:5000/hello-world



\# Verify the image works

docker run localhost:5000/hello-world



**Implementing Authentication and Security**



1\.

\# Navigate to the certs directory

cd /opt/docker-registry/certs



\# Generate a private key

openssl genrsa -out domain.key 4096



\# Generate a certificate signing request

openssl req -new -key domain.key -out domain.csr -subj "/C=US/ST=CA/L=San Francisco/O=MyOrg/CN=localhost"



\# Generate the self-signed certificate

openssl x509 -req -days 365 -in domain.csr -signkey domain.key -out domain.crt



\# Verify certificate creation

ls -la /opt/docker-registry/certs/



2\.

\# Install htpasswd utility if not available

sudo apt-get update

sudo apt-get install -y apache2-utils



\# Create authentication file with username 'testuser' and password 'testpass'

htpasswd -Bbn testuser testpass > /opt/docker-registry/auth/htpasswd



\# Verify the auth file

cat /opt/docker-registry/auth/htpasswd



3\.

\# Stop the basic registry

docker stop registry-basic

docker rm registry-basic



\# Start secure registry with authentication and TLS

docker run -d \\

&nbsp; --name registry-secure \\

&nbsp; --restart=always \\

&nbsp; -p 5000:5000 \\

&nbsp; -v /opt/docker-registry/data:/var/lib/registry \\

&nbsp; -v /opt/docker-registry/certs:/certs \\

&nbsp; -v /opt/docker-registry/auth:/auth \\

&nbsp; -e REGISTRY\_HTTP\_TLS\_CERTIFICATE=/certs/domain.crt \\

&nbsp; -e REGISTRY\_HTTP\_TLS\_PRIVATE\_KEY=/certs/domain.key \\

&nbsp; -e REGISTRY\_AUTH=htpasswd \\

&nbsp; -e REGISTRY\_AUTH\_HTPASSWD\_REALM="Registry Realm" \\

&nbsp; -e REGISTRY\_AUTH\_HTPASSWD\_PATH=/auth/htpasswd \\

&nbsp; registry:2



\# Verify the secure registry is running

docker ps | grep registry-secure



4\.

\# Create Docker daemon configuration directory

sudo mkdir -p /etc/docker/certs.d/localhost:5000



\# Copy the certificate to Docker's certificate directory

sudo cp /opt/docker-registry/certs/domain.crt /etc/docker/certs.d/localhost:5000/ca.crt



\# Restart Docker daemon to pick up the new certificate

sudo systemctl restart docker



\# Wait for Docker to restart

sleep 5



\# Verify Docker is running

docker info



###### **Testing Authenticated Registry Operations**



1\.

\# Login to the private registry

docker login localhost:5000



\# When prompted, enter:

\# Username: testuser

\# Password: testpass



\# Verify login was successful by checking Docker config

cat ~/.docker/config.json



2\.

\# Pull a sample application image

docker pull nginx:alpine



\# Tag it for your private registry

docker tag nginx:alpine localhost:5000/my-nginx:v1.0



\# Push to your private registry

docker push localhost:5000/my-nginx:v1.0



\# Create a custom image to push



\# Push custom image

docker push localhost:5000/my-custom-app:latest



\# List images in registry (using registry API)

curl -k -u testuser:testpass https://localhost:5000/v2/\_catalog



3\.

\# Remove local images

docker rmi localhost:5000/my-nginx:v1.0 localhost:5000/my-custom-app:latest



\# Pull images from private registry

docker pull localhost:5000/my-nginx:v1.0

docker pull localhost:5000/my-custom-app:latest



\# Test the pulled images

docker run --rm localhost:5000/my-custom-app:latest

docker run --rm -p 8080:80 -d --name test-nginx localhost:5000/my-nginx:v1.0



\# Test nginx is working

curl http://localhost:8080



\# Clean up test container

docker stop test-nginx

###### 

###### **Working with Content Trust Policies**



\# Create a script to demonstrate content trust bypass

./test-content-trust.sh



\# Create a registry configuration file for content trust

cat > /opt/docker-registry/config.yml



\# Restart registry with custom configuration

docker stop registry-secure

docker rm registry-secure



docker run -d \\

&nbsp; --name registry-configured \\

&nbsp; --restart=always \\

&nbsp; -p 5000:5000 \\

&nbsp; -v /opt/docker-registry/data:/var/lib/registry \\

&nbsp; -v /opt/docker-registry/certs:/certs \\

&nbsp; -v /opt/docker-registry/auth:/auth \\

&nbsp; -v /opt/docker-registry/config.yml:/etc/docker/registry/config.yml \\

&nbsp; registry:2



###### **Registry Storage Management and Best Practices**



a.

\# Check registry storage usage

du -sh /opt/docker-registry/data



\# List all repositories in the registry

curl -k -u testuser:testpass https://localhost:5000/v2/\_catalog | jq '.'



\# Get tags for a specific repository

curl -k -u testuser:testpass https://localhost:5000/v2/my-nginx/tags/list | jq '.'



\# Get detailed information about registry contents

find /opt/docker-registry/data -type f -name "\*.json" | head -10



b.

Create a registry cleanup script

\# Make script executable

chmod +x registry-cleanup.sh



\# Show storage before cleanup

echo "Storage before cleanup:"

du -sh /opt/docker-registry/data



\# Run cleanup (commented out to preserve lab data)

\# ./registry-cleanup.sh



\# Show storage after cleanup would run

echo "Cleanup script created and ready to use."



c.

Implementing Storage Limits and Policies

cat > /opt/docker-registry/config-advanced.yml



\# Create a monitoring script

./monitor-registry.sh



\# Create backup script

chmod +x backup-registry.sh



\# Create restore script

./backup-registry.sh

###### 

###### **Advanced Registry Features and Troubleshooting**



\# Create API testing script

./test-registry-api.sh



\# Create troubleshooting guide script

./troubleshoot-registry.sh



\# Create performance monitoring script

./performance-monitor.sh



\# Create comprehensive test script

./final-verification.sh

