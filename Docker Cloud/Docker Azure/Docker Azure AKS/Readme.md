##### Docker Containers in AKS



###### **Setup**



1\.

\# Login to Azure (this will open a browser window)

az login



\# Verify your subscription

az account show



2\.



Create Resource Group

A resource group is a container that holds related resources for an Azure solution.



\# Set variables for consistent naming

RESOURCE\_GROUP="aks-lab-rg"

LOCATION="eastus"

AKS\_CLUSTER\_NAME="aks-lab-cluster"

ACR\_NAME="akslabregistry$(date +%s)"



\# Create resource group

az group create --name $RESOURCE\_GROUP --location $LOCATION



\# Verify resource group creation

az group show --name $RESOURCE\_GROUP



3\.

\# Create Azure Container Registry

az acr create \\

&nbsp;   --resource-group $RESOURCE\_GROUP \\

&nbsp;   --name $ACR\_NAME \\

&nbsp;   --sku Basic \\

&nbsp;   --admin-enabled true



\# Get ACR login server

ACR\_LOGIN\_SERVER=$(az acr show --name $ACR\_NAME --resource-group $RESOURCE\_GROUP --query "loginServer" --output tsv)

echo "ACR Login Server: $ACR\_LOGIN\_SERVER"



4\.

\# Create AKS cluster with ACR integration

az aks create \\

&nbsp;   --resource-group $RESOURCE\_GROUP \\

&nbsp;   --name $AKS\_CLUSTER\_NAME \\

&nbsp;   --node-count 2 \\

&nbsp;   --node-vm-size Standard\_B2s \\

&nbsp;   --attach-acr $ACR\_NAME \\

&nbsp;   --generate-ssh-keys \\

&nbsp;   --enable-managed-identity



\# This command takes 5-10 minutes to complete

echo "AKS cluster creation in progress..."



5\.

Configure kubectl

Configure kubectl to connect to your AKS cluster.



\# Get AKS credentials

az aks get-credentials --resource-group $RESOURCE\_GROUP --name $AKS\_CLUSTER\_NAME



\# Verify connection to cluster

kubectl get nodes



\# Check cluster information

kubectl cluster-info



###### **Build Docker Image and Push to Azure Container Registry**



\# Build Docker image

docker build -t aks-demo-app:v1 .



\# List Docker images

docker images



\# Test the image locally

docker run -d -p 8080:3000 --name test-app aks-demo-app:v1



\# Test the application

curl http://localhost:8080



\# Check container logs

docker logs test-app



\# Stop and remove test container

docker stop test-app

docker rm test-app



\# Login to ACR

az acr login --name $ACR\_NAME



\# Tag image for ACR

docker tag aks-demo-app:v1 $ACR\_LOGIN\_SERVER/aks-demo-app:v1



\# Push image to ACR

docker push $ACR\_LOGIN\_SERVER/aks-demo-app:v1



\# Verify image in ACR

az acr repository list --name $ACR\_NAME --output table

az acr repository show-tags --name $ACR\_NAME --repository aks-demo-app --output table



###### **Deploy Image to AKS using kubectl**



**1.**

\# Apply deployment

kubectl apply -f deployment.yaml



\# Check deployment status

kubectl get deployments



\# Check pods

kubectl get pods



\# Get detailed pod information

kubectl get pods -o wide



\# Check pod logs

kubectl logs -l app=aks-demo-app



\# Describe deployment for troubleshooting

kubectl describe deployment aks-demo-app



2\.

\# Apply service

kubectl apply -f service.yaml



\# Check service status

kubectl get services



\# Wait for external IP (this may take a few minutes)

echo "Waiting for external IP assignment..."

kubectl get service aks-demo-app-service --watch



Note: Press Ctrl+C when you see the EXTERNAL-IP column shows an actual IP address instead of <pending>.



3\.

\# Get external IP

EXTERNAL\_IP=$(kubectl get service aks-demo-app-service -o jsonpath='{.status.loadBalancer.ingress\[0].ip}')

echo "External IP: $EXTERNAL\_IP"



\# Test application access

curl http://$EXTERNAL\_IP



\# Test health endpoint

curl http://$EXTERNAL\_IP/health



\# Open in browser (if available)

echo "Application URL: http://$EXTERNAL\_IP"



###### **Scale Application and Monitor using Azure Monitor**



1. Scale Application Horizontally



\# Scale deployment to 5 replicas

kubectl scale deployment aks-demo-app --replicas=5



\# Check scaling progress

kubectl get pods -w



\# Verify all pods are running

kubectl get pods -l app=aks-demo-app



\# Check deployment status

kubectl get deployment aks-demo-app



2\. Test Load Distribution

\# Test multiple requests to see different hostnames

for i in {1..10}; do

&nbsp;   echo "Request $i:"

&nbsp;   curl -s http://$EXTERNAL\_IP | grep "Hostname"

&nbsp;   echo ""

done



3\. Configure Horizontal Pod Autoscaler

\# Create HPA (Horizontal Pod Autoscaler)

kubectl autoscale deployment aks-demo-app --cpu-percent=70 --min=3 --max=10



\# Check HPA status

kubectl get hpa



\# Describe HPA for details

kubectl describe hpa aks-demo-app



4\. Enable Azure Monitor for Containers

\# Enable monitoring add-on for AKS

az aks enable-addons \\

&nbsp;   --resource-group $RESOURCE\_GROUP \\

&nbsp;   --name $AKS\_CLUSTER\_NAME \\

&nbsp;   --addons monitoring



\# Verify monitoring is enabled

az aks show --resource-group $RESOURCE\_GROUP --name $AKS\_CLUSTER\_NAME --query "addonProfiles.omsagent.enabled"



5\. View Monitoring Data

\# Get cluster resource ID for Azure portal

CLUSTER\_RESOURCE\_ID=$(az aks show --resource-group $RESOURCE\_GROUP --name $AKS\_CLUSTER\_NAME --query "id" --output tsv)

echo "Cluster Resource ID: $CLUSTER\_RESOURCE\_ID"



\# Check cluster metrics using kubectl

kubectl top nodes

kubectl top pods



\# View cluster events

kubectl get events --sort-by=.metadata.creationTimestamp



###### **Rolling Updates**



\# Update application image (simulate new version)

kubectl set image deployment/aks-demo-app aks-demo-app=$ACR\_LOGIN\_SERVER/aks-demo-app:v1



\# Check rollout status

kubectl rollout status deployment/aks-demo-app



\# View rollout history

kubectl rollout history deployment/aks-demo-app



###### **Troubleshooting**



\# Check cluster health

kubectl get componentstatuses



\# View all resources

kubectl get all



\# Check node status

kubectl describe nodes



\# Check pod logs for specific pod

kubectl logs <pod-name>



\# Execute commands in pod

kubectl exec -it <pod-name> -- /bin/sh



\# Port forward for local testing

kubectl port-forward service/aks-demo-app-service 8080:80



**Issue 1: ACR Authentication Problems**

Problem: Cannot push images to ACR Solution:

az acr login --name $ACR\_NAME

\# Or use admin credentials

az acr credential show --name $ACR\_NAME



**Issue 2: Pods Stuck in Pending State**

Problem: Pods not starting Solution:

kubectl describe pod <pod-name>

kubectl get events

\# Check resource constraints and node capacity



**Issue 3: External IP Not Assigned**

Problem: LoadBalancer service shows <pending> for external IP Solution:

\# Wait longer (can take 5-10 minutes)

\# Check Azure portal for load balancer creation

\# Verify AKS cluster has proper permissions

