#### **Docker for HPC**



##### Create resources



Build the Docker image:

docker build -f Dockerfile.hpc-base -t hpc-base:latest .



Test the container with a simple run:

docker run --rm -it hpc-base:latest mpicc --version



Compile and test the MPI application:

docker run --rm -v $(pwd):/hpc hpc-base:latest bash -c 

cd /hpc \&\& 

mpicc -o hello\_mpi hello\_mpi.c \&\& 

mpirun -np 4 --allow-run-as-root ./hello\_mpi





Test the Python MPI application:

docker run --rm -v $(pwd):/hpc hpc-base:latest bash -c 

cd /hpc \&\& 

mpirun -np 4 --allow-run-as-root python3 hello\_mpi.py





##### Deploy a Distributed MPI Environment Using Docker



**Create a Docker Compose file for distributed MPI**



docker build -f Dockerfile.mpi-cluster -t mpi-cluster:latest .



Update the docker-compose file to use the new image:

sed -i 's/hpc-base:latest/mpi-cluster:latest/g' docker-compose.mpi.yml



**Start the MPI cluster:**

docker-compose -f docker-compose.mpi.yml up -d



**Verify all containers are running:**

docker-compose -f docker-compose.mpi.yml ps



**Test connectivity between containers:**

docker exec -it mpi-master bash -c "

ping -c 3 mpi-worker1 \&\& 

ping -c 3 mpi-worker2

"

**Create a hostfile for MPI:**

docker exec -it mpi-master bash -c "

echo 'mpi-master slots=2' > /hpc/hostfile

echo 'mpi-worker1 slots=2' >> /hpc/hostfile  

echo 'mpi-worker2 slots=2' >> /hpc/hostfile

cat /hpc/hostfile

"



**Test distributed MPI execution:**

docker exec -it mpi-master bash -c "

cd /hpc \&\&

mpicc -o hello\_mpi hello\_mpi.c \&\&

mpirun -np 6 --hostfile hostfile --allow-run-as-root ./hello\_mpi

"



##### Test the Performance of Dockerized HPC Workloads



**Run Performance Benchmarks**



docker exec -it mpi-master bash -c "

cd /hpc \&\&

mpicc -o pi\_calculation pi\_calculation.c -lm \&\&

echo 'Running with 1 process:' \&\&

mpirun -np 1 --allow-run-as-root ./pi\_calculation \&\&

echo 'Running with 2 processes:' \&\&

mpirun -np 2 --allow-run-as-root ./pi\_calculation \&\&

echo 'Running with 4 processes:' \&\&

mpirun -np 4 --allow-run-as-root ./pi\_calculation \&\&

echo 'Running with 6 processes (distributed):' \&\&

mpirun -np 6 --hostfile hostfile --allow-run-as-root ./pi\_calculation

**"**

**Run the memory bandwidth test:**



docker exec -it mpi-master bash -c "

cd /hpc \&\&

echo 'Memory bandwidth test with different process counts:' \&\&

mpirun -np 1 --allow-run-as-root python3 memory\_test.py \&\&

mpirun -np 2 --allow-run-as-root python3 memory\_test.py \&\&

mpirun -np 4 --allow-run-as-root python3 memory\_test.py \&\&

mpirun -np 6 --hostfile hostfile --allow-run-as-root python3 memory\_test.py

"

**Monitor Resource Usage**

chmod +x monitor\_resources.sh

./monitor\_resources.sh \&

MONITOR\_PID=$!



**Run a benchmark while monitoring:**

docker exec -it mpi-master bash -c "

cd /hpc \&\&

mpirun -np 6 --hostfile hostfile --allow-run-as-root ./pi\_calculation

"



**Stop monitoring:**

kill $MONITOR\_PID

##### 

##### Scale the Containerized HPC Tasks Across Multiple Nodes



1. Cluster setup

docker swarm init

Note: In a real multi-node setup, you would join additional physical nodes to the swarm. For this lab, we'll simulate scaling using multiple containers.



2\. Deploy the HPC service stack:

docker stack deploy -c docker-compose.swarm.yml hpc-stack



3\. Test Scaling Capabilities

docker service ps hpc-stack\_hpc-service

docker service scale hpc-stack\_hpc-service=6



4\. Test Cross-Container Communication

\# Get one of the service containers

CONTAINER\_ID=$(docker ps --filter "name=hpc-stack\_hpc-service" --format "{{.ID}}" | head -1)



\# Copy the test script to the container

docker cp distributed\_test.py $CONTAINER\_ID:/hpc/



\# Execute the distributed test

docker exec -it $CONTAINER\_ID bash -c "

cd /hpc \&\&

mpirun -np 4 --allow-run-as-root python3 distributed\_test.py

"



Scale down the service:

docker service scale hpc-stack\_hpc-service=2



Test with fewer processes:

CONTAINER\_ID=$(docker ps --filter "name=hpc-stack\_hpc-service" --format "{{.ID}}" | head -1)

docker exec -it $CONTAINER\_ID bash -c "

cd /hpc \&\&

mpirun -np 2 --allow-run-as-root python3 distributed\_test.py

"



##### Integrate with Cloud Platforms for Scalable Computing



1. Create Cloud-Ready HPC Images

docker build -f Dockerfile.cloud-hpc -t cloud-hpc:latest .



2\. Create Cloud Deployment Configuration

chmod +x cloud\_scaling\_simulator.py



3\. Test the scaling simulator:



\# Check current status

python3 cloud\_scaling\_simulator.py status



\# Scale to 4 workers

python3 cloud\_scaling\_simulator.

