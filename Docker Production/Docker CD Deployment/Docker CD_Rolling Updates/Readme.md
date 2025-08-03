##### Rolling Updates with Docker



1. **Initialize Docker Swarm mode**

docker swarm init



\# Verify swarm status

docker info | grep Swarm



**2. Build the first version**



**a.**

docker build -t webapp:v1.0 .



\# Verify the image was created

docker images | grep webapp



b.

\# Create a service with 3 replicas

docker service create \\

&nbsp; --name webapp \\

&nbsp; --replicas 3 \\

&nbsp; --publish 8080:80 \\

&nbsp; webapp:v1.0



\# Verify service creation

docker service ls



\# Check service status

docker service ps webapp



c.

\# Test the application

curl http://localhost:8080



**3.  Build Version 2**

docker build -t webapp:v2.0 .



\# Verify both versions exist

docker images | grep webapp



\# Configure update parameters

docker service update \\

&nbsp; --update-delay 10s \\

&nbsp; --update-parallelism 1 \\

&nbsp; --update-failure-action rollback \\

&nbsp; webapp



Parameter Explanation: 

• --update-delay 10s: Wait 10 seconds between updating each replica 

• --update-parallelism 1: Update one replica at a time 

• --update-failure-action rollback: Automatically rollback if update fails



**4. Ensure Zero Downtime During Updates**



a. Monitor Service Before Update



\# In a new terminal, monitor the service

watch -n 1 'docker service ps webapp'



\# Continuous testing script

while true; do

&nbsp; echo "$(date): $(curl -s http://localhost:8080 | grep -o 'Version \[0-9.]\*')"

&nbsp; sleep 2

done



b. Perform rolling update to version 2.0



docker service update --image webapp:v2.0 webapp



\# Monitor the update progress

docker service ps webapp



c. Verify Zero Downtime



Observe the monitoring terminals:

• The watch command should show old replicas being replaced gradually 

• The curl loop should show a mix of Version 1.0 and Version 2.0 responses 

• There should be no connection errors or timeouts



**5. Roll Back to Previous Version**



Simulate a Problem with Version 2



Build the problematic version:

docker build -t webapp:v3.0 .



\# Update to the problematic version

docker service update --image webapp:v3.0 webapp



\# Monitor the deployment

docker service ps webapp



\# Rollback to previous version

docker service rollback webapp



\# Verify rollback status

docker service ps webapp



\# Check that we're back to version 2.0

curl http://localhost:8080 | grep "Version"



\# Rollback to version 1.0 specifically

docker service update --image webapp:v1.0 webapp



\# Verify the rollback

curl http://localhost:8080 | grep "Version"



**6. Monitoring**



chmod +x monitor-update.sh



\# Follow service logs

docker service logs -f webapp



\# In another terminal, check individual container logs

docker ps | grep webapp

docker logs -f <container\_id>



Build and deploy with health checks:



docker build -t webapp:v4.0 .



\# Update service with health check awareness

docker service update \\

&nbsp; --image webapp:v4.0 \\

&nbsp; --health-cmd "curl -f http://localhost/health || exit 1" \\

&nbsp; --health-interval 30s \\

&nbsp; --health-timeout 3s \\

&nbsp; --health-retries 3 \\

&nbsp; webapp



\# Get detailed service information

docker service inspect webapp --pretty



\# Monitor resource usage

docker stats $(docker ps -q --filter "label=com.docker.swarm.service.name=webapp")



\# Check service events

docker system events --filter service=webapp



\# Get service update history

docker service ps webapp --format "table {{.ID}}\\t{{.Name}}\\t{{.Image}}\\t{{.CurrentState}}\\t{{.Error}}"



**7. Troubleshooting** 



**Issue 1: Update Stuck or Failing**



\# Check service status

docker service ps webapp



\# Force remove failed tasks

docker service update --force webapp



\# Check Docker daemon logs

sudo journalctl -u docker.service -f



**Issue 2: Port Already in Use**



\# Check what's using the port

sudo netstat -tulpn | grep :8080



\# Kill the process using the port

sudo kill -9 <process\_id>



\# Or use a different port

docker service update --publish-rm 8080:80 --publish-add 8081:80 webapp



**Issue 3: Image Pull Failures**



\# Check image availability

docker images | grep webapp



\# Manually pull image

docker pull webapp:v2.0



\# Check Docker Hub connectivity

docker search nginx

