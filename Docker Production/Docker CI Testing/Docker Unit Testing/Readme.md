##### **Docker \& Unit Testing**



##### Build and Test a Python Application



cd ~/docker-ci-lab/python-app



\# Build the Docker image

docker build -t python-ci-app:latest .



\# Verify the image was created

docker images | grep python-ci-app



\# Run tests using the default CMD

docker run --rm python-ci-app:latest



\# Run tests with coverage report

docker run --rm python-ci-app:latest python -m pytest tests/ -v --cov=src --cov-report=term-missing



\# Run the application in detached mode

docker run -d --name python-test-app -p 5000:5000 python-ci-app:latest python src/app.py



\# Test the endpoints

curl http://localhost:5000/

curl http://localhost:5000/health

curl http://localhost:5000/add/10/20



##### Build and Test Node.js Application



Build the Node.js Docker image:



cd ~/docker-ci-lab/nodejs-app



\# Build the Docker image

docker build -t nodejs-ci-app:latest .



\# Verify the image was created

docker images | grep nodejs-ci-app

Run tests in the Docker container:



\# Run tests using the default CMD

docker run --rm nodejs-ci-app:latest



\# Run tests with coverage report

docker run --rm nodejs-ci-app:latest npm run test:coverage

Test the application interactively:



\# Run the application in detached mode

docker run -d --name nodejs-test-app -p 3000:3000 nodejs-ci-app:latest npm start



\# Test the endpoints

curl http://localhost:3000/

curl http://localhost:3000/health

curl http://localhost:3000/multiply/6/7

##### 

##### Set Up CI Pipeline with Docker Compose



Create a Docker Compose file to orchestrate both applications

Update package.json to include jest-junit

Create Jenkins script and Jenkins job exe script

Create Gitlab script and GitLab job exe script



\# Change to main dir

cd ~/docker-ci



\# Run the Jenkins-style pipeline

echo "Running Jenkins-style pipeline..."

./run-jenkins-pipeline.sh



echo ""

echo "Waiting 5 seconds before running GitLab CI simulation..."

sleep 5



\# Clean up before running GitLab CI

docker-compose down



\# Run the GitLab CI simulation

echo "Running GitLab CI simulation..."

./run-gitlab-ci.sh

