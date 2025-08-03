###### **Docker and Selenium Testing**



**1. Setup**



\# Pull the latest Selenium standalone Chrome image

docker pull selenium/standalone-chrome



\# Verify the image was downloaded successfully

docker images | grep selenium



\# Run Selenium container in detached mode

docker run -d \\

&nbsp; --name selenium-chrome \\

&nbsp; -p 4444:4444 \\

&nbsp; -p 7900:7900 \\

&nbsp; --shm-size=2g \\

&nbsp; selenium/standalone-chrome



\# Test Selenium hub status using curl

curl -s http://localhost:4444/wd/hub/status | python3 -m json.tool



\# Alternative: Check container logs

docker logs selenium-chrome



**2. Python Settings**



pip3 install -r requirements.txt

conftest.py



**3. Run the Test Suite**



\# Run tests with verbose output and HTML report

pytest tests/ -v --html=reports/selenium\_test\_report.html --self-contained-html



\# Run specific test class

pytest tests/test\_web\_automation.py::TestWebAutomation::test\_google\_search -v



\# Run tests with custom markers (if any)

pytest tests/ -v -m "not slow"



**4. Advanced Docker Configuration for Testing**



Create Docker-Compose for Selenium Grid

Create Dockerfile for test runner

Create updated conftest.py for Grid setup



**5. Jenkins Integration for Continuous Testing**



mkdir jenkins\_home

chmod 777 jenkins\_home



\# Run Jenkins in Docker

docker run -d \\

&nbsp; --name jenkins \\

&nbsp; -p 8080:8080 \\

&nbsp; -p 50000:50000 \\

&nbsp; -v $(pwd)/jenkins\_home:/var/jenkins\_home \\

&nbsp; -v /var/run/docker.sock:/var/run/docker.sock \\

&nbsp; -v $(which docker):/usr/bin/docker \\

&nbsp; jenkins/jenkins:lts



\# Get initial admin password

echo "Waiting for Jenkins to start..."

sleep 30

docker exec jenkins cat /var/jenkins\_home/secrets/initialAdminPassword



\# Create Jenkinsfile and Jenkins Job config script

chmod +x setup\_jenkins\_job.sh



\# Start the complete testing infrastructure

docker-compose up -d



\# Wait for services to be ready

echo "Waiting for Selenium Grid to be ready..."

sleep 30



\# Check Selenium Grid status

curl -s http://localhost:4444/wd/hub/status | python3 -m json.tool



\# Run tests against the Grid

pytest tests/ -v --html=reports/grid\_test\_report.html --self-contained-html



\# View running containers

docker ps



**6. Monitoring**



\# Create monitoring script \& Make monitoring script executable

chmod +x monitor\_tests.sh



\# Run monitoring

./monitor\_tests.sh



**7. Troubleshooting**



Issue 1: Container Memory Problems: If you encounter memory-related issues:

\# Increase shared memory for Chrome

docker run -d --name selenium-chrome --shm-size=2g selenium/standalone-chrome

\# Check container memory usage

docker stats selenium-chrome



Issue 2: Port Conflicts: If ports are already in use:

\# Check what's using port 4444

sudo netstat -tulpn | grep 4444

\# Use different ports

docker run -d -p 4445:4444 selenium/standalone-chrome



Issue 3: Test Timeouts

\# Increase timeout in conftest.py

\# driver.implicitly\_wait(20)  # Increase from 10 to 20 seconds

\# Check Selenium hub logs

docker logs selenium-hub



Issue 4: Browser Crashes

\# Increase shared memory

docker run -d --shm-size=2g selenium/standalone-chrome

\# Check Chrome node logs

docker logs chrome-node

