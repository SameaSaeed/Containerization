###### **Docker with multi-tenant containers**



1. Build images



\# Build Tenant A image

cd ~/multi-tenant-docker/tenant-a

docker build -t tenant-a-app:v1.0 .



\# Build Tenant B image

cd ~/multi-tenant-docker/tenant-b

docker build -t tenant-b-app:v1.0 .



\# Build Tenant C image

cd ~/multi-tenant-docker/tenant-c

docker build -t tenant-c-app:v1.0 .



\# Verify images are built

docker images | grep tenant



2\. Deploy each application in its container:



\# Deploy Tenant A (Python Flask)

docker run -d \\

&nbsp; --name tenant-a-container \\

&nbsp; -p 8081:5000 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-a-app:v1.0



\# Deploy Tenant B (Node.js)

docker run -d \\

&nbsp; --name tenant-b-container \\

&nbsp; -p 8082:3000 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-b-app:v1.0



\# Deploy Tenant C (Nginx)

docker run -d \\

&nbsp; --name tenant-c-container \\

&nbsp; -p 8083:80 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-c-app:v1.0



\# Verify all containers are running

docker ps



3\. Test each application to ensure it's working correctly:



\# Test Tenant A

curl http://localhost:8081

curl http://localhost:8081/health



\# Test Tenant B

curl http://localhost:8082

curl http://localhost:8082/health



\# Test Tenant C

curl http://localhost:8083



\# Check container logs

docker logs tenant-a-container

docker logs tenant-b-container

docker logs tenant-c-container



###### **Use Different Network Modes to Ensure Isolation**



1. Stop existing containers and create isolated networks:



\# Stop all running containers

docker stop tenant-a-container tenant-b-container tenant-c-container

docker rm tenant-a-container tenant-b-container tenant-c-container



\# Create separate networks for each tenant

docker network create --driver bridge tenant-a-network

docker network create --driver bridge tenant-b-network

docker network create --driver bridge tenant-c-network



\# Create a shared network for inter-tenant communication (if needed)

docker network create --driver bridge shared-services-network



\# List all networks

docker network ls



2\. Redeploy applications using isolated networks:



\# Deploy Tenant A with isolated network

docker run -d \\

&nbsp; --name tenant-a-container \\

&nbsp; --network tenant-a-network \\

&nbsp; -p 8081:5000 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-a-app:v1.0



\# Deploy Tenant B with isolated network

docker run -d \\

&nbsp; --name tenant-b-container \\

&nbsp; --network tenant-b-network \\

&nbsp; -p 8082:3000 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-b-app:v1.0



\# Deploy Tenant C with isolated network

docker run -d \\

&nbsp; --name tenant-c-container \\

&nbsp; --network tenant-c-network \\

&nbsp; -p 8083:80 \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-c-app:v1.0



3\. Verify that containers cannot communicate with each other across different networks:



\# Test network isolation by trying to ping between containers

\# This should fail because they're on different networks



\# Get container IP addresses

docker inspect tenant-a-container | grep IPAddress

docker inspect tenant-b-container | grep IPAddress

docker inspect tenant-c-container | grep IPAddress



\# Try to ping from Tenant A to Tenant B (should fail)

docker exec tenant-a-container ping -c 3 tenant-b-container || echo "Network isolation working - ping failed as expected"



\# Verify applications still work externally

curl http://localhost:8081

curl http://localhost:8082

curl http://localhost:8083



4\. Create a shared database that multiple tenants can access through the shared network:



\# Create a PostgreSQL database container

docker run -d \\

&nbsp; --name shared-database \\

&nbsp; --network shared-services-network \\

&nbsp; -e POSTGRES\_DB=multitenantdb \\

&nbsp; -e POSTGRES\_USER=dbadmin \\

&nbsp; -e POSTGRES\_PASSWORD=securepassword123 \\

&nbsp; -p 5432:5432 \\

&nbsp; postgres:13



\# Connect Tenant A to the shared services network (multi-network container)

docker network connect shared-services-network tenant-a-container



\# Verify that Tenant A can reach the database

docker exec tenant-a-container ping -c 3 shared-database

###### 

###### **Implement Resource Limits for CPU and Memory Usage**



1. Stop Existing Containers and Redeploy with Resource Limits

docker stop tenant-a-container tenant-b-container tenant-c-container shared-database

docker rm tenant-a-container tenant-b-container tenant-c-container shared-database



2\.

Redeploy applications with specific resource constraints:



\# Deploy Tenant A with resource limits (512MB RAM, 0.5 CPU cores)

docker run -d \\

&nbsp; --name tenant-a-container \\

&nbsp; --network tenant-a-network \\

&nbsp; -p 8081:5000 \\

&nbsp; --memory="512m" \\

&nbsp; --cpus="0.5" \\

&nbsp; --memory-swap="512m" \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-a-app:v1.0



\# Deploy Tenant B with resource limits (256MB RAM, 0.3 CPU cores)

docker run -d \\

&nbsp; --name tenant-b-container \\

&nbsp; --network tenant-b-network \\

&nbsp; -p 8082:3000 \\

&nbsp; --memory="256m" \\

&nbsp; --cpus="0.3" \\

&nbsp; --memory-swap="256m" \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-b-app:v1.0



\# Deploy Tenant C with resource limits (128MB RAM, 0.2 CPU cores)

docker run -d \\

&nbsp; --name tenant-c-container \\

&nbsp; --network tenant-c-network \\

&nbsp; -p 8083:80 \\

&nbsp; --memory="128m" \\

&nbsp; --cpus="0.2" \\

&nbsp; --memory-swap="128m" \\

&nbsp; --restart unless-stopped \\

&nbsp; tenant-c-app:v1.0



\# Deploy shared database with higher limits (1GB RAM, 1 CPU core)

docker run -d \\

&nbsp; --name shared-database \\

&nbsp; --network shared-services-network \\

&nbsp; -e POSTGRES\_DB=multitenantdb \\

&nbsp; -e POSTGRES\_USER=dbadmin \\

&nbsp; -e POSTGRES\_PASSWORD=securepassword123 \\

&nbsp; -p 5432:5432 \\

&nbsp; --memory="1g" \\

&nbsp; --cpus="1.0" \\

&nbsp; --memory-swap="1g" \\

&nbsp; postgres:13



3\. Monitor the resource usage of containers:



\# Check resource usage statistics

docker stats --no-stream



\# Get detailed resource information for specific containers

docker inspect tenant-a-container | grep -A 10 "Memory"

docker inspect tenant-a-container | grep -A 5 "CpuShares"



chmod +x ~/multi-tenant-docker/monitor-resources.sh

~/multi-tenant-docker/monitor-resources.sh



chmod +x ~/multi-tenant-docker/load-test.sh

~/multi-tenant-docker/load-test.sh



###### **Use Docker Compose to Manage Multi-Tenant Applications**



1. Create files



Create docker-compose

Create a database initialization script

Create Nginx configuration for reverse proxy



2\. Deploy Using Docker Compose



\# Stop and remove existing containers

docker stop $(docker ps -aq) 2>/dev/null || true

docker rm $(docker ps -aq) 2>/dev/null || true



\# Deploy using Docker Compose

cd ~/multi-tenant-docker

docker-compose up -d



\# Check the status of all services

docker-compose ps



\# View logs from all services

docker-compose logs --tail=20



3\. Test the multi-tenant application deployment:



\# Test individual tenant applications

curl http://localhost:8091  # Tenant A

curl http://localhost:8092  # Tenant B

curl http://localhost:8093  # Tenant C



\# Test reverse proxy

curl http://localhost/tenant-a

curl http://localhost/tenant-b

curl http://localhost/tenant-c

curl http://localhost/



\# Test database connectivity

docker-compose exec shared-database psql -U dbadmin -d multitenantdb -c "\\dt tenant\_a.\*"

docker-compose exec shared-database psql -U dbadmin -d multitenantdb -c "SELECT \* FROM tenant\_a.users;"



\# Check health status

docker-compose exec tenant-a curl -f http://localhost:5000/health

docker-compose exec tenant-b curl -f http://localhost:3000/health



###### **Set Up Inter-Container Communication and Access Control**



1. **Create API Gateway**



\# Create API gateway application

\# Create requirements.txt

\# Create Dockerfile for API Gateway

\# Update the Docker Compose file to include the API gateway after Backingup existing docker-compose.yml

cp docker-compose.yml docker-compose.yml.backup





**2. Implement Database Access Control**

