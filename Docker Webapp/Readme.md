##### Docker and Webapp



\# Build the Docker image with a tag

docker build -t flask-web-app:v1.0 .



\# Run the container with port mapping

docker run -d \\

&nbsp; --name flask-app-container \\

&nbsp; -p 8080:5000 \\

&nbsp; -v flask-app-data:/app/data \\

&nbsp; flask-web-app:v1.0



\# Test the main page

curl http://localhost:8080



\# Test the health check endpoint

curl http://localhost:8080/health



\# Check container logs

docker logs flask-app-container



###### **Add Database Container with Docker Compose**



\# Stop and remove the single container

docker stop flask-app-container

docker rm flask-app-container



\# Deploy with docker.enhanced

\# Build and start all services

docker-compose up -d --build



\# Verify all containers are running

docker-compose ps



\# Check logs for all services

docker-compose logs



###### **Test the Multi-Container Application**



\# Test through Nginx (port 80)

curl http://localhost/



\# Test direct Flask app (port 8080)

curl http://localhost:8080/



\# Test health endpoint

curl http://localhost/health



\# Test statistics endpoint

curl http://localhost/stats



\# Check Redis connectivity

docker-compose exec redis redis-cli ping



###### **Application Testing**



\# Load test

chmod +x load\_test.sh

./load\_test.sh



\# Check container resource usage

docker stats



\# Check specific container logs

docker-compose logs web

docker-compose logs redis

docker-compose logs nginx



\# Check container health

docker-compose exec web curl http://localhost:5000/health



Database Verification



###### **Database Verification**



\# Access the web container

docker-compose exec web /bin/bash



\# Inside the container, check the database

python3 -c "

import sqlite3

conn = sqlite3.connect('/app/data/visitors.db')

cursor = conn.cursor()

cursor.execute('SELECT COUNT(\*) FROM visitors')

print('Total visitors:', cursor.fetchone()\[0])

cursor.execute('SELECT \* FROM visitors ORDER BY visit\_time DESC LIMIT 5')

print('Recent visitors:')

for row in cursor.fetchall():

&nbsp;   print(row)

conn.close()

"



\# Exit the container

exit

###### 

###### **Scaling and Management**



\# Scale the web service to 3 instances

docker-compose up -d --scale web=3



\# Verify scaling

docker-compose ps



\# Test load balancing

for i in {1..10}; do

&nbsp;   curl -s http://localhost/ | grep "Session ID" | head -1

&nbsp;   sleep 1

done



###### **Troubleshooting**



Issue 1: Container Won't Start

Problem: Container fails to start or exits immediately.



Solution:



\# Check container logs

docker-compose logs web



\# Check if ports are already in use

netstat -tulpn | grep :8080



\# Rebuild containers

docker-compose down

docker-compose up --build -d



Issue 2: Database Connection Issues

Problem: Application can't connect to database.



Solution:



\# Check if data directory exists and has correct permissions

docker-compose exec web ls -la /app/data/



\# Recreate the database

docker-compose exec web python3 -c "

from app\_enhanced import init\_db

init\_db()

print('Database initialized')

"



Issue 3: Redis Connection Problems

Problem: Redis service is not accessible.



Solution:



\# Check Redis container status

docker-compose ps redis



\# Test Redis connectivity

docker-compose exec redis redis-cli ping



\# Check network connectivity

docker-compose exec web ping redis



Issue 4: Port Conflicts

Problem: Ports are already in use.



Solution:



\# Find processes using the ports

sudo lsof -i :80

sudo lsof -i :8080



\# Change ports in docker-compose.yml

\# For example, change "80:80" to "8081:80"



###### **Performance Optimization**

