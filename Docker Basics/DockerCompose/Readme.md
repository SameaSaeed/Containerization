##### Docker Compose



**Verify Container Communication Setup**



The containers are configured to communicate through:

Custom Network: All services are on the app-network bridge network

Service Names: Containers can reach each other using service names (redis, postgres, web)

Dependencies: The web service depends on both redis and postgres services

Health Checks: Each service has health checks to ensure proper startup order



**Manage Services with Docker Compose**



Start the entire application stack:

docker-compose up -d



**Test the web application endpoints**



\# Test the home endpoint

curl http://localhost:8080/



\# Test Redis caching

curl http://localhost:8080/cache/testkey/testvalue

curl http://localhost:8080/cache/testkey



\# Test database functionality

curl http://localhost:8080/users



\# Test health check

curl http://localhost:8080/health



**Other commands**



docker-compose stop

docker-compose restart

docker-compose down

docker-compose down -v



Scale the web service to multiple instances:

docker-compose up -d --scale web=3



**View Logs for All Services**



\# Web application logs

docker-compose logs web



\# Redis logs

docker-compose logs redis



\# PostgreSQL logs

docker-compose logs postgres



\# Follow all service logs

docker-compose logs -f



\# Follow specific service logs

docker-compose logs -f web



\# Last 50 lines from all services

docker-compose logs --tail=50



\# Last 20 lines from web service

docker-compose logs --tail=20 web



\# View logs with timestamps:

docker-compose logs -t



**Loadbalancing**



Start the application with scaling and load balancing:

docker-compose up -d --scale web=3



Test the load balancer: Test multiple requests to see load balancing

for i in {1..10}; do

&nbsp; curl http://localhost/

&nbsp; echo "Request $i completed"

done



Scale down the web service:

docker-compose up -d --scale web=1



**Troubleshooting** 



Issue 1: Port Already in Use



\# Check what's using the port

sudo netstat -tulpn | grep :8080



\# Kill the process or change the port in docker-compose.yml



Issue 2: Database Connection Errors



\# Check if PostgreSQL is ready

docker-compose exec postgres pg\_isready -U appuser -d appdb



\# View PostgreSQL logs

docker-compose logs postgres



Issue 3: Redis Connection Errors



\# Test Redis connection

docker-compose exec redis redis-cli ping



\# Check Redis logs

docker-compose logs redis



Issue 4: Build Failures



\# Rebuild without cache

docker-compose build --no-cache



\# Remove all containers and rebuild

docker-compose down

docker-compose up --build

Health Check Commands



**Monitor service health**



\# Check health status

docker-compose ps



\# View detailed health information

docker inspect complex-app-web | grep -A 10 Health



\# Manual health checks

curl http://localhost:8080/health





**Best practices**



Service Isolation: Each service runs in its own container

Environment Variables: Configuration through environment variables

Named Volumes: Persistent data storage

Custom Networks: Isolated network communication

Health Checks: Service health monitoring

Dependency Management: Proper service startup order

Resource Management: Restart policies and resource limits

Security: Non-root users and secure passwords





