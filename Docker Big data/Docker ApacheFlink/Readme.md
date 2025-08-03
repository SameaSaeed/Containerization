##### Docker and Apache Flink



1\. Deploy the Flink Cluster

docker-compose up -d



2\. Set Up Flink Job Manager and Task Manager



a. Verify Job Manager Configuration



Access the Flink Web Dashboard by opening your browser and navigating to:

http://localhost:8081

Note: If you're using a cloud machine, replace localhost with your machine's public IP address.



In the dashboard, you should see:

Job Manager: 1 instance running

Task Managers: 2 instances connected

Available Task Slots: 4 total (2 per task manager)



b. Inspect Cluster Configuration



Check the detailed configuration of your job manager:

docker exec flink-jobmanager cat /opt/flink/conf/flink-conf.yaml



Examine task manager configuration:

docker exec flink-taskmanager1 cat /opt/flink/conf/flink-conf.yaml



c. Verify Network Connectivity



Test communication between job manager and task managers:

docker exec flink-jobmanager ping -c 3 flink-taskmanager1

docker exec flink-jobmanager ping -c 3 flink-taskmanager2



Check the cluster status using Flink CLI:

docker exec flink-jobmanager flink list

###### 

###### **Submit a Stream Processing Job to the Flink Cluster**



1. Create a sample data generator

2\. Submit a Built-in Example Job



Flink comes with several example jobs. Let's submit the WordCount example:

docker exec flink-jobmanager flink run /opt/flink/examples/streaming/WordCount.jar



Check the job status in the web dashboard or via CLI:

docker exec flink-jobmanager flink list



3\. Start a socket text stream example that reads from a socket:

docker exec -d flink-jobmanager flink run /opt/flink/examples/streaming/SocketWindowWordCount.jar --hostname localhost --port 9999



In another terminal, create a socket server to send data:

docker exec -it flink-jobmanager nc -l 9999



Type some text and press Enter. You can type phrases like:

hello world

apache flink streaming

real time processing

big data analytics



4\. Monitor Job Execution

docker exec flink-jobmanager flink list -r



Check job details in the web dashboard:



Navigate to Jobs tab

Click on your running job

Explore the Overview, Timeline, and Subtasks sections



###### **Scale the Flink Cluster and Adjust Resources**



1. Create docker-compose.scaled

2\. Scale Up the Cluster

Stop the current cluster and start the scaled version:



docker-compose down

docker-compose -f docker-compose-scaled.yml up -d

Verify the scaled cluster:



docker-compose -f docker-compose-scaled.yml ps

Check the web dashboard to confirm you now have:



3 Task Managers

12 Available Task Slots (4 per task manager)



3\. Dynamic Scaling with Docker Compose

docker-compose -f docker-compose-scaled.yml up -d --scale taskmanager1=2



4\. Adjust Resource Allocation

Create a config file



###### **Monitor the Flink Cluster's Performance and Metrics**





1. Access Built-in Monitoring Dashboard



Navigate to the Flink Web Dashboard and explore different monitoring sections:

Overview: Cluster summary and resource utilization

Jobs: Running and completed job details

Task Managers: Individual task manager metrics

Job Manager: Job manager configuration and logs



2\. Monitor Resource Utilization



Check CPU and memory usage of containers:

docker stats flink-jobmanager flink-taskmanager1 flink-taskmanager2 flink-taskmanager3



Monitor container logs for performance insights:

docker-compose -f docker-compose-scaled.yml logs --tail=50 jobmanager

docker-compose -f docker-compose-scaled.yml logs --tail=50 taskmanager1



3\. Create a Performance Monitoring Script

4\. Setup log analysis script

5\. Performance Testing



Submit a more intensive job to test cluster performance:

docker exec flink-jobmanager flink run -p 8 /opt/flink/examples/streaming/WordCount.jar



Monitor the job execution:

watch -n 2 'docker exec flink-jobmanager flink list -r'



###### **Troubleshooting**



Issue 1: Containers Not Starting

docker-compose logs

docker system df

docker system prune -f



Issue 2: Task Managers Not Connecting



Verify network connectivity:

docker network ls

docker network inspect flink-docker-lab\_flink-network



Issue 3: Out of Memory Errors

Increase container memory limits in docker-compose.yml:



services:

&nbsp; jobmanager:

&nbsp;   # ... other configuration

&nbsp;   deploy:

&nbsp;     resources:

&nbsp;       limits:

&nbsp;         memory: 2G

&nbsp;       reservations:

&nbsp;         memory: 1G



Issue 4: Port Conflicts



\# If port 8081 is already in use:

netstat -tulpn | grep 8081



\# Change the port mapping in docker-compose.yml

ports:

&nbsp; - "8082:8081"  # Use port 8082 instead

