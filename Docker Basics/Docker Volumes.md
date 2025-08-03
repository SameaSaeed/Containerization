#### **Docker Volumes**



**List volumes**

docker volume ls



**Create Volumes**

docker volume create my-persistent-data



**Inspect Volumes**

docker volume inspect my-persistent-data



**Remove specific volumes**

docker volume rm my-persistent-data mysql-data app-logs-demo app-config-demo restored-volume 2>/dev/null || true



**Using Volumes with Real Applications**



##### Run a web server with persistent storage



\# Run nginx with a volume for web content

docker run -d --name web-server \\

&nbsp; -v my-persistent-data:/usr/share/nginx/html \\

&nbsp; -p 8080:80 \\

&nbsp; nginx:alpine



\# Run a temporary container to add content

docker run --rm -v my-persistent-data:/data ubuntu:20.04 \\

&nbsp; bash -c "echo '<h1>Hello from Persistent Volume!</h1>' > /data/index.html"



\# Check if the web server is running

curl http://localhost:8080



\# Stop and remove the container

docker stop web-server

docker rm web-server



\# Start a new web server container with the same volume

docker run -d --name web-server-new \\

&nbsp; -v my-persistent-data:/usr/share/nginx/html \\

&nbsp; -p 8080:80 \\

&nbsp; nginx:alpine



\# The content should still be there

curl http://localhost:8080



**b. Explore volume contents from the host**



\# Find the volume-mount-point

VOLUME\_PATH=$(docker volume inspect my-persistent-data --format '{{.Mountpoint}}')

echo "Volume is mounted at: $VOLUME\_PATH"



\# List contents (requires sudo on most systems)

sudo ls -la $VOLUME\_PATH

sudo cat $VOLUME\_PATH/persistent-file.txt



docker volume prune

docker volume rm app-logs



**c. Create a backup using a temporary container**



docker run --rm -v my-persistent-data:/data -v $(pwd):/backup ubuntu:20.04 \\

&nbsp; tar czf /backup/volume-backup.tar.gz -C /data .



\#Verify backup creation

ls -la volume-backup.tar.gz



\# Create a new volume

docker volume create restored-volume



\# Restore data to the new volume

docker run --rm -v restored-volume:/data -v $(pwd):/backup ubuntu:20.04 \\

&nbsp; bash -c "cd /data \&\& tar xzf /backup/volume-backup.tar.gz"



\# Check the restored data

docker run --rm -v restored-volume:/data ubuntu:20.04 \\

&nbsp; bash -c "ls -la /data \&\& cat /data/persistent-file.txt"

##### 

##### Data Persistence Across Container Restarts



\# Create a volume for MySQL data

docker volume create mysql-data



\# Run MySQL container with persistent volume

docker run -d --name mysql-db \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=mypassword \\

&nbsp; -e MYSQL\_DATABASE=testdb \\

&nbsp; -v mysql-data:/var/lib/mysql \\

&nbsp; mysql:8.0



\# Wait a moment for MySQL to start

sleep 30



\# Connect to MySQL and create some data

docker exec -it mysql-db mysql -uroot -pmypassword testdb



-- Inside MySQL shell

CREATE TABLE users (

&nbsp;   id INT AUTO\_INCREMENT PRIMARY KEY,

&nbsp;   name VARCHAR(100),

&nbsp;   email VARCHAR(100)

);



INSERT INTO users (name, email) VALUES 

('John Doe', 'john@example.com'),

('Jane Smith', 'jane@example.com');



SELECT \* FROM users;

exit



\# Stop and remove the MySQL container

docker stop mysql-db

docker rm mysql-db



\# Start new MySQL container with the same data volume

docker run -d --name mysql-db-new \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=mypassword \\

&nbsp; -e MYSQL\_DATABASE=testdb \\

&nbsp; -v mysql-data:/var/lib/mysql \\

&nbsp; mysql:8.0



\# Wait for MySQL to start

sleep 30



\# Connect and check if data is still there

docker exec -it mysql-db-new mysql -uroot -pmypassword testdb



-- Inside MySQL shell

SELECT \* FROM users;

-- Your data should still be there!

exit



##### Application Log Persistence



\# Create a volume for logs

docker volume create app-logs-demo



\# Run a container that generates logs

docker run -d --name log-generator \\

&nbsp; -v app-logs-demo:/var/log/app \\

&nbsp; ubuntu:20.04 \\

&nbsp; bash -c "while true; do echo \\$(date): Log entry >> /var/log/app/application.log; sleep 5; done"



\# Check logs being generated

docker exec log-generator tail -f /var/log/app/application.log

Press Ctrl+C to stop monitoring



\# Stop and remove the container

docker stop log-generator

docker rm log-generator



\# Start a new container with the same volume

docker run -d --name log-generator-new \\

&nbsp; -v app-logs-demo:/var/log/app \\

&nbsp; ubuntu:20.04 \\

&nbsp; bash -c "while true; do echo \\$(date): New container log >> /var/log/app/application.log; sleep 5; done"



\# Check that old logs are preserved and new ones are being added

docker exec log-generator-new cat /var/log/app/application.log



\# Create volume for configuration

docker volume create app-config-demo



\# Create initial configuration

docker run --rm -v app-config-demo:/config ubuntu:20.04 \\

&nbsp; bash -c "echo 'server\_port=8080' > /config/app.conf \&\& echo 'debug\_mode=true' >> /config/app.conf"



\# Run application that reads configuration

docker run -d --name config-app \\

&nbsp; -v app-config-demo:/etc/app \\

&nbsp; ubuntu:20.04 \\

&nbsp; bash -c "while true; do echo 'Reading config:'; cat /etc/app/app.conf; sleep 10; done"



\# Check application output

docker logs config-app



\# Update configuration while app is running

docker run --rm -v app-config-demo:/config ubuntu:20.04 \\

&nbsp; bash -c "echo 'server\_port=9090' > /config/app.conf \&\& echo 'debug\_mode=false' >> /config/app.conf"



\# Restart the application

docker stop config-app

docker rm config-app



docker run -d --name config-app-new \\

&nbsp; -v app-config-demo:/etc/app \\

&nbsp; ubuntu:20.04 \\

&nbsp; bash -c "while true; do echo 'Reading config:'; cat /etc/app/app.conf; sleep 10; done"



\# Check that updated configuration persisted

docker logs config-app-new



##### Troubleshooting 



\# Check volume permissions

docker run --rm -v my-persistent-data:/data ubuntu:20.04 ls -la /data



\# Fix permissions if needed

docker run --rm -v my-persistent-data:/data ubuntu:20.04 chmod 755 /data



\# Create the volume first

docker volume create missing-volume



\# Then use it with containers

docker run -v missing-volume:/data ubuntu:20.04



\# Find containers using the volume

docker ps -a --filter volume=my-persistent-data



\# Stop and remove containers first

docker stop container-name

docker rm container-name



\# Then remove the volume

docker volume rm my-persistent-data



