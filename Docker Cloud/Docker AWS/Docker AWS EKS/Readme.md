##### Docker Containers in EKS cluster



1\. Setup



\# Check AWS CLI version

aws --version



\# Verify AWS configuration

aws sts get-caller-identity



\# Check current region

aws configure get region



2\. Set Environment Variables



\# Set cluster name and region

export CLUSTER\_NAME=my-eks-cluster

export AWS\_REGION=us-west-2

export ACCOUNT\_ID=$(aws sts get-caller-identity --query Account --output text)



\# Verify environment variables

echo "Cluster Name: $CLUSTER\_NAME"

echo "AWS Region: $AWS\_REGION"

echo "Account ID: $ACCOUNT\_ID"



3\. Create EKS Cluster



\# Create EKS cluster with managed node group

eksctl create cluster \\

&nbsp; --name $CLUSTER\_NAME \\

&nbsp; --region $AWS\_REGION \\

&nbsp; --version 1.28 \\

&nbsp; --nodegroup-name standard-workers \\

&nbsp; --node-type t3.medium \\

&nbsp; --nodes 2 \\

&nbsp; --nodes-min 1 \\

&nbsp; --nodes-max 4 \\

&nbsp; --managed



Note: Cluster creation takes approximately 15-20 minutes. The command will automatically configure kubectl context.



\# Check cluster status

aws eks describe-cluster --name $CLUSTER\_NAME --region $AWS\_REGION



\# Verify kubectl configuration

kubectl config current-context



\# Check cluster nodes

kubectl get nodes



\# Check cluster information

kubectl cluster-info



4\. Build Docker Image and Push to AWS ECR



\# Create ECR repository

aws ecr create-repository \\

&nbsp; --repository-name my-app \\

&nbsp; --region $AWS\_REGION



\# Get ECR login token and login to Docker

aws ecr get-login-password --region $AWS\_REGION | \\

docker login --username AWS --password-stdin $ACCOUNT\_ID.dkr.ecr.$AWS\_REGION.amazonaws.com



\# Set ECR repository URI

export ECR\_REPO\_URI=$ACCOUNT\_ID.dkr.ecr.$AWS\_REGION.amazonaws.com/my-app



\# Build Docker image

docker build -t my-app .



\# Tag image for ECR

docker tag my-app:latest $ECR\_REPO\_URI:latest

docker tag my-app:latest $ECR\_REPO\_URI:v1.0



\# Push images to ECR

docker push $ECR\_REPO\_URI:latest

docker push $ECR\_REPO\_URI:v1.0



\# Verify images in ECR

aws ecr list-images --repository-name my-app --region $AWS\_REGION



5\. Deploy Docker Image to EKS



a. Create a Kubernetes Namespace



\# Create namespace

kubectl create namespace my-app



\# Set default namespace context

kubectl config set-context --current --namespace=my-app



\# Verify namespace

kubectl get namespaces



b. Create deployments

\# Apply deployment

kubectl apply -f deployment.yaml



\# Apply service

kubectl apply -f service.yaml



c. Expose Application with AWS Load Balancer



1. **Setup** 



\# Download IAM policy for AWS Load Balancer Controller

curl -o iam\_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam\_policy.json



\# Create IAM policy

aws iam create-policy \\

&nbsp; --policy-name AWSLoadBalancerControllerIAMPolicy \\

&nbsp; --policy-document file://iam\_policy.json



\# Create IAM service account

eksctl create iamserviceaccount \\

&nbsp; --cluster=$CLUSTER\_NAME \\

&nbsp; --namespace=kube-system \\

&nbsp; --name=aws-load-balancer-controller \\

&nbsp; --role-name AmazonEKSLoadBalancerControllerRole \\

&nbsp; --attach-policy-arn=arn:aws:iam::$ACCOUNT\_ID:policy/AWSLoadBalancerControllerIAMPolicy \\

&nbsp; --approve



**2. Install Load Balancer Controller using Helm**



\# Add eks-charts repository

helm repo add eks https://aws.github.io/eks-charts

helm repo update



\# Install AWS Load Balancer Controller

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \\

&nbsp; -n kube-system \\

&nbsp; --set clusterName=$CLUSTER\_NAME \\

&nbsp; --set serviceAccount.create=false \\

&nbsp; --set serviceAccount.name=aws-load-balancer-controller



\# Verify installation

kubectl get deployment -n kube-system aws-load-balancer-controller



**3. Apply ingress**

kubectl apply -f ingress.yaml



\# Check ingress status

kubectl get ingress



\# Get load balancer URL (may take a few minutes)

kubectl get ingress my-app-ingress -o jsonpath='{.status.loadBalancer.ingress\[0].hostname}'



**4. Test External Access**



\# Get the load balancer hostname

export LB\_HOSTNAME=$(kubectl get ingress my-app-ingress -o jsonpath='{.status.loadBalancer.ingress\[0].hostname}')



\# Wait for load balancer to be ready (may take 3-5 minutes)

echo "Load Balancer URL: http://$LB\_HOSTNAME"



\# Test the application

curl http://$LB\_HOSTNAME



\# Test health endpoint

curl http://$LB\_HOSTNAME/health

###### 

###### **Scale Application and Monitor with CloudWatch**



1. **Create Horizontal Pod Autoscaler: Set up automatic scaling based on CPU utilization.**



\# Create HPA

kubectl autoscale deployment my-app-deployment --cpu-percent=70 --min=2 --max=10



\# Check HPA status

kubectl get hpa



\# View HPA details

kubectl describe hpa my-app-deployment



**2. Install metrics server for resource monitoring**



\# Install metrics server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml



\# Verify metrics server

kubectl get deployment metrics-server -n kube-system



\# Check node metrics (wait a few minutes after installation)

kubectl top nodes



\# Check pod metrics

kubectl top pods



**3. Generate Load for Testing Autoscaling**



\# Create a load generator pod

kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://my-app-service/; done"



\# Monitor HPA in real-time (run in separate terminal)

kubectl get hpa -w



\# Check pod scaling

kubectl get pods -w



\# After testing, delete load generator

kubectl delete pod load-generator



**4. Enable CloudWatch Container Insights**



\# Install CloudWatch agent

curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster\_name}}/$CLUSTER\_NAME/;s/{{region\_name}}/$AWS\_REGION/" | kubectl apply -f -



\# Verify CloudWatch agent installation

kubectl get daemonset cloudwatch-agent -n amazon-cloudwatch



\# Check logs

kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent --tail=50



**5. Create CloudWatch Dashboard**



aws cloudwatch put-dashboard \\

&nbsp; --dashboard-name "EKS-MyApp-Dashboard" \\

&nbsp; --dashboard-body file://dashboard.json



echo "Dashboard created: https://$AWS\_REGION.console.aws.amazon.com/cloudwatch/home?region=$AWS\_REGION#dashboards:name=EKS-MyApp-Dashboard



###### **Testing**



\# Test application endpoints

echo "Testing main endpoint:"

curl http://$LB\_HOSTNAME



echo "Testing health endpoint:"

curl http://$LB\_HOSTNAME/health



\# Check application logs

kubectl logs -l app=my-app --tail=20



###### **Troubleshooting** 



**Issue: Load balancer not accessible**



\# Check ingress status

kubectl describe ingress my-app-ingress



\# Verify security groups

aws ec2 describe-security-groups --filters "Name=group-name,Values=\*$CLUSTER\_NAME\*"



**Issue: HPA not scaling**



\# Check metrics server

kubectl get apiservice v1beta1.metrics.k8s.io -o yaml



\# Verify resource requests are set

kubectl describe deployment my-app-deployment

