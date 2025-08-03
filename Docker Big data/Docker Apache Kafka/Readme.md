##### Docker and Apache Kafka



1\. Start the Kafka Cluster



\# Start all services in detached mode

docker-compose up -d



\# Verify all containers are running

docker-compose ps



\# Check container logs

docker-compose logs kafka

docker-compose logs zookeeper



2\. Verify Kafka Installation



\# Check if Kafka is listening on the correct port

docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list



\# Create a test topic to verify functionality

docker exec kafka-broker kafka-topics --create --topic test-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1



\# List topics to confirm creation

docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list



3\. Set up Producer and Consumer Applications inside Docker Containers



Build and Run Producer and Consumer

\# Build and start all services including producer and consumer

docker-compose up -d --build



\# Check if all containers are running

docker-compose ps



\# View producer logs

docker-compose logs -f producer



\# In another terminal, view consumer logs

docker-compose logs -f consumer



###### **Use kafkacat to Send and Receive Messages from Kafka Topics**



**Install and Configure kafkacat**



\# Install kafkacat on the host system

sudo apt-get update

sudo apt-get install -y kafkacat



\# Alternative: Use kafkacat in a Docker container

docker run --rm -it --network kafka-docker-lab\_kafka-network confluentinc/cp-kafkacat:latest kafkacat -b kafka:29092 -L



**Create Topics Using kafkacat**



\# Create additional topics for testing

docker exec kafka-broker kafka-topics --create --topic user-events --bootstrap-server localhost:9092 --partitions 2 --replication-factor 1



docker exec kafka-broker kafka-topics --create --topic system-logs --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1



\# List all topics

docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list



**Send Messages Using kafkacat**



\# Send messages to user-events topic

echo '{"user\_id": "user123", "action": "login", "timestamp": "2024-01-15T10:30:00Z"}' | \\

kafkacat -b localhost:9092 -t user-events -P



echo '{"user\_id": "user456", "action": "purchase", "amount": 99.99, "timestamp": "2024-01-15T10:31:00Z"}' | \\

kafkacat -b localhost:9092 -t user-events -P



echo '{"user\_id": "user789", "action": "logout", "timestamp": "2024-01-15T10:32:00Z"}' | \\

kafkacat -b localhost:9092 -t user-events -P



\# Send multiple messages from a file

cat > sample\_messages.txt << EOF

{"level": "INFO", "service": "web-server", "message": "Server started successfully"}

{"level": "ERROR", "service": "database", "message": "Connection timeout"}

{"level": "WARN", "service": "cache", "message": "Memory usage high"}

EOF



\# Send messages from file

kafkacat -b localhost:9092 -t system-logs -P -l sample\_messages.txt



**Consume Messages Using kafkacat**



\# Consume messages from user-events topic

kafkacat -b localhost:9092 -t user-events -C -o beginning



\# Consume messages with key and offset information

kafkacat -b localhost:9092 -t user-events -C -f 'Key: %k, Offset: %o, Message: %s\\n'



\# Consume from specific partition

kafkacat -b localhost:9092 -t user-events -C -p 0 -o beginning



\# Consume messages from system-logs topic

kafkacat -b localhost:9092 -t system-logs -C -o beginning





**Advanced kafkacat Operations**



\# Get topic metadata

kafkacat -b localhost:9092 -L



\# Get specific topic metadata

kafkacat -b localhost:9092 -L -t user-events



\# Consume with consumer group

kafkacat -b localhost:9092 -t user-events -C -G test-group



\# Produce with key

echo "user123:{'action': 'click', 'page': 'homepage'}" | \\

kafkacat -b localhost:9092 -t user-events -P -K:



###### **Monitor Kafka Cluster Health and Performance**



1. **Access Kafka UI Dashboard**



\# Ensure Kafka UI is running

docker-compose ps kafka-ui



\# Access Kafka UI in your browser

echo "Open your browser and navigate to: http://localhost:8080"



**2. Monitor Using JMX Metrics**

python3 kafka-monitor.py



**3. Create Performance Monitoring Script**

./performance\_monitor.sh



**4. Set Up Log Monitoring**

./monitor\_log.sh



###### **Implement a Simple Stream Processing Application within Docker**



1. Create files



2\. Create Required Topics and Start Stream Processing

\# Create topics for stream processing

docker exec kafka-broker kafka-topics --create --topic processed-sensor-data --bootstrap-server localhost:9092 --partitions 2 --replication-factor 1



docker exec kafka-broker kafka-topics --create --topic sensor-alerts --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1



\# Build and start stream processing services

docker-compose up -d --build



\# Verify all services are running

docker-compose ps



\# Monitor stream processor logs

docker-compose logs -f stream-processor



\# In another terminal, monitor alert consumer logs

docker-compose logs -f alert-consumer



3\. Test Stream Processing Pipeline



\# Test the complete pipeline by consuming processed data

kafkacat -b localhost:9092 -t processed-sensor-data -C -f 'Key: %k\\nValue: %s\\n\\n'



\# Monitor alerts

kafkacat -b localhost:9092 -t sensor-alerts -C -f 'ALERT - Key: %k\\nValue: %s\\n\\n'



\# Check all topics

docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list



###### **Troubleshooting** 



Issue 1: Containers Not Starting

\# Check container status

docker-compose ps



\# View container logs

docker-compose logs \[service-name]



\# Restart specific service

docker-compose restart \[service-name]



Issue 2: Connection Issues

\# Test network connectivity

docker network ls

docker network inspect kafka-docker-lab\_kafka-network



\# Test Kafka connectivity

docker exec kafka-broker kafka-broker-api-versions --bootstrap-server localhost:9092



Issue 3: Topic Creation Issues

\# List existing topics

docker exec kafka-broker kafka-topics --bootstrap-server localhost:9092 --list



\# Delete and recreate topic if needed

docker exec kafka-broker kafka-topics --delete --topic \[topic-name] --bootstrap-server localhost:9092

