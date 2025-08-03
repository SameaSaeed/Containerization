###### **Build and Deploy the Services**



\# Build and start all services

docker-compose up --build -d

The -d flag runs containers in detached mode (in the background).



\#Verify Container Deployment

Check that both containers are running:



\# Check running containers

docker-compose ps



\# Test backend health from within the frontend container

docker exec frontend-web wget -qO- http://backend:3001/health



\# Test API endpoint

docker exec frontend-web wget -qO- http://backend:3001/api/users



###### **Set Up Environment Variables for Container Communication**



\# Update files with env

Update docker-compose with env 

Update server.js with env



\# Stop current services

docker-compose down



\# Rebuild and start with new configuration

docker-compose up --build -d



\# Test environment information

curl http://localhost:3001/api/env



###### **Test Connectivity and Troubleshoot Using Docker Network Inspect**



\# Inspect the network to see connected containers

docker network inspect microservices-net



\# Test ping between containers using container names

docker exec frontend-web ping -c 3 backend



\# Test ping using IP addresses (use the IPs from network inspect)

docker exec frontend-web ping -c 3 172.18.0.2



\# Test HTTP connectivity

docker exec frontend-web wget -qO- http://backend:3001/health



\# Test from backend to frontend

docker exec backend-api wget -qO- http://frontend:80



\# Test DNS resolution

docker exec frontend-web nslookup backend

docker exec backend-api nslookup frontend



\# View container logs to see network activity

docker-compose logs backend

docker-compose logs frontend



\# Follow logs in real-time

docker-compose logs -f backend

Press Ctrl+C to stop following logs.



\# Test backend directly

curl http://localhost:3001/health

curl http://localhost:3001/api/users



\# Test frontend (open in browser or use curl)

curl http://localhost:8080

For browser testing: Open your web browser and navigate to:



Frontend: http://localhost:8080

Backend API: http://localhost:3001/health



###### **Advanced Network Troubleshooting**



\#Check if containers are on the correct network

docker inspect backend-api | grep NetworkMode

docker inspect frontend-web | grep NetworkMode



\# List all networks and their containers

docker network ls

for network in $(docker network ls --format "{{.Name}}"); do

&nbsp;   echo "=== Network: $network ==="

&nbsp;   docker network inspect $network --format "{{range .Containers}}{{.Name}} {{end}}"

done



\# Check container network settings

docker exec backend-api ip addr show

docker exec frontend-web ip addr show



\# Test port connectivity

docker exec frontend-web nc -zv backend 3001



###### **Performance Testing**



\# Time multiple requests

time for i in {1..10}; do

&nbsp;   docker exec frontend-web wget -qO- http://backend:3001/health > /dev/null

done



\# Test concurrent requests

docker exec frontend-web ab -n 100 -c 10 http://backend:3001/health



###### **Network Management**



**a. Useful Docker Network Commands**



\# Create different types of networks

docker network create --driver bridge my-bridge-network

docker network create --driver host my-host-network



\# Connect/disconnect containers to networks

docker network connect microservices-net container-name

docker network disconnect microservices-net container-name



\# Remove unused networks

docker network prune



\# Remove specific network (containers must be stopped first)

docker network rm microservices-net

Container Communication Patterns



**b. Test different communication patterns**



\# 1. Container name resolution

docker exec frontend-web wget -qO- http://backend:3001/health



\# 2. Service name resolution (in Docker Compose)

docker exec frontend-web wget -qO- http://backend:3001/api/users



\# 3. IP address communication

docker exec frontend-web wget -qO- http://172.18.0.2:3001/health



\# 4. External network access

docker exec backend-api wget -qO- http://google.com



###### **Troubleshooting**

Issue 1: Containers Cannot Communicate
Symptoms: Connection refused or timeout errors

Solutions:

# Check if containers are on the same network
docker network inspect microservices-net

# Verify container names and ports
docker-compose ps

# Check if services are listening on correct ports
docker exec backend-api netstat -tlnp

Issue 2: DNS Resolution Not Working
Symptoms: "Name or service not known" errors

Solutions:

# Restart Docker daemon
sudo systemctl restart docker

# Recreate containers
docker-compose down
docker-compose up -d

# Check Docker DNS settings
docker exec frontend-web cat /etc/resolv.conf

Issue 3: Port Conflicts
Symptoms: "Port already in use" errors

Solutions:

# Check what's using the port
sudo netstat -tlnp | grep :3001
sudo lsof -i :3001

# Use different ports in docker-compose.yml
# Change "3001:3001" to "3002:3001"

Issue 4: Network Already Exists
Symptoms: "Network already exists" error

Solutions:

# Remove existing network (stop containers first)
docker-compose down
docker network rm microservices-net
docker network create microservices-net
docker-compose up -d 



