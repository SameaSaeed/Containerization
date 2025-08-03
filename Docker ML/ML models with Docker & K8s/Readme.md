###### **Containerizing ML model with Docker \& K8s**



###### Serving the containerized ML model



1\. Create a requirements file for Python dependencies

2\. Create an ML model

3\. Create the Flask API wrapper

4\. Create the Dockerfile



5\. Build the Docker image

docker build -t ml-house-predictor:v1.1 .

docker images | grep ml-house-predictor



6\. Run the Container

docker run -d \\

&nbsp; --name ml-predictor \\

&nbsp; -p 5000:5000 \\

&nbsp; ml-house-predictor:v1.1



7\. Test the ML API



Test the documentation endpoint:

curl http://localhost:5000/



\# Prediction 1

curl -X POST http://localhost:5000/predict \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"size": 1800, "bedrooms": 2, "age": 5}'



\# Prediction 2

curl -X POST http://localhost:5000/predict \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"size": 3000, "bedrooms": 4, "age": 15}'



###### Connect the Model Container to a PostgreSQL Container



1. Postgres Container setup



Create a Docker network for container communication:

docker network create ml-network



Run PostgreSQL container:

docker run -d \\

&nbsp; --name postgres-ml \\

&nbsp; --network ml-network \\

&nbsp; -e POSTGRES\_DB=mldata \\

&nbsp; -e POSTGRES\_USER=postgres \\

&nbsp; -e POSTGRES\_PASSWORD=password \\

&nbsp; -p 5432:5432 \\

&nbsp; postgres:13



Wait for PostgreSQL to start (about 10 seconds):

sleep 10



2\. Database Schema



Create the database schema:

docker exec -i postgres-ml psql -U postgres -d mldata << EOF

CREATE TABLE IF NOT EXISTS predictions (

&nbsp;   id SERIAL PRIMARY KEY,

&nbsp;   size REAL NOT NULL,

&nbsp;   bedrooms INTEGER NOT NULL,

&nbsp;   age INTEGER NOT NULL,

&nbsp;   predicted\_price REAL NOT NULL,

&nbsp;   created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

);



-- Insert some sample data

INSERT INTO predictions (size, bedrooms, age, predicted\_price) VALUES

(2000, 3, 5, 245000.50),

(1500, 2, 10, 185000.75),

(2800, 4, 2, 320000.25);

EOF



Verify the table was created:

docker exec -it postgres-ml psql -U postgres -d mldata -c "SELECT \* FROM predictions;"



3\. Connect ML Container to Database



Stop the current ML container:

docker stop ml-predictor-v2

docker rm ml-predictor-v2



Run the ML container with database connection:

docker run -d \\

&nbsp; --name ml-predictor-db \\

&nbsp; --network ml-network \\

&nbsp; -p 5000:5000 \\

&nbsp; -e DB\_HOST=postgres-ml \\

&nbsp; -e DB\_NAME=mldata \\

&nbsp; -e DB\_USER=postgres \\

&nbsp; -e DB\_PASSWORD=password \\

&nbsp; -e DB\_PORT=5432 \\

&nbsp; ml-house-predictor:v1.1



4\. Test the database connection:

curl http://localhost:5000/predictions



Predict to test database storage:

curl -X POST http://localhost:5000/predict \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"size": 2200, "bedrooms": 3, "age": 8}'



Verify the prediction was stored:

curl http://localhost:5000/predictions



###### Integrate the Docker Container into a Kubernetes Deployment



1. **Create Kubernetes Files**



mkdir k8s-manifests

cd k8s-manifests



nano postgres-deployment.yaml

nano ml-deployment.yaml

nano db-init-configmap.yaml



**2. Deploy to Kubernetes**



Start minikube (if not already running):

minikube start



Load the Docker image into minikube:

minikube image load ml-house-predictor:v1.1



Apply the Kubernetes manifests:

kubectl apply -f db-init-configmap.yaml

kubectl apply -f postgres-deployment.yaml

kubectl apply -f ml-deployment.yaml



Check the deployment status:

kubectl get deployments

kubectl get pods

kubectl get services



**3. Initialize Database in Kubernetes**



Wait for PostgreSQL pod to be ready:

kubectl wait --for=condition=ready pod -l app=postgres --timeout=60s

Initialize the database:

kubectl exec -i deployment/postgres-deployment -- psql -U postgres -d mldata << EOF

CREATE TABLE IF NOT EXISTS predictions (

&nbsp;   id SERIAL PRIMARY KEY,

&nbsp;   size REAL NOT NULL,

&nbsp;   bedrooms INTEGER NOT NULL,

&nbsp;   age INTEGER NOT NULL,

&nbsp;   predicted\_price REAL NOT NULL,

&nbsp;   created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

);



INSERT INTO predictions (size, bedrooms, age, predicted\_price) VALUES

(2000, 3, 5, 245000.50),

(1500, 2, 10, 185000.75),

(2800, 4, 2, 320000.25);

EOF



**4. Test the Kubernetes Deployment**



Get the service URL:

minikube service ml-predictor-service --url



Test the API (replace URL with the output from previous command):

\# Get the service URL

SERVICE\_URL=$(minikube service ml-predictor-service --url)



\# Test health endpoint

curl $SERVICE\_URL/health



\# Test prediction

curl -X POST $SERVICE\_URL/predict \\

&nbsp; -H "Content-Type: application/json" \\

&nbsp; -d '{"size": 2400, "bedrooms": 3, "age": 7}'



\# Get predictions from database

curl $SERVICE\_URL/predictions



Check pod logs:

kubectl logs -l app=ml-predictor



Scale the deployment:

kubectl scale deployment ml-predictor-deployment --replicas=3

kubectl get pods



**5. Monitor the Deployment**



Check resource usage:

kubectl top pods



View deployment details:

kubectl describe deployment ml-predictor-deployment



Check service endpoints:

kubectl get endpoints



###### Troubleshooting 



Container fails to start:

Check logs: docker logs <container-name>

Verify port availability: netstat -tulpn | grep :5000



Database connection fails:

Ensure containers are on the same network

Check environment variables

Verify PostgreSQL is ready: docker exec postgres-ml pg\_isready



Kubernetes pods not starting:

Check pod status: kubectl describe pod <pod-name>

Verify image availability: kubectl get events



API returns errors:

Check application logs

Verify JSON format in requests

Ensure all required fields are provided



Model predictions seem incorrect:

The model uses synthetic data for demonstration

In production, use real training data

Consider model validation and testing

