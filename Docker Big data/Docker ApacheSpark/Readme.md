##### Docker ApacheSpark



**Pull and Run Apache Spark Docker Image**



1\.

\# Search for official Apache Spark images

docker search apache/spark



\# Pull the official Apache Spark image

docker pull apache/spark:latest



\# Verify the image was downloaded

docker images | grep spark



2\.

\# Run Spark in interactive mode to explore

docker run -it --name spark-test apache/spark:latest /bin/bash



\# Inside the container, check Spark installation

ls -la /opt/spark/

echo $SPARK\_HOME



\# Exit the container

exit



\# Remove the test container

docker rm spark-test



3\.

\# Run Spark shell in a container

docker run -it --rm \\

&nbsp; --name spark-shell \\

&nbsp; -p 4040:4040 \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-shell



\# Note: The Spark UI will be available at http://localhost:4040

Inside the Spark shell, try these basic commands:



// Create a simple RDD (Resilient Distributed Dataset)

val data = Array(1, 2, 3, 4, 5)

val distData = sc.parallelize(data)



// Perform a simple operation

val result = distData.map(x => x \* 2).collect()

println(result.mkString(", "))



// Exit Spark shell

:quit



**Set Up Spark with Master and Worker Nodes**



a.

\# Create a custom bridge network for Spark cluster

docker network create spark-network



\# Verify network creation

docker network ls | grep spark



b.

\# Start Spark Master container

docker run -d \\

&nbsp; --name spark-master \\

&nbsp; --network spark-network \\

&nbsp; -p 8080:8080 \\

&nbsp; -p 7077:7077 \\

&nbsp; -p 4040:4040 \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master



\# Check if master is running

docker ps | grep spark-master



\# View master logs

docker logs spark-master

The Spark Master UI will be available at http://localhost:8080



c.

\# Start first worker node

docker run -d \\

&nbsp; --name spark-worker-1 \\

&nbsp; --network spark-network \\

&nbsp; -p 8081:8081 \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077



\# Start second worker node

docker run -d \\

&nbsp; --name spark-worker-2 \\

&nbsp; --network spark-network \\

&nbsp; -p 8082:8081 \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077



\# Verify all containers are running

docker ps | grep spark



d.

\# Check cluster status through master logs

docker logs spark-master | tail -10



\# Check worker logs

docker logs spark-worker-1 | tail -5

docker logs spark-worker-2 | tail -5

Visit http://localhost:8080 in your browser to see the Spark Master UI with connected workers.



**Submit Spark Jobs to the Cluster**



1\.

Create a Spark Application



2\.

Submit Job to Cluster

\# Copy data and application to master container

docker cp ~/spark-lab/data/sample.txt spark-master:/data/

docker cp ~/spark-lab/apps/wordcount.py spark-master:/apps/



\# Submit the Spark job to the cluster

docker exec spark-master /opt/spark/bin/spark-submit \\

&nbsp; --master spark://spark-master:7077 \\

&nbsp; --deploy-mode client \\

&nbsp; --executor-memory 1g \\

&nbsp; --total-executor-cores 2 \\

&nbsp; /apps/wordcount.py /data/sample.txt



3\.

Monitor Job Execution

\# Check application logs

docker logs spark-master | grep -A 10 -B 10 "WordCount"



\# View running applications in Spark UI

echo "Visit http://localhost:8080 to see running applications"

echo "Visit http://localhost:4040 to see application details (when running)"



4\.

Configure Persistent Storage for Spark Data

Subtask 4.1: Create Docker Volumes

\# Create volumes for persistent storage

docker volume create spark-data

docker volume create spark-logs

docker volume create spark-apps



\# List created volumes

docker volume ls | grep spark



5\.

First, stop the existing cluster:



\# Stop and remove existing containers

docker stop spark-master spark-worker-1 spark-worker-2

docker rm spark-master spark-worker-1 spark-worker-2

Start the cluster with persistent volumes:



\# Start master with persistent storage

docker run -d \\

&nbsp; --name spark-master \\

&nbsp; --network spark-network \\

&nbsp; -p 8080:8080 \\

&nbsp; -p 7077:7077 \\

&nbsp; -p 4040:4040 \\

&nbsp; -v spark-data:/data \\

&nbsp; -v spark-logs:/opt/spark/logs \\

&nbsp; -v spark-apps:/apps \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master



\# Start workers with persistent storage

docker run -d \\

&nbsp; --name spark-worker-1 \\

&nbsp; --network spark-network \\

&nbsp; -p 8081:8081 \\

&nbsp; -v spark-data:/data \\

&nbsp; -v spark-logs:/opt/spark/logs \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077



docker run -d \\

&nbsp; --name spark-worker-2 \\

&nbsp; --network spark-network \\

&nbsp; -p 8082:8081 \\

&nbsp; -v spark-data:/data \\

&nbsp; -v spark-logs:/opt/spark/logs \\

&nbsp; apache/spark:latest \\

&nbsp; /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077



6\.

\# Copy large dataset

docker cp ~/spark-lab/data/large\_dataset.txt spark-master:/data/



\# Run job with larger dataset

docker exec spark-master /opt/spark/bin/spark-submit \\

&nbsp; --master spark://spark-master:7077 \\

&nbsp; --deploy-mode client \\

&nbsp; --executor-memory 1g \\

&nbsp; --total-executor-cores 2 \\

&nbsp; /apps/wordcount.py /data/large\_dataset.txt



**Use Docker Compose to Manage the Spark Cluster**



1\.

Stop existing containers

docker stop spark-master spark-worker-1 spark-worker-2

docker rm spark-master spark-worker-1 spark-worker-2



2\.

Create a Docker Compose file:



3\.

\# Navigate to the lab directory

cd ~/spark-lab



\# Start the Spark cluster

docker-compose up -d



\# Check cluster status

docker-compose ps



\# View logs from all services

docker-compose logs --tail=10



4\.

Scale Workers with Docker Compose

\# Scale worker nodes to 3 instances

docker-compose up -d --scale spark-worker-1=2 --scale spark-worker-2=2



\# Check running containers

docker-compose ps



\# View cluster in Spark UI

echo "Visit http://localhost:8080 to see all workers"



5\.

Submit Jobs Using Docker Compose



**Advance Job**



**Troubleshooting**



Issue 1: Container Connection Problems

\# Check network connectivity

docker network inspect spark-network



\# Verify containers are on the same network

docker inspect spark-master | grep NetworkMode

docker inspect spark-worker-1 | grep NetworkMode



Issue 2: Port Conflicts

\# Check if ports are already in use

netstat -tulpn | grep :8080

netstat -tulpn | grep :7077



\# Use different ports if needed

docker run -p 8090:8080 -p 7078:7077 ...



Issue 3: Memory Issues

\# Check container resource usage

docker stats



\# Adjust memory settings in Docker Compose

\# Add to service configuration:

\# mem\_limit: 2g

\# memswap\_limit: 2g



Issue 4: Volume Mount Problems

\# Check volume status

docker volume inspect spark-data



\# Verify volume mounts

docker inspect spark-master | grep -A 10 Mounts





