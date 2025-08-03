#### CI/CD Deployment strategies with docker



###### **Build and Deploy Blue Environment**



\# Create the network first

docker network create blue-green-network



\# Build and start blue environment

docker-compose -f docker-compose.blue.yml up -d --build



\# Verify blue deployment

docker-compose -f docker-compose.blue.yml ps



\# Test blue environment directly

curl http://localhost:3001

Subtask 3.2: Build and Deploy Green Environment

Deploy the green environment alongside the blue:





###### **Build and start Green environment**



docker-compose -f docker-compose.green.yml up -d --build



\# Verify green deployment

docker-compose -f docker-compose.green.yml ps



\# Test green environment directly

curl http://localhost:3002



\# Check both environments are running

docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"

Subtask 3.3: Deploy Load Balancer



###### **Deploy the NGINX load balancer to route traffic**



\# Start the complete stack with load balancer

docker-compose -f docker-compose.lb.yml up -d --build



\# Verify all services are running

docker-compose -f docker-compose.lb.yml ps



\# Test load balancer (should route to blue by default)

curl http://localhost



###### **Implement Traffic Routing Between Blue and Green Containers**



1. **Test the current traffic routing setup:**



\# Test multiple requests to see current routing

echo "Testing current traffic routing:"

for i in {1..5}; do

&nbsp;   echo "Request $i:"

&nbsp;   curl -s http://localhost | jq '.environment, .version'

&nbsp;   echo "---"

done



2\. **Switch traffic from blue to green:**



\# Switch traffic to green

./scripts/switch-traffic.sh green



\# Test the switch

echo "Testing after switching to green:"

for i in {1..5}; do

&nbsp;   echo "Request $i:"

&nbsp;   curl -s http://localhost | jq '.environment, .version'

&nbsp;   echo "---"

done



**3. Implement Gradual Traffic Shifting (Canary)**



\# Reload nginx

docker exec nginx-lb nginx -s reload



echo "Canary deployment configured: Blue($BLUE\_WEIGHT%) Green($GREEN\_WEIGHT%)"

EOF



\# Make script executable

chmod +x scripts/canary-deploy.sh



b. Test Canary Deployment



\# Start with 20% traffic to green

./scripts/canary-deploy.sh green 20



\# Test traffic distribution

echo "Testing canary deployment (20% green, 80% blue):"

for i in {1..20}; do

&nbsp;   RESPONSE=$(curl -s http://localhost | jq -r '.version')

&nbsp;   echo -n "$RESPONSE "

done

echo ""



\# Increase to 50% traffic to green

./scripts/canary-deploy.sh green 50



echo "Testing canary deployment (50% green, 50% blue):"

for i in {1..20}; do

&nbsp;   RESPONSE=$(curl -s http://localhost | jq -r '.version')

&nbsp;   echo -n "$RESPONSE "

done

echo ""



##### Test Failover Strategy by Simulating Deployment Failure



Create Health Check Monitoring Script



a. Simulate Application Failure



\# First, switch all traffic to green

./scripts/switch-traffic.sh green



\# Verify traffic is going to green

echo "Current traffic routing:"

curl -s http://localhost | jq '.environment, .version'



\# Simulate green environment failure by stopping it

echo "Simulating green environment failure..."

docker stop green-app



\# Check health status

./scripts/health-monitor.sh



\# Test if load balancer fails over to blue

echo "Testing failover to blue environment:"

for i in {1..5}; do

&nbsp;   echo "Request $i:"

&nbsp;   curl -s http://localhost | jq '.environment, .version' || echo "Request failed"

&nbsp;   sleep 1

done



b. Create Automatic Failover Script



\# Make script executable

chmod +x scripts/auto-failover.sh



Test Automatic Failover

\# Restart green environment

docker start green-app

sleep 5



\# Switch traffic back to green

./scripts/switch-traffic.sh green



\# Test automatic failover when green fails

echo "Testing automatic failover..."

docker stop green-app

sleep 2



\# Run failover script

./scripts/auto-failover.sh green blue



\# Verify failover worked

echo "Verifying failover:"

curl -s http://localhost | jq '.environment, .version'



c. Simulate Network Issues

chmod +x scripts/simulate-issues.sh



##### Automate the Deployment Process with CI/CD Tools



a. Create Complete Deployment Pipeline Script

chmod +x scripts/cicd-pipeline.sh



b. Create environment configuration



c. Test Complete CI/CD Pipeline



\# Initialize the pipeline (start with blue environment)

echo "blue" > .current-env



\# Deploy initial blue environment

./scripts/cicd-pipeline.sh deploy



\# Check status

./scripts/cicd-pipeline.sh status



\# Test canary deployment

./scripts/cicd-pipeline.sh canary 25



\# Test full deployment

./scripts/cicd-pipeline.

