##### Docker Image and Kubernetes app



##### 1\. Simple app



a. Deploy app



Create a Simple Web Application

Create a simple configuration file for nginx

Create a basic Dockerfile that will serve our web application



b. Build the container image:

docker build -t webapp-basic:v1.0 .



Run the container to test it:

docker run -d --name webapp-test -p 8080:80 webapp-basic:v1.0



Test the application:

curl http://localhost:8080



##### 2\. Advanced features



a. Create an Enhanced Web Application

Create the build script

Create the public directory and files



b. Build both versions and compare their sizes:



\# Build the basic version

docker build -t webapp-basic:v1.0 -f Dockerfile .



\# Build the optimized version

docker build -t webapp-optimized:v1.0 -f Dockerfile.multistage .



\# Compare image sizes

echo "=== Image Size Comparison ==="

docker images | grep webapp

You should see a significant difference in image sizes. The multi-stage build removes development dependencies and build tools from the final image.



c. Test the optimized application:



\# Run the optimized container

docker run -d --name webapp-optimized -p 8081:80 webapp-optimized:v1.0



\# Test the application

curl http://localhost:8081



\# Test the health check endpoint

curl http://localhost:8081/health



##### 3\. Set Up Private Container Registry and Configure Kubernetes



**a.  Setup harbour**



\# Navigate to Harbor directory

cd ~/harbor



\# Start Harbor

sudo docker-compose up -d



\# Wait for Harbor to be ready (this may take a few minutes)

echo "Waiting for Harbor to start..."

sleep 60



\# Check Harbor status

sudo docker-compose ps



 Get Harbor admin password

echo "Harbor admin password:"

sudo cat ~/harbor/harbor.yml | grep harbor\_admin\_password



\# Harbor will be available at: https://localhost

\# Default username: admin

\# Use the password from above



**b. Create Harbor Project via API**



\# Get the admin password

HARBOR\_PASSWORD=$(sudo cat ~/harbor/harbor.yml | grep harbor\_admin\_password | awk '{print $2}')



\# Create a project called 'container-lab'

curl -X POST "http://localhost/api/v2.0/projects" \\

  -H "Content-Type: application/json" \\

  -u "admin:${HARBOR\_PASSWORD}" \\

  -d '{

    "project\_name": "container-lab",

    "public": false,

    "metadata": {

      "public": "false"

    }

  }'



echo "Project created successfully!"



**c. Tag and Push Images to Harbor**



\# Login to Harbor

echo "${HARBOR\_PASSWORD}" | docker login localhost -u admin --password-stdin



\# Tag images for Harbor

docker tag webapp-optimized:v1.0 localhost/container-lab/webapp:v1.0

docker tag webapp-optimized:v1.0 localhost/container-lab/webapp:latest



\# Push images to Harbor

docker push localhost/container-lab/webapp:v1.0

docker push localhost/container-lab/webapp:latest



\# Verify images are in Harbor

curl -u "admin:${HARBOR\_PASSWORD}" "http://localhost/api/v2.0/projects/container-lab/repositories"



**d. Start Minikube and Configure Registry Access**



\# Start minikube

minikube start --driver=docker



\# Wait for minikube to be ready

kubectl wait --for=condition=Ready nodes --all --timeout=300s



\# Check cluster status

kubectl cluster-info



\# Create namespace for our application

kubectl create namespace container-lab



\# Create Docker registry secret

kubectl create secret docker-registry harbor-secret \\

  --docker-server=localhost \\

  --docker-username=admin \\

  --docker-password="${HARBOR\_PASSWORD}" \\

  --docker-email=admin@harbor.local \\

  -n container-lab



\# Verify secret creation

kubectl get secrets -n container-lab



##### 4\. Create Kubernetes Deployment



a. Create a deployment manifest for our application:

cd ~/container-lab



\# Apply the deployment

kubectl apply -f webapp-deployment.yaml



\# Wait for deployment to be ready

kubectl wait --for=condition=available --timeout=300s deployment/webapp-deployment -n container-lab



\# Check deployment status

kubectl get deployments -n container-lab

kubectl get pods -n container-lab

kubectl get services -n container-lab



b. Test the deployed app



\# Port forward to access the application

kubectl port-forward service/webapp-service 8082:80 -n container-lab \&



\# Wait a moment for port forwarding to establish

sleep 5



\# Test the application

curl http://localhost:8082



\# Test health endpoint

curl http://localhost:8082/health



\# Stop port forwarding

pkill -f "kubectl port-forward"



c. Verify Image Pull from Private Registry



\# Check events to see image pull

kubectl get events -n container-lab --sort-by='.lastTimestamp'



\# Describe a pod to see image details

POD\_NAME=$(kubectl get pods -n container-lab -l app=webapp -o jsonpath='{.items\[0].metadata.name}')

kubectl describe pod $POD\_NAME -n container-lab



\# Check image information

kubectl get pods -n container-lab -o jsonpath='{.items\[\*].spec.containers\[\*].image}'



##### 5\.  Advanced Container Management



a.

\# Trigger vulnerability scan via API

curl -X POST "http://localhost/api/v2.0/projects/container-lab/repositories/webapp/artifacts/v1.0/scan" \\

  -u "admin:${HARBOR\_PASSWORD}"



\# Wait for scan to complete

sleep 30



\# Get scan results

curl -u "admin:${HARBOR\_PASSWORD}" \\

  "http://localhost/api/v2.0/projects/container-lab/repositories/webapp/artifacts/v1.0" | \\

  python3 -m json.tool



b.

Create a script to update and redeploy the application:

chmod +x update-app.sh



c.

\# Monitor pod resource usage

kubectl top pods -n container-lab



\# Watch deployment status

kubectl get pods -n container-lab -w \&

WATCH\_PID=$!



\# Generate some load to test scaling

kubectl run load-generator --image=busybox --restart=Never -n container-lab -- \\

  /bin/sh -c "while true; do wget -q -O- http://webapp-service/; sleep 1; done"



\# Wait a bit to see the load

sleep 30



\# Stop monitoring

kill $WATCH\_PID



\# Clean up load generator

kubectl delete pod load-generator -n container-lab



##### 6\. Create HPA Using YAML Configuration



a.

\# Enable metrics server for resource monitoring

minikube addons enable metrics-server



\# Verify metrics server is running

kubectl get pods -n kube-system | grep metrics-server



\# Check metrics server logs if needed

kubectl logs -n kube-system -l k8s-app=metrics-server



\# Check current context

kubectl config current-context



\# Get cluster information

kubectl cluster-info



b.

kubectl apply -f hpa.yaml



\# Watch HPA status in real-time

watch -n 2 kubectl get hpa hpa



\# In another terminal, watch pods

watch -n 2 kubectl get pods



c.

\# Create load generator deployment

kubectl apply -f load-generator.yaml



\# Verify load generator is running

kubectl get pods | grep load-generator



\# Scale load generator to create more traffic

kubectl scale deployment load-generator --replicas=5



\# Monitor CPU usage

kubectl top pods



\# Get detailed metrics

kubectl top pods



\# Check HPA events

kubectl describe hpa hpa | grep Events -A 10



\# View deployment scaling events

kubectl describe deployment app | grep Events -A 10



\# Stop load generation

kubectl scale deployment load-generator --replicas=0



\# Monitor scale-down process

watch -n 5 kubectl get pods



d.

\# Deploy CPU stress test

kubectl apply -f cpu-stress.yaml



\# Monitor HPA status during load test

kubectl get hpa web-app-hpa --watch



\# In another terminal, monitor pod scaling

watch kubectl get pods -l app=web-app



\# Check resource usage

kubectl top pods -l app=web-app



e.

\# Create multiple load generators

for i in {1..3}; do

kubectl apply -f load-generator-$i.yaml

done



\# Verify all load generators are running

kubectl get pods | grep load-generator



f.

\# Make script executable

chmod +x monitor-scaling.sh



\# Run monitoring script

./monitor-scaling.sh



\# View HPA events

kubectl describe hpa web-app-hpa



\# Check deployment events

kubectl describe deployment web-app



\# View pod events

kubectl get events --sort-by=.metadata.creationTimestamp



\# Stop load generators to test scale-down

kubectl delete pod load-generator

kubectl delete pods -l app=cpu-stress

for i in {1..3}; do kubectl delete pod load-generator-$i; done



\# Monitor scale-down process

kubectl get hpa web-app-hpa --watch



\# View HPA controller logs

kubectl logs -n kube-system -l app=horizontal-pod-autoscaler



g.

chmod +x verify-autoscaling.sh

./verify-autoscaling.sh



h.

\# Remove existing HPA

kubectl delete hpa hpa



\# Apply optimized HPA

kubectl apply -f optimized-hpa.yaml



\# Verify new configuration

kubectl get hpa php-apache-optimized

kubectl describe hpa php-apache-optimized



i.

\# Run comprehensive load test

kubectl apply -f comprehensive-load-test.yaml



\# Monitor test progress

kubectl get jobs

kubectl logs job/load-test



##### 6\. Troubleshooting



**Issue 1: Harbor Not Starting: If Harbor fails to start:**



\# Check Harbor logs

sudo docker-compose -f ~/harbor/docker-compose.yml logs



\# Restart Harbor

cd ~/harbor

sudo docker-compose down

sudo docker-compose up -d



**Issue 2: Image Pull Errors: If Kubernetes can't pull images:**



\# Check secret configuration

kubectl get secret harbor-secret -n container-lab -o yaml



\# Recreate secret if needed

kubectl delete secret harbor-secret -n container-lab

kubectl create secret docker-registry harbor-secret \\

  --docker-server=localhost \\

  --docker-username=admin \\

  --docker-password="${HARBOR\_PASSWORD}" \\

  --docker-email=admin@harbor.local \\

  -n container-lab



**Issue 3: Pod Not Starting: If pods fail to start:**



\# Check pod events

kubectl describe pod $POD\_NAME -n container-lab



\# Check logs

kubectl logs $POD\_NAME -n container-lab



\# Check resource constraints

kubectl get pods -n container-lab -o wide



**Issue 4: Metrics Server Not Working**



\# Check metrics-server status

kubectl get pods -n kube-system | grep metrics-server



\# Restart metrics-server if needed

kubectl rollout restart deployment/metrics-server -n kube-system



**Issue 5: HPA Shows Unknown CPU Usage**



\# Wait for metrics to be available (can take 2-3 minutes)

kubectl top pods



\# Check if resource requests are defined

kubectl describe deployment php-apache | grep -A 10 "Requests"



**Issue 6: Pods Not Scaling**



\# Check HPA conditions

kubectl describe hpa



\# Verify resource limits and requests

kubectl describe pod <pod-name>



**Issue 7: Metrics Server Not Working**



\# Check metrics server status

kubectl get pods -n kube-system | grep metrics-server



\# If metrics server is not running, restart it

minikube addons disable metrics-server

minikube addons enable metrics-server



\# Wait for metrics server to be ready

kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s



**Issue 8: HPA Shows Unknown Metrics**



\# Check if resource requests are set in deployment

kubectl describe deployment web-app | grep -A 10 "Limits\\|Requests"



\# Verify metrics server is collecting data

kubectl top nodes

kubectl top pods -l app=web-app



**Issue 9: Pods Not Scaling**



\# Check HPA events for scaling decisions

kubectl describe hpa web-app-hpa



\# Verify resource utilization is above threshold

kubectl top pods -l app=web-app



\# Check if there are resource constraints

kubectl describe nodes

