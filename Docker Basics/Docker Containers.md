##### **Docker Containers**



Runnning Containers



docker run -d --name my-ubuntu-container ubuntu sleep 3600

docker run -d --name persistent-container ubuntu sleep 7200

docker run -d --name app-server-1 --network app-network nginx:alpine	(Run container on custom network)

docker run -d --name web-public --network app-network -p 8080:80 nginx:alpine	(Run a container with portmapping)

docker run -it --name persistent-container -v my-persistent-data:/data ubuntu:20.04 bash 

(Run container with volume mounted to /data )



docker run -it --name new-persistent-container -v my-persistent-data:/data ubuntu:20.04 bash

(Mount the same volume to a new container)



docker run -it --name multi-volume-container \\

&nbsp; -v database-data:/var/lib/database \\

&nbsp; -v app-logs:/var/log/app \\

&nbsp; -v app-config:/etc/app \\

&nbsp; ubuntu:20.04 bash

(Run a container with multiple volume mounts)



\# Inside the container

\# Create database data

mkdir -p /var/lib/database

echo "user\_data=sample" > /var/lib/database/users.db



\# Create log data

mkdir -p /var/log/app

echo "$(date): Application started" > /var/log/app/app.log



\# Create configuration data

mkdir -p /etc/app

echo "debug=true" > /etc/app/config.ini

echo "port=8080" >> /etc/app/config.ini



\# Verify all data

ls -la /var/lib/database/

ls -la /var/log/app/

ls -la /etc/app/

exit



**Executing commands in already running containers**



docker exec -it my-ubuntu-container /bin/bash

docker exec persistent-container ls -la /home/

docker exec -it --user root container-name /bin/bash : Run exec as root user



Inspecting containers



docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-ubuntu-container

docker inspect --format='{{.State.Status}}' my-ubuntu-container

docker inspect --format='{{.Config.Image}}' my-ubuntu-container

docker inspect --format='{{.Created}}' my-ubuntu-container

docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' auto-restart/ restart-on-failure

docker inspect my-ubuntu-container short-lived-ubuntu-container



Stopping containers



docker start persistent-container

docker stop my-ubuntu-container

docker stop $(docker ps -q): Stop all running containers

docker rm my-ubuntu-container

docker rm -f test-container

docker rm $(docker ps -aq) : Remove all containers

