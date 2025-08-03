##### Docker \& Performance Benchmarking



**Deploy the Web Application**

docker build -f Dockerfile.webapp -t test-webapp:latest .



a. Create a Docker network for our testing environment:

docker network create performance-test-network



Run the web application container:

docker run -d \\

    --name test-webapp \\

    --network performance-test-network \\

    -p 3000:3000 \\

    test-webapp:latest



b. Verify the application is running:

\# Wait a few seconds for the app to start

sleep 5



\# Test the application

curl http://localhost:3000/

curl http://localhost:3000/cpu-intensive

curl http://localhost:3000/memory



**Run a basic load test with Apache Bench**



Build the Apache Bench Docker image

docker build -f Dockerfile.ab -t apache-bench:latest .



Verify the installation:

docker run rm apache-bench:latest ab -V



docker run --rm \\

    --network performance-test-network \\

    apache-bench:latest \\

    ab -n 1000 -c 10 http://test-webapp:3000/



**Run a more intensive test on the CPU-intensive endpoint**



docker run --rm \\

    --network performance-test-network \\

    apache-bench:latest \\

    ab -n 500 -c 5 -t 30 http://test-webapp:3000/cpu-intensive



**Generate detailed output with timing information**



docker run --rm \\

    --network performance-test-network \\

    apache-bench:latest \\

    ab -n 1000 -c 20 -g ab-results.tsv http://test-webapp:3000/



2\.



**Run a basic Siege test**



docker run --rm \\

    --network performance-test-network \\

    siege-bench:latest \\

    siege -c 10 -t 30s http://test-webapp:3000/



**Run Siege with multiple endpoints**



docker run --rm \\

    --network performance-test-network \\

    -v $(pwd)/urls.txt:/benchmarks/urls.txt \\

    siege-bench:latest \\

    siege -c 5 -t 20s -f /benchmarks/urls.txt



**Run Siege with detailed logging**



docker run --rm \\

    --network performance-test-network \\

    -v $(pwd):/benchmarks/output \\

    siege-bench:latest \\

    siege -c 15 -t 45s --log=/benchmarks/output/siege.log http://test-webapp:3000/



3\.



Run the comprehensive benchmark:

./benchmark.sh

./analyze\_results.sh



###### Run Distributed Load Tests Using Multiple Docker Containers



1. Deploy a Distributed Testing Environment



Start the distributed testing environment:

docker-compose -f docker-compose.distributed.yml up -d



Wait for all services to be ready:

\# Wait for services to start

sleep 15



\# Check service status

docker-compose -f docker-compose.distributed.yml ps

Verify the load balancer is working:

\# Test direct access to webapp

curl http://localhost:3000/



\# Test access through load balancer

curl http://localhost:8080/



2\. Run the distributed tests:



./distributed\_test.sh



Monitor container resources during testing:

\# In a separate terminal, monitor all containers

docker stats --format "table {{.Container}}\\t{{.CPUPerc}}\\t{{.MemUsage}}\\t{{.NetIO}}"

curl http://localhost:8080/

curl http://localhost:8080/



./analyze\_distributed.sh



###### **Integrate Performance Tests into CI Pipeline**



Run workflow and simulate files

