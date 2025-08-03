##### Machine Learning Project Containers



###### **Build a Containerized Machine Learning Model**



**a. Create Project Directory Structure**



\# Create main project directory

mkdir ml-docker-lab \&\& cd ml-docker-lab



\# Create subdirectories for organization

mkdir -p {notebooks,models,data,src}



**b. Create necessary files**



touch Dockerfile requirements.txt docker-compose.yml

Create Requirements File

Create the Dockerfile



**c. Build the Docker Image**



\# Build the Docker image

docker build -t ml-tensorflow:latest .



\# Verify the image was created

docker images | grep ml-tensorflow



###### **Run a Containerized Machine Learning Model**



1. Create a ML Model Script



2\. Run the container with volume mounting for model persistence

docker run -it --rm \\

&nbsp;   -v $(pwd)/models:/app/models \\

&nbsp;   -v $(pwd)/data:/app/data \\

&nbsp;   ml-tensorflow:latest \\

&nbsp;   python src/simple\_ml\_model.py



3\. Verify Model Training



ls -la models/



\# You should see:

\# simple\_model.h5

\# scaler.pkl

##### 

##### Jupyter Notebooks Inside the Container



1. Create a Sample Jupyter Notebook

mkdir -p notebooks

nano notebooks/ml\_exploration.ipynb



2\. Run Jupyter Lab in Container

docker run -it --rm \\

&nbsp;   -p 8888:8888 \\

&nbsp;   -v $(pwd)/notebooks:/app/notebooks \\

&nbsp;   -v $(pwd)/models:/app/models \\

&nbsp;   -v $(pwd)/data:/app/data \\

&nbsp;   ml-tensorflow:latest



3\. Access Jupyter Lab

After running the container, you should see output similar to:



\[I 2024-01-01 12:00:00.000 ServerApp] Jupyter Server 2.7.0 is running at:

\[I 2024-01-01 12:00:00.000 ServerApp] http://0.0.0.0:8888/lab

Open your web browser and navigate to:



http://localhost:8888/lab

You can now access Jupyter Lab running inside your Docker container and work with the notebook interactively.

###### 

##### Save and Load Trained Models from Docker Volumes



1. Create Model Management Script

nano src/model\_manager.py



2\. Test Model Persistence

\# Run the model persistence demo

docker run -it --rm \\

&nbsp;   -v $(pwd)/models:/app/models \\

&nbsp;   ml-tensorflow:latest \\

&nbsp;   python src/model\_manager.py



3\. Verify Persistent Storage

\# List files in the models directory

ls -la models/



\# Start a new container and list models

docker run -it --rm \\

&nbsp;   -v $(pwd)/models:/app/models \\

&nbsp;   ml-tensorflow:latest \\

&nbsp;   python -c "

from src.model\_manager import ModelManager

manager = ModelManager()

print('Available models:', manager.list\_saved\_models())

"



##### Docker Compose Setup for Multi-Service ML Application



Create Flask API for Model Serving

nano src/ml\_api.py



Create Database Setup Script

nano src/database\_setup.py

