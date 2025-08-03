##### Python app with Docker



**Run app locally**



1\. Create a Python Web Application

2\. Create HTML Template

3\. Test the Application Locally



\# Install Flask (if not already installed)

pip3 install flask



\# Run the application

python3 app.py



You should see output similar to:



\* Running on all addresses (0.0.0.0)

\* Running on http://127.0.0.1:5000

\* Running on http://\[your-ip]:5000



Note: Press Ctrl+C to stop the application when you're done testing.



**Dockerfile to Containerize the Python App**



\# Build the Docker image

docker build -t python-flask-app:v1.0 .



\# Verify the image was created

docker images | grep python-flask-app



\# Run the container

docker run -d \\

&nbsp; --name flask-app-container \\

&nbsp; -p 8080:5000 \\

&nbsp; -v $(pwd)/data:/app/data \\

&nbsp; python-flask-app:v1.0



\# Check if container is running

docker ps



\# Test the health endpoint

curl http://localhost:8080/health



\# Check application logs

docker logs flask-app-container



\# Access the application

echo "Open your browser and navigate to http://localhost:8080"



\# Inspect container details

docker inspect flask-app-container



\# Check container resource usage

docker stats flask-app-container --no-stream



\# Execute commands inside the container

docker exec -it flask-app-container /bin/bash

\# Type 'exit' to leave the container shell



**Expose Ports and Connect to a Database Container**



\# Stop the current container

docker stop flask-app-container

docker rm flask-app-container



\# Create a Docker network for our containers

docker network create flask-network



\# Run PostgreSQL container

docker run -d \\

&nbsp; --name postgres-db \\

&nbsp; --network flask-network \\

&nbsp; -e POSTGRES\_DB=flaskapp \\

&nbsp; -e POSTGRES\_USER=flaskuser \\

&nbsp; -e POSTGRES\_PASSWORD=flaskpass \\

&nbsp; -p 5432:5432 \\

&nbsp; postgres:13



\# Rebuild the image

docker build -t python-flask-app:v2.0 .



\# Run the updated container connected to the database

docker run -d \\

&nbsp; --name flask-app-container \\

&nbsp; --network flask-network \\

&nbsp; -p 8080:5000 \\

&nbsp; -e DB\_HOST=postgres-db \\

&nbsp; -e DB\_NAME=flaskapp \\

&nbsp; -e DB\_USER=flaskuser \\

&nbsp; -e DB\_PASSWORD=flaskpass \\

&nbsp; python-flask-app:v2.0



\# Check both containers are running

docker ps



\# Test the health endpoint

curl http://localhost:8080/health



\# Check application logs

docker logs flask-app-container



\# Test database connectivity

docker exec -it postgres-db psql -U flaskuser -d flaskapp -c "SELECT \* FROM visitors;



**Create Multi-Container Setup with Docker Compose**



\# Stop and remove existing containers

docker stop flask-app-container postgres-db 2>/dev/null || true

docker rm flask-app-container postgres-db 2>/dev/null || true



\# Remove the network we created manually

docker network rm flask-network 2>/dev/null || true



\# Start all services with Docker Compose

docker-compose up -d



\# Check the status of all services

docker-compose ps



\# View logs from all services

docker-compose logs



\# View logs from a specific service

docker-compose logs web



\# Test the web application

curl http://localhost:8080/health



\# Test direct database connection

docker-compose exec database psql -U flaskuser -d flaskapp -c "SELECT COUNT(\*) FROM visitors;"



\# Test Redis cache (if included)

docker-compose exec cache redis-cli ping



\# Test Nginx proxy (if included)

curl http://localhost/health



\# Scale the web service to 3 instances

docker-compose up -d --scale web=3



\# Check the scaled services

docker-compose ps



\# Scale back to 1 instance

docker-compose up -d --scale web=1



**Advanced Operations and Management**



**Container Monitoring and Logs**

\# View real-time logs from all services

docker-compose logs -f



\# Monitor resource usage

docker stats



\# Check container health

docker-compose exec web curl http://localhost:5000/health



**Database Operations**

Perform database operations:



\# Access database shell

docker-compose exec database psql -U flaskuser -d flaskapp



\# Backup database

docker-compose exec database pg\_dump -U flaskuser flaskapp > backup.sql



\# View database tables

docker-compose exec database psql -U flaskuser -d flaskapp -c "\\dt"



**Application Updates**

Update your application without downtime:



\# Rebuild and update a specific service

docker-compose build web

docker-compose up -d web



\# Update all services

docker-compose build

docker-compose up -d

