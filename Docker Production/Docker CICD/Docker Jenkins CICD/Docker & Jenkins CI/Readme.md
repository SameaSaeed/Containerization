##### Docker and Jenkins CI/CD



###### **Setting up Jenkins**



a. Install Jenkins



\# Update package repository

sudo apt update



\# Install OpenJDK 11 (required for Jenkins)

sudo apt install -y openjdk-11-jdk



\# Verify Java installation

java -version



\# Add Jenkins repository key

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \\

  /usr/share/keyrings/jenkins-keyring.asc > /dev/null



\# Add Jenkins repository to sources list

echo deb \[signed-by=/usr/share/keyrings/jenkins-keyring.asc] \\

  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \\

  /etc/apt/sources.list.d/jenkins.list > /dev/null



\# Update package repository

sudo apt update



\# Install Jenkins

sudo apt install -y Jenkins



\# Start Jenkins service

sudo systemctl start jenkins



\# Enable Jenkins to start on boot

sudo systemctl enable jenkins



\# Check Jenkins service status

sudo systemctl status Jenkins



b. Configure Jenkins Initial Setup



\# Get the initial admin password

sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Note: Copy this password as you'll need it for the web setup.



Open your web browser and navigate to http://localhost:8080 (or your server's IP address with port 8080).

Enter the initial admin password you copied

Click Install suggested plugins



Create your first admin user with the following details:

Username: admin

Password: admin123

Full name: Jenkins Administrator

Email: admin@example.com

Keep the default Jenkins URL

Click Start using Jenkins



###### **Create a Jenkins Pipeline for Docker Image Building and Testing**



a. Configure Jenkins to Use Docker for Building Images



Install Docker Plugin in Jenkins

In Jenkins dashboard, go to Manage Jenkins → Manage Plugins

Click on Available tab

Search for Docker and install the following plugins:

Docker Pipeline

Docker plugin

Docker Commons Plugin

Click Install without restart

Check Restart Jenkins when installation is complete



b. Add Jenkins User to Docker Group

\# Add jenkins user to Docker group

sudo usermod -aG docker jenkins



\# Restart Jenkins service to apply changes

sudo systemctl restart jenkins



\# Verify Docker access for Jenkins user

sudo -u jenkins docker ps



c. Configure Docker in Jenkins Global Tool Configuration

Go to Manage Jenkins → Global Tool Configuration

Scroll down to the Docker section

Click Add Docker

Configure as follows:

Name: docker

Installation root: /usr/bin/docker

Check Install automatically and select Download from docker.com

Click Save



d. Create a sample application



e. Initialize Git repo



f. Create Jenkins pipeline

In the Jenkins dashboard, click New Item

Enter item name: docker-pipeline-demo

Select Pipeline and click OK



In the configuration page, scroll down to the Pipeline section

Select Pipeline script and Save



g.  Run the Pipeline

Click Build Now to trigger the pipeline

Monitor the build progress in the Build History

Click on the build number to view detailed logs

Verify that all stages complete successfully

###### 

###### **Integrate SonarQube for Static Code Analysis**



**a. Install SonarQube**



\# Create SonarQube directory

sudo mkdir -p /opt/sonarqube

cd /opt/sonarqube



\# Download SonarQube Community Edition

sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip



\# Install unzip if not available

sudo apt install -y unzip



\# Extract SonarQube

sudo unzip sonarqube-9.9.0.65466.zip

sudo mv sonarqube-9.9.0.65466 sonarqube



\# Create sonarqube user

sudo useradd -r -s /bin/false sonarqube



\# Set ownership

sudo chown -R sonarqube:sonarqube /opt/sonarqube



\# Configure SonarQube service

sudo tee /etc/systemd/system/sonarqube.service > /dev/null << 'EOF'

\[Unit]

Description=SonarQube service

After=syslog.target network.target



\[Service]

Type=forking

ExecStart=/opt/sonarqube/sonarqube/bin/linux-x86-64/sonar.sh start

ExecStop=/opt/sonarqube/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonarqube

Group=sonarqube

Restart=always

LimitNOFILE=65536

LimitNPROC=4096



\[Install]

WantedBy=multi-user.target

EOF



\# Start SonarQube service

sudo systemctl daemon-reload

sudo systemctl start sonarqube

sudo systemctl enable sonarqube



\# Check service status

sudo systemctl status SonarQube



**b. Configure SonarQube Initial Setup**

Wait for SonarQube to start (it may take a few minutes), then:



Open browser and navigate to http://localhost:9000

Login with default credentials:

        Username: admin

        Password: admin

Change the password when prompted to: admin123

Click Create new project

Choose Manually

Configure project:

 	Project key: sample-node-app

        Display name: Sample Node App

Click Set Up

Choose Use global setting for token

Generate token and copy it (save it as you'll need it later)



**c. Install SonarQube Plugin in Jenkins**



Go to Manage Jenkins → Manage Plugins

Search for SonarQube Scanner plugin

Install the plugin and restart Jenkins



**d. Configure SonarQube in Jenkins**



Go to Manage Jenkins → Configure System

Scroll to SonarQube servers section

Click Add SonarQube



Configure:

Name: SonarQube

Server URL: http://localhost:9000

Server authentication token: Click Add → Jenkins

Kind: Secret text

Secret: (paste the SonarQube token you generated)

ID: sonarqube-token

Description: SonarQube Authentication Token

Click Save



**e. Configure SonarQube Scanner Tool**



Go to Manage Jenkins → Global Tool Configuration

Scroll to SonarQube Scanner section

Click Add SonarQube Scanner

Configure:

 Name: SonarQube Scanner

 Check Install automatically

 Version: Select latest version

Click Save



**f. Create SonarQube Configuration File**



cd /home/ubuntu/sample-app



\# Add to git

git add sonar-project.properties

git commit -m "Add SonarQube configuration"



g. Update Jenkins Pipeline with SonarQube Integration



###### **Set Up Automated Docker Hub Push**



Configure Docker Hub Credentials

Go to Manage Jenkins → Manage Credentials.

Click on (global) domain.

Click Add Credentials.



Configure the credentials:

Kind: Username with password

Username: Your Docker Hub username

Password: Your Docker Hub password or access token

ID: dockerhub-credentials

Description: Docker Hub Login Credentials

Click OK to save.

###### 

###### **Trigger Pipeline on Code Changes and View Build Results**



1. **Configure Webhook for Automatic Triggers**



Since we're working in a local environment, we'll simulate automatic triggers using Jenkins polling.



Go to your pipeline job configuration

In Build Triggers section, check Poll SCM

Set schedule to: H/2 \* \* \* \* (polls every 2 minutes)

Click Save



OR 



chmod +x ~/webhook-listener.py



\# Build and run webhook container

docker build -f Dockerfile.webhook -t webhook-listener .

docker run -d --name webhook-listener \\

&nbsp;   -p 8081:8081 \\

&nbsp;   --network host \\

&nbsp;   webhook-listener



\# Test the webhook trigger

curl -X POST http://localhost:8081/webhook/build \\

&nbsp;   -H "Content-Type: application/json" \\

&nbsp;   -d '{"repository": "jenkins-docker-demo", "branch": "master"}'



**2. Set Up Git Repository Monitoring**



For a more realistic setup, let's create a local Git repository that Jenkins can monitor:



\# Create a bare repository to simulate remote repo

sudo mkdir -p /opt/git-repos

sudo git init --bare /opt/git-repos/sample-app.git

sudo chown -R jenkins:jenkins /opt/git-repos



\# Add remote to our existing repository

cd /home/ubuntu/sample-app

git remote add origin /opt/git-repos/sample-app.git

git push -u origin master



**3.  Update Pipeline to Use Git Repository**



Go to your pipeline job configuration

In Pipeline section, change from Pipeline script to Pipeline script from SCM

Configure:

 SCM: Git

 Repository URL: /opt/git-repos/sample-app.git

 Branch: \*/master

 Script Path: Jenkinsfile



**4. Create Jenkinsfile in Repository**



cd /home/ubuntu/sample-app



\# Commit and push Jenkinsfile

git add Jenkinsfile

git commit -m "Add Jenkinsfile for CI/CD pipeline"

git push origin master



**5a. Test the Complete Pipeline**



Click Build Now to run the updated pipeline.



Monitor the execution and verify that all stages complete successfully.



Check your Docker Hub repository to confirm the image was pushed successfully.



Verify the staging deployment by accessing:



http://localhost:3002



**5b. Test Automatic Pipeline Triggers**



a. Make a change to the application:

cd /home/ubuntu/sample-app



\# Update the application version

sed -i 's/"version": "1.0.0"/"version": "1.1.0"/' package.json

sed -i 's/version: '\\''1.0.0'\\''/version: '\\''1.1.0'\\''/' app.js



\# Commit and push changes

git add .

git commit -m "Update application version to 1.1.0"

git push origin master



b. Wait for Jenkins to detect the change (up to 2 minutes)

c. Observe the automatic pipeline execution



**6. Monitor Build Results and Metrics**



***View Build History and Trends***

In Jenkins dashboard, click on your pipeline job

Observe the Build History section showing recent builds

Click on Trend to see build success/failure trends

Click on individual build numbers to view:

 Console output

 Build artifacts

 Test results

 SonarQube analysis results



***Access SonarQube Dashboard***

Open http://localhost:9000 in your browser

Login with your SonarQube credentials

Click on your project sample-node-app

Review:

 Code quality metrics

 Security vulnerabilities

 Code coverage

 Technical debt

 Code smells and bugs



***Verify Application Deployment***

Open http://localhost:3000 to access the deployed application

Test the endpoints:

  Main endpoint: http://localhost:3000/

  Health check: http://localhost:3000/health



\# Test the deployed application

curl http://localhost:3000/

curl http://localhost:3000/health



\# Check running containers

docker ps | grep sample-app



***Build Metrics Dashboard***

chmod +x ~/collect-metrics.sh



\# Collect current metrics

~/collect-metrics.sh collect



\# Display dashboard

~/collect-metrics.sh dashboard



###### **Monitor and Manage Jenkins Builds from Docker Containers**



1. **Set Up Build Monitoring Dashboard**



Install the Blue Ocean plugin for better pipeline visualization:

Go to Manage Jenkins → Manage Plugins

Search for "Blue Ocean"

Install the plugin



Access Blue Ocean interface:

Click Open Blue Ocean from the Jenkins main menu

View your pipeline with enhanced visualization



**2. Create Docker-based Monitoring Script**



chmod +x ~/monitor-builds.sh



cd ~/

docker build -f Dockerfile.monitor -t jenkins-monitor .



\# Run the monitoring container

docker run -it --rm \\

&nbsp;   --name jenkins-monitor \\

&nbsp;   -v /var/run/docker.sock:/var/run/docker.sock \\

&nbsp;   --network host \\

&nbsp;   jenkins-monitor



###### **Troubleshooting**



**Jenkins Service Issues**



\# If Jenkins fails to start

sudo systemctl status jenkins

sudo journalctl -u jenkins



\# Check Jenkins logs

sudo tail -f /var/log/jenkins/jenkins.log



**Docker Permission Issues**



\# If Jenkins can't access Docker

sudo usermod -aG docker jenkins

sudo systemctl restart Jenkins



\# Or run Jenkins with Docker socket access

sudo chmod 666 /var/run/docker.sock



\# Test Docker access

sudo -u jenkins docker ps



**Pipeline Fails at Docker Build**: Docker build fails with "no space left on device"



\# Clean up Docker system

docker system prune -a -f

docker volume prune -f



\# Check disk space

df -h



**Cannot push to Docker Hub**: Authentication fails when pushing to Docker Hub



Verify Docker Hub credentials in Jenkins

Test manual login:

docker login -u your-username



Use Docker Hub access tokens instead of passwords



**SonarQube Connection Issues**



\# Check SonarQube service

sudo systemctl status sonarqube



\# Check SonarQube logs

sudo tail -f /opt/sonarqube/sonarqube/logs/sonar.log

Pipeline Failures

Check console output for specific error messages

Verify all required plugins are installed

Ensure proper credentials are configured

Check file permissions and paths



**Container Tests Fail**: Tests fail inside Docker containers



\# Debug by running container interactively

docker run -it --rm -v $(pwd):/app -w /app node:16-alpine sh



\# Inside container, run commands manually

npm install

npm test

###### 

##### **Best Practices**



Security Best Practices

Credential Management: Using Jenkins credential store for sensitive information

User Permissions: Proper user separation between Jenkins and system users

Container Security: Running containers with non-root users where possible



CI/CD Best Practices

Pipeline as Code: Using Jenkinsfile for version-controlled pipeline definitions

Automated Testing: Including automated tests in the pipeline

Quality Gates: Implementing SonarQube quality gates to prevent poor code deployment

Artifact Management: Proper cleanup of old Docker images

Notification System: Email notifications for build status



Docker Best Practices

Multi-stage Builds: Using appropriate base images

Layer Optimization: Minimizing Docker image layers

Security Scanning: Including security analysis in the pipeline

Resource Management: Proper container lifecycle management

