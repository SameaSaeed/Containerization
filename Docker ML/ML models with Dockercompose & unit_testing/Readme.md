###### **ML model containerization with docker-compose**



1\. Create a Machine Learning Model

2\. Train and Save the Model



\# Navigate to model directory

cd model



\# Install required packages

pip3 install scikit-learn pandas joblib



\# Train the model

python3 train\_model.py



\# Verify model files are created

ls -la \*.pkl



\# Return to main directory

cd ..



3\. Create Flask API Application

4\. Create Requirements File

5\. Create Dockerfile

6\. Build the Docker image

docker build -t ml-flask-app:latest .



7\. Run the container

docker run -d --name ml-app-test -p 5000:5000 ml-flask-app:latest



8\. Test the health endpoint

curl http://localhost:5000/health



Check container logs

docker logs ml-app-test



9\. Create a database schema

10\. Update Flask App with Database Integration

11\. Create Docker Compose File (Services: Postgres, ML app, Nginx)

12\. Deploy with Docker Compose

\# Start all services

docker-compose up -d



\# Check service status

docker-compose ps



\# View logs

docker-compose logs -f



\# Check individual service logs

docker-compose logs ml-app-1

docker-compose logs postgres



13\. Create Test Scripts (Unit/integration tests)



14\. Build Docker Image

Push Docker Image to Registry

Deploy to Staging/Production (DockerCompose/ K8s/ Serverless)







