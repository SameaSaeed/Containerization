1\. Create Jenkins Pipeline Job for CI part



Go to Jenkins Dashboard

Click New Item

Enter name: docker-cicd-pipeline

Select Pipeline and click OK

Configure Pipeline



In Pipeline section, select Pipeline script from SCM

SCM: Git

Repository URL: Use your local git repository path or create a GitHub repo

Script Path: Jenkinsfile

Save the configuration

Commit Pipeline Files



git add .

git commit -m "Add Jenkins pipeline configuration"



2\. Deploy Docker Containers to AWS EC2 Instances



Create:

EC2 deployment script, 

Jenkinsfile with EC2 Deployment, 

Configure AWS CLI for Automated EC2 Management through a script



3\. Security

Integrate Trivy Security Scanner

Advanced Security Pipeline Stage

Security Policy File



4\. Test Complete CI/CD Pipeline



a. Run Full Pipeline Test



\# Commit all changes

git add .

git commit -m "Complete CI/CD pipeline with security scanning"



\# Test local build

./build-docker.sh



\# Test security scan

./security-scan.sh your-dockerhub-username/docker-cicd-demo:latest



\# Verify application works

docker run -d --name test-app -p 3002:3000 your-dockerhub-username/docker-cicd-demo:latest

sleep 5

curl http://localhost:3002/health

docker stop test-app \&\& docker rm test-app



b. Trigger Jenkins Pipeline

Go to the Jenkins Dashboard

Click on your Docker-CI/CD pipeline job

Click Build Now

Monitor the pipeline execution through each stage



c. Verify Deployment



\# Check if the staging deployment is running

curl http://localhost:3001/health



\# Check Docker Hub for pushed images

docker search your-dockerhub-username/docker-cicd-demo



**Troubleshooting** 



Docker Permission Issues

\# If Jenkins can't access Docker

sudo usermod -aG docker jenkins

sudo systemctl restart jenkins



Pipeline Fails at Security Scan

\# Install missing dependencies

sudo apt-get update

sudo apt-get install curl wget jq -y



EC2 Connection Issues

\# Verify SSH key permissions

chmod 400 ~/.ssh/your-key.pem

\# Test SSH connection

ssh -i ~/.ssh/your-key.pem ubuntu@your-ec2-ip



Docker Hub Push Failures

\# Login manually to test credentials

docker login

docker push your-dockerhub-username/docker-cicd-demo:test



**Validation**



1. Check Jenkins Pipeline Success

All pipeline stages should complete successfully

Security scan reports should be generated

Images should be pushed to Docker Hub



2\. Verify Docker Hub Repository

Images with different tags should be visible

Latest tag should point to most recent build



3\. Test Application Deployment

Staging environment should be accessible

Health check endpoint should return success

Application should serve expected responses



4\. Security Scan Results

Security reports should be generated

Vulnerability counts should be documented

No critical security issues should block deployment

