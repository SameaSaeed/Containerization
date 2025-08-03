######  Set up a GitLab CI/CD Pipeline to Build and Deploy Docker Images



1\. Create a sample application, a Dockerfile, docker-compose (to deploy multiple services as part of the Pipeline), nginx.conf, .env, scripts files

2\. Create .gitlab-ci.yml GitLab CI/CD Pipeline Configuration

3\. Initialize Git Repository and Connect to GitLab



a. Initialize Git repository:

git init

git add .

git commit -m "Initial commit"



b. Go to GitLab.com and sign in

Click New Project

Choose Create blank project

Name it docker-cicd-lab

Set visibility to Private

Click Create project



c. Connect local repository to GitLab:

git remote add origin https://gitlab.com/YOUR\_USERNAME/docker-cicd-lab.git

git branch -M main

git push -u origin main

Replace YOUR\_USERNAME with your actual GitLab username.



###### Versioning



Create a version file for semantic versioning:

echo "1.0.0" > VERSION



Update the pipeline and commit the updated file



###### Use GitLab CI/CD Variables to Inject Secrets and Environment Variables



a. Configure GitLab CI/CD Variables



Navigate to GitLab project

Go to Settings > CI/CD

Expand the Variables section

Add the following variables:

Production Variables:



Key: PROD\_MONGO\_USERNAME, Value: prod\_admin, Protected: ✓, Masked: ✓

Key: PROD\_MONGO\_PASSWORD, Value: super\_secure\_prod\_password, Protected: ✓, Masked: ✓

Key: PROD\_REDIS\_PASSWORD, Value: redis\_prod\_secure\_pass, Protected: ✓, Masked: ✓

Key: PROD\_DATABASE\_URL, Value: mongodb://prod\_admin:super\_secure\_prod\_password@mongo:27017/proddb, Protected: ✓

Staging Variables:



Key: STAGING\_MONGO\_USERNAME, Value: staging\_admin, Masked: ✓

Key: STAGING\_MONGO\_PASSWORD, Value: staging\_secure\_password, Masked: ✓

Key: STAGING\_REDIS\_PASSWORD, Value: redis\_staging\_pass, Masked: ✓

General Variables:



Key: CI\_PUSH\_TOKEN, Value: your\_gitlab\_token\_here, Masked: ✓

Key: NOTIFICATION\_WEBHOOK, Value: https://hooks.slack.com/your/webhook/url



b. Create Environment-Specific docker-compose Files



Create staging-specific compose file

Create production-specific compose file



c. Update Pipeline file with Secret Management

d. Create a script to validate that all required secrets are available



**Trigger Pipeline on Commits to Automatically Deploy Docker Containers**



1. Configure Automatic Triggers

\# Create a feature branch to test automatic triggers

git checkout -b feature/auto-deploy-test



\# Make a small change to trigger the pipeline

echo "# Docker CI/CD Demo Application



This application demonstrates GitLab CI/CD integration with Docker.



\## Features

\- Automated Docker image building

\- Comprehensive testing in containers

\- Automatic deployment on commits

\- Docker Hub integration



\## Version: 1.1.0" > README.md



2\. Update application version

\# Update package.json version

sed -i 's/"version": "1.0.0"/"version": "1.1.0"/' package.json



\# Update app.js version

sed -i 's/version.\*1.0.0/version: "1.1.0"/' app.js

