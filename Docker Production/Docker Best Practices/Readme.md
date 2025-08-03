##### Docker and Production Best Practices



1\. Use light-weight base images like alpine

2\. Integrate health checks

3\. Configure Automatic Restart Policies



\# Stop any running containers

docker stop prod-app 2>/dev/null || true

docker rm prod-app 2>/dev/null || true



\# Run with restart policy: always

docker run -d --name prod-app-always \\

  --restart=always \\

  -p 3001:3000 \\

  production-app:healthcheck



\# Run with restart policy: unless-stopped

docker run -d --name prod-app-unless-stopped \\

  --restart=unless-stopped \\

  -p 3002:3000 \\

  production-app:healthcheck



\# Run with restart policy: on-failure with max retries

docker run -d --name prod-app-on-failure \\

  --restart=on-failure:3 \\

  -p 3003:3000 \\

  production-app:healthcheck

Test restart functionality:

\# Check container status

docker ps



\# Simulate container failure

docker kill prod-app-always



\# Wait and check if it restarted

sleep 5

docker ps



\# Check restart count

docker inspect prod-app-always | grep -A 5 "RestartCount"



4\. Configure Memory and CPU Limits

Create containers with resource limits:

\# Stop previous containers

docker stop $(docker ps -q) 2>/dev/null || true

docker rm $(docker ps -aq) 2>/dev/null || true



\# Run container with memory limit (256MB)

docker run -d --name app-memory-limit \\

  --memory=256m \\

  --memory-swap=256m \\

  -p 3000:3000 \\

  production-app:alpine



\# Run container with CPU limit (0.5 CPU cores)

docker run -d --name app-cpu-limit \\

  --cpus=0.5 \\

  -p 3001:3000 \\

  production-app:alpine



\# Run container with both memory and CPU limits

docker run -d --name app-resource-limits \\

  --memory=512m \\

  --memory-swap=512m \\

  --cpus=1.0 \\

  --restart=unless-stopped \\

  -p 3002:3000 \\

  production-app:alpine

Monitor resource usage:

\# Check resource usage

docker stats --no-stream



\# Get detailed resource information

docker inspect app-resource-limits | grep -A 10 "HostConfig"



5\. Configure docker-compose with resource limits



\# Deploy the stack

docker-compose -f docker-compose.prod.yml up -d



\# Check resource usage

docker stats --no-stream



\# Test the application through Nginx

curl http://localhost/

curl http://localhost/health



6\. Use Logging and Monitoring Tools (ELK Stack and Prometheus)



a.

\# Start ELK stack

docker-compose -f docker-compose.elk.yml up -d



\# Wait for services to start

sleep 60



\# Check if Elasticsearch is running

curl http://localhost:9200



\# Check Kibana (may take a few minutes to start)

echo "Kibana will be available at: http://localhost:5601"



b.

\# Start monitoring stack

docker-compose -f docker-compose.monitoring.yml up -d



\# Wait for services to start

sleep 30



\# Check Prometheus

curl http://localhost:9090



\# Access Grafana at http://localhost:3001 (admin/admin123)

echo "Grafana available at: http://localhost:3001"

echo "Username: admin"

echo "Password: admin123"



7\. Secure Docker Containers using Docker Bench and Content Trust



a.

Install and run Docker Bench for Security:

\# Create security directory

mkdir ~/security

cd ~/security



\# Download Docker Bench for Security

git clone https://github.com/docker/docker-bench-security.git

cd docker-bench-security



\# Run Docker Bench Security scan

sudo ./docker-bench-security.sh



\# Save results to file

sudo ./docker-bench-security.sh > docker-bench-results.txt 2>\&1



\# Review critical findings

grep -A 5 -B 5 "WARN\\|FAIL" docker-bench-results.txt | head -50



b.

\# Create secure Docker daemon configuration

sudo mkdir -p /etc/docker



sudo tee /etc/docker/daemon.json << 'EOF'

{

  "icc": false,

  "userns-remap": "default",

  "log-driver": "json-file",

  "log-opts": {

    "max-size": "10m",

    "max-file": "3"

  },

  "live-restore": true,

  "userland-proxy": false,

  "no-new-privileges": true

}

EOF



\# Restart Docker daemon

sudo systemctl restart docker



\# Verify configuration

docker info | grep -A 10 "Security Options"



c.

Implement Content Trust



\# Enable Content Trust

export DOCKER\_CONTENT\_TRUST=1



\# Generate delegation keys

docker trust key generate mykey



\# Create a repository for signed images

docker tag production-app:alpine localhost:5000/production-app:signed



\# Note: For full content trust, you would need a Docker registry with notary



\## Build secure image

docker build -f Dockerfile.secure -t production-app:secure .



d. Implement Runtime Security

\# Deploy secure application

docker-compose -f docker-compose.secure.yml up -d



\# Test security

docker exec -it $(docker ps -q -f "name=web") sh -c "whoami"

docker exec -it $(docker ps -q -f "name=web") sh -c "id"



\# Test application functionality

curl http://localhost:3000

curl http://localhost:3000/health



e. Security scanning with Trivy:

\# Install Trivy for vulnerability scanning

sudo apt-get update

sudo apt-get install wget apt-transport-https gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -

echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb\_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

sudo apt-get update

sudo apt-get install trivy -y



\# Scan the secure image

trivy image production-app:secure



\# Generate detailed report

trivy image --format json --output security-report.json production-app:secure



\# Check for high and critical vulnerabilities

trivy image --severity HIGH,CRITICAL production-app:secure



8\. Comprehensive Testing



chmod +x test-production-setup.sh

./test-production-setup.sh

Performance and load testing:

\# Install Apache Bench for load testing

sudo apt-get install apache2-utils -y



\# Run load test

echo "Running load test..."

ab -n 1000 -c 10 http://localhost:3000/



\# Monitor during load test

docker stats --no-stream



9\. Troubleshooting



a.

Issue 1: Container Memory Issues

\# Check memory usage

docker stats --no-stream



\# Increase memory limits if needed

docker update --memory=1g --memory-swap=1g container\_name



\# Check for memory leaks

docker exec container\_name cat /proc/meminfo



b.

Issue 2: Health Check Failures

\# Debug health check

docker inspect container\_name | grep -A 10 Health



\# Check health check logs

docker logs container\_name | grep health



\# Test health check manually

docker exec container\_name wget --spider http://localhost:3000/health



c.

Issue 3: Security Scan Issues

\# Update base images

docker pull node:18-alpine

docker build --no-cache -t production-app:secure .



\# Check for security updates

docker exec container\_name apk update \&\& apk upgrade



\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_



Build and test the production healthcheck container:

docker build -f Dockerfile.production -t healthcheck-app:production .

docker run -d --name production-app --restart=unless-stopped -p 5007:5000 healthcheck-app:production



###### **Troubleshooting** 



Issue 1: Health Check Always Fails

Symptoms: Container constantly restarts, health check never passes

Solutions:

Check if the application is actually listening on the specified port

Verify the health check URL is accessible

Increase the --start-period to allow more time for application startup

Check application logs: docker logs container-name



Issue 2: Health Check Takes Too Long

Symptoms: Health checks timeout frequently

Solutions:

Increase the --timeout value

Optimize the health check endpoint

Use a simpler health check (e.g., TCP check instead of HTTP)



Issue 3: Container Doesn't Restart When Unhealthy

Symptoms: Container becomes unhealthy but doesn't restart

Solutions:

Verify restart policy is configured: docker inspect container-name --format='{{.HostConfig.RestartPolicy}}'

Check if the health check is actually failing (exit code 1)

Ensure the container process exits when unhealthy

