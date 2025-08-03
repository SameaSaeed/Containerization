##### **Docker Debugging**



##### Basic Log Inspection

###### 

###### **View real-time logs:**

\# View logs in real-time (similar to tail -f)

docker logs -f debug-container



###### **In a new terminal, generate some log entries:**

\# Generate different types of requests to create logs

curl http://localhost:8080/

curl http://localhost:8080/error

curl http://localhost:8080/nonexistent

curl http://localhost:8080/slow \&

###### 

###### **View logs with timestamps:**

\# Stop the real-time log viewing (Ctrl+C) and view logs with timestamps

docker logs -t debug-container



###### **View recent logs only:**

\# View only the last 10 log entries

docker logs --tail 10 debug-container



\# View logs from the last 5 minutes

docker logs --since 5m debug-container



##### Advanced Log Analysis



###### **Filter logs by time range:**

\# View logs from a specific time (adjust the time to your current time)

docker logs --since "2024-01-01T10:00:00" --until "2024-01-01T11:00:00" debug-container



\# View logs from the last hour

docker logs --since 1h debug-container



###### **Search for specific log patterns:**

\# Use grep to filter logs for errors

docker logs debug-container 2>\&1 | grep -i error



\# Search for specific HTTP status codes

docker logs debug-container 2>\&1 | grep "404\\|500"



###### **Run Commands Inside Containers:**

\# Execute bash inside the running container

docker exec -it debug-container bash



\# Check the current working directory

pwd



\# List files in the application directory

ls -la



\# Check running processes

ps aux



\# Check network configuration

ip addr show



\# Check environment variables

env | grep -E "(PATH|PYTHON|HOME)"



\# Exit the container shell

exit



##### Running Specific Commands



###### **Execute single commands without entering interactive mode:**



\# Check the Python version in the container

docker exec debug-container python --version



\# View the application file

docker exec debug-container cat app.py



\# Check disk usage

docker exec debug-container df -h



\# Check memory usage

docker exec debug-container free -m



###### **Debug application-specific issues:**



\# Check if the application is listening on the correct port

docker exec debug-container netstat -tlnp



\# Test internal connectivity

docker exec debug-container curl http://localhost:8080/



\# Check application logs from inside the container

docker exec debug-container ps aux | grep python



###### **Debugging Resource Issues**



1\.

\# Run a container with limited memory

docker run -d --name memory-limited --memory=50m python:3.9-slim python -c "

import time

data = \[]

while True:

&nbsp;   data.append('x' \* 1024 \* 1024)  # Allocate 1MB

&nbsp;   time.sleep(1)

&nbsp;   print(f'Allocated {len(data)} MB')

"



**2.**

\# Monitor container resource usage

docker stats memory-limited --no-stream



\# Check container logs for memory issues

docker logs memory-limited



\# Get detailed resource information

docker inspect memory-limited | grep -A 10 "Memory"



3\.



High Resource Usage

\# Monitor real-time resource usage

docker stats <container\_name>



\# Check processes inside container

docker exec <container\_name> ps aux



\# Examine system resources

docker exec <container\_name> free -m

docker exec <container\_name> df -h



###### **Installing Debug Tools**



Install additional debugging tools inside the container:

\# Enter the container interactively

docker exec -it debug-container bash



\# Update package list and install tools

apt-get update

apt-get install -y curl wget htop strace



\# Test the newly installed tools

htop  # Press 'q' to quit

curl http://localhost:8080/

exit



##### **Troubleshoot**: **Inspect Container Network Configuration**



Examine container network details:

\# Get detailed information about the container

docker inspect debug-container



\# Focus on network configuration

docker inspect debug-container | grep -A 20 "NetworkSettings"

Check container IP address and network:

\# Get the container's IP address

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debug-container



\# Get network name

docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' debug-container



###### **Network Connectivity Testing**



Create a second container for network testing:

\# Run a simple container for network testing

docker run -d --name network-test alpine sleep 3600



\# Test connectivity between containers

docker exec network-test ping -c 3 $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debug-container)



Test port connectivity:

\# Install network tools in the test container

docker exec network-test apk add --no-cache curl



\# Test HTTP connectivity between containers

docker exec network-test curl http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debug-container):8080/



###### **Simulate and fix port binding issues**



\# Stop the current container

docker stop debug-container



\# Try to run another container on the same port (this will fail)

docker run -d --name debug-container-2 -p 8080:8080 debug-app



\# Check if the port is already in use

docker ps -a

netstat -tlnp | grep 8080



\# Run on a different port

docker run -d --name debug-container-alt -p 8081:8080 debug-app



\# Test the new port

curl http://localhost:8081/



Examine Docker networks:

\# List all Docker networks

docker network ls



\# Inspect the default bridge network

docker network inspect bridge



\# Create a custom network for better isolation

docker network create debug-network



\# Run containers on the custom network

docker run -d --name debug-app-custom --network debug-network -p 8082:8080 debug-app



Create a container that runs interactively:



\# Stop previous containers to free up resources

docker stop debug-container debug-container-2 debug-container-alt debug-app-custom network-test



\# Run a container with an interactive process

docker run -d --name interactive-container alpine sh -c "while true; do echo 'Container is running...'; sleep 5; done"



##### **Docker attach**



\# Stop previous containers to free up resources

docker stop debug-container debug-container-2 debug-container-alt debug-app-custom network-test



\# Run a container with an interactive process

docker run -d --name interactive-container alpine sh -c "while true; do echo 'Container is running...'; sleep 5; done"



\# Attach to see the output

docker attach interactive-container



\# Note: You'll see the repeating output

\# Press Ctrl+C to detach (this will stop the container)



1\.

\# Run a container with bash that stays open

docker run -dit --name shell-container ubuntu bash



\# Attach to the container

docker attach shell-container



\# You now have an interactive shell

\# Try some commands:

ls -la

ps aux

echo "I'm inside the container"



\# Detach without stopping the container using Ctrl+P, Ctrl+Q

\# (Press Ctrl+P, then Ctrl+Q in sequence)



2\.

\# After detaching, check that the container is still running

docker ps



\# Use exec to enter the same container (recommended approach)

docker exec -it shell-container bash



\# This creates a new process, so exiting won't stop the container

exit



\# Verify the container is still running

docker ps

