**Integration Testing**



\# Build and start the test environment

docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit



\# Check if all services are running (in a new terminal if needed)

docker-compose -f docker-compose.test.yml ps



\# View test results

docker-compose -f docker-compose.test.yml logs tests



\# Clean up

docker-compose -f docker-compose.test.yml down -v



b.

\# Start Jenkins using Docker

docker run -d \\

&nbsp; --name jenkins \\

&nbsp; -p 8080:8080 \\

&nbsp; -p 50000:50000 \\

&nbsp; -v ~/jenkins\_home:/var/jenkins\_home \\

&nbsp; -v /var/run/docker.sock:/var/run/docker.sock \\

&nbsp; -v $(which docker):/usr/bin/docker \\

&nbsp; --group-add $(getent group docker | cut -d: -f3) \\

&nbsp; jenkins/jenkins:lts



\# Wait for Jenkins to start and get the initial admin password

echo "Waiting for Jenkins to start..."

sleep 30



\# Get the initial admin password

docker exec jenkins cat /var/jenkins\_home/secrets/initialAdminPassword



\#Configure Jenkins



c.

Create Jenkins Job

In Jenkins, click New Item

Enter name: docker-ci-integration-tests

Select Pipeline and click OK

In the configuration:

Under Pipeline, select Pipeline script from SCM

SCM: Git

Repository URL: Your repository URL (or use local path for testing)

Script Path: jenkins/Jenkinsfile

Click Save

###### 

###### **Monitor and review results** 

a. With scripts

b. Create Automated Test Runner Script (Add)

