**Containerizing a REST API**



**Dockerize app**



Build the Docker image for your Flask API:

docker build -t flask-api:v1.0 .



Verify the image was created successfully:

docker images | grep flask-api



**Expose the API and connect it to a PostgreSQL container**



Create a Docker network

docker network create api-network



Run PostgreSQL container

docker run -d \\

&nbsp; --name postgres-db \\

&nbsp; --network api-network \\

&nbsp; -e POSTGRES\_DB=apidb \\

&nbsp; -e POSTGRES\_USER=apiuser \\

&nbsp; -e POSTGRES\_PASSWORD=apipass \\

&nbsp; -p 5432:5432 \\

&nbsp; postgres:15-alpine



Check if PostgreSQL is ready to accept connections:

docker logs postgres-db



Run the Flask API container

docker run -d \\

&nbsp; --name flask-api-container \\

&nbsp; --network api-network \\

&nbsp; -e DB\_HOST=postgres-db \\

&nbsp; -e DB\_NAME=apidb \\

&nbsp; -e DB\_USER=apiuser \\

&nbsp; -e DB\_PASS=apipass \\

&nbsp; -e DB\_PORT=5432 \\

&nbsp; -p 5000:5000 \\

&nbsp; flask-api:v1.0



**Test API**



1. Check API health: Test the health endpoint:



curl http://localhost:5000/

Expected response:



{

&nbsp; "message": "Flask API is running!",

&nbsp; "status": "healthy",

&nbsp; "version": "1.0"

}



2\. Test API endpoints:



curl -X POST http://localhost:5000/users \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"name": "John Doe", "email": "john@example.com"}'



Test getting all users:



curl http://localhost:5000/users

Test getting a specific user:



curl http://localhost:5000/users/1

Test updating a user:



curl -X PUT http://localhost:5000/users/1 \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"name": "John Smith", "email": "johnsmith@example.com"}'



3\. View container logs



Check the API container logs to see request processing:

docker logs flask-api-container



Check PostgreSQL logs:

docker logs postgres-db



**Docker-copmose**



docker-compose up -d



\# Health check

curl http://localhost:5000/



\# Get all users (should include sample data)

curl http://localhost:5000/users



\# Create a new user

curl -X POST http://localhost:5000/users \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"name": "David Miller", "email": "david@example.com"}'



\# Verify the new user was created

curl http://localhost:5000/users



\#View docker-compose logs for a specific service:

docker-compose logs api

docker-compose logs database



**Scale and manage services**



Scale the API service (run multiple instances):

docker-compose up -d --scale api=2



Stop all services:

docker-compose down



Stop services and remove volumes:

docker-compose down -v



**Advanced Testing**



1. Database Connection Testing

Connect directly to the PostgreSQL container to verify data:



docker exec -it postgres-db psql -U apiuser -d apidb

Inside the PostgreSQL shell, run:



\\dt

SELECT \* FROM users;

\\q



2\. Performance Testing: Test API performance using curl in a loop:

for i in {1..10}; do

&nbsp; curl -X POST http://localhost:5000/users \\

&nbsp;   -H "Content-Type: application/json" \\

&nbsp;   -d "{\\"name\\": \\"User$i\\", \\"email\\": \\"user$i@example.com\\"}" \\

&nbsp;   -w "Time: %{time\_total}s\\n"

done



3\. Monitor container resource usage:

docker stats



**Troubleshooting** 



Issue 1: Database Connection Refused

Problem: API cannot connect to PostgreSQL Solution:

Ensure containers are on the same network

Check environment variables

Verify PostgreSQL is fully started before API



Issue 2: Port Already in Use

Problem: Port 5000 or 5432 already in use Solution:

\# Find process using the port

sudo lsof -i :5000

\# Kill the process or change port in docker-compose.yml



Issue 3: Permission Denied

Problem: Permission issues with volumes Solution:

\# Fix ownership

sudo chown -R $USER:$USER ./app



**Best Practices**



Security: Non-root user in container

Health Checks: Container health monitoring

Environment Variables: Configurable database settings

Data Persistence: PostgreSQL data volume

Network Isolation: Custom Docker network

Dependency Management: Service dependencies in Compose

Resource Optimization: Multi-stage builds and .dockerignore

