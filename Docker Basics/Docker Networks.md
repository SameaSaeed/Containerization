##### Docker Networks



docker network ls

Default network: Bridge



###### **Custom Bridge Network**



Provide better isolation than the default bridge network

Enable automatic DNS resolution between containers

Allow custom IP addressing schemes



**Create a custom network**



docker network create app-network

docker network create \\

&nbsp; --driver bridge \\

&nbsp; --subnet=172.20.0.0/16 \\

&nbsp; --ip-range=172.20.240.0/20 \\

&nbsp; --gateway=172.20.0.1 \\

&nbsp; backend-network



docker network connect custom-network container1: Connect an existing container to a custom network

docker network disconnect <network\_name> <container\_name> : Disconnect a container from a network



docker network inspect bridge

docker inspect web-server-1 | grep IPAddress



**Test Network Communication**



Test external access

curl http://localhost:hostport



Test internal network access

docker exec container-1 ping -c 3 container-2

docker exec alpine-client ping -c 3 <IP\_ADDRESS\_OF\_WEB\_SERVER\_1>

docker exec container-1 wget -qO- http://container-2

docker exec alpine-client wget -qO- http://<IP\_ADDRESS\_OF\_WEB\_SERVER\_1>



docker exec default-network-container ping -c 3 custom-network-container

(Fail: network isolation between different Docker networks)



**Inspect network**



docker network inspect <network\_name>



\# Get specific network information using format filters

docker network inspect webapp-network --format='{{.IPAM.Config}}'



\# Check which containers are connected

docker network inspect webapp-network --format='{{range .Containers}}{{.Name}} {{.IPv4Address}}{{end}}'

###### 

**Network Segmentation**



a. Deploy a Multi-Container Application



\# Run a database container in the backend network

docker run -d --name mysql-db \\

  --network backend-network \\

  -e MYSQL\_ROOT\_PASSWORD=rootpass \\

  -e MYSQL\_DATABASE=webapp \\

  mysql:8.0



\# Run an application server connected to both networks

docker run -d --name app-server \\

  --network backend-network \\

  nginx: alpine



\# Connect the app-server to the frontend network as well

docker network connect frontend-network app-server



b. Test connectivity between containers in the same network:



\# Access the web-client container

docker exec -it web-client sh



\# Inside the container, test connectivity to web-server

ping web-server



\# Test HTTP connectivity

wget -qO- http://web-server



\# Exit the container

exit



c. Test Cross-Network Communication



\# Run a container in the frontend network

docker run -d --name frontend-app --network frontend-network alpine:latest sleep 3600



\# Try to ping from frontend to backend (should fail)

docker exec frontend-app ping mysql-db



d. Test Multi-Network Container Communication



\# From the app server, test connectivity to the backend

docker exec app-server ping mysql-db



\# Run a test container in the frontend network

docker run --rm --network frontend-network alpine:latest ping -c 3 app-server



**Removing Networks**



docker network rm app-network custom-subnet-network



##### **Host Network**



Containers share the host's network stack

Better performance but less isolation

Useful for network monitoring and high-performance applications



\# Check the host-nginx container network settings

docker inspect host-nginx | grep -A 5 "NetworkMode"



\# Run a simple web server on host network

docker run --rm --network host -p 8080:80 nginx:alpine \&



\# Test accessibility (should be accessible on host IP)

curl localhost:8080



\# Stop the background container

docker stop $(docker ps -q --filter ancestor=nginx:alpine)



\# Run a container that monitors host network interfaces

docker run --rm --network host alpine:latest ip addr show



\# Compare with bridge network container

docker run --rm --network bridge alpine:latest ip addr show



##### **Troubleshooting**



\# Check container network namespace

docker exec web-server ip route



\# Check network interface details

docker exec web-server ip addr show



\# Test DNS resolution

docker exec web-server nslookup web-client



\# Check iptables rules (on host)

sudo iptables -t nat -L DOCKER



Issue 1: Container Cannot Resolve Other Container Names

Solution: Ensure both containers are on the same custom network (not default bridge)



Issue 2: Port Conflicts with Host Networking

Solution: Check for port conflicts on the host system before using host networking



Issue 3: Cannot Remove Network

Solution: Ensure no containers are connected to the network before removal

