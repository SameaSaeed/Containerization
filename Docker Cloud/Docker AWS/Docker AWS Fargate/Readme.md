###### **Create a Task Definition for Fargate and Run the Container**



a. Create IAM Role for ECS Tasks



\# Create execution role

aws iam create-role \\

&nbsp;   --role-name ecsTaskExecutionRole \\

&nbsp;   --assume-role-policy-document file://ecs-task-trust-policy.json



\# Attach managed policy

aws iam attach-role-policy \\

&nbsp;   --role-name ecsTaskExecutionRole \\

&nbsp;   --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy



b. Create task Definition



\# Create CloudWatch log group

aws logs create-log-group --log-group-name /ecs/fargate-demo-task



\# Register task definition

aws ecs register-task-definition --cli-input-json file://task-definition.json



c. Create VPC and Security Groups

\# Create VPC

VPC\_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

echo "VPC ID: $VPC\_ID"



\# Create Internet Gateway

IGW\_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --vpc-id $VPC\_ID --internet-gateway-id $IGW\_ID



\# Create subnets in different AZs

SUBNET1\_ID=$(aws ec2 create-subnet --vpc-id $VPC\_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)

SUBNET2\_ID=$(aws ec2 create-subnet --vpc-id $VPC\_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)



\# Enable auto-assign public IP

aws ec2 modify-subnet-attribute --subnet-id $SUBNET1\_ID --map-public-ip-on-launch

aws ec2 modify-subnet-attribute --subnet-id $SUBNET2\_ID --map-public-ip-on-launch



\# Create route table and add route to IGW

ROUTE\_TABLE\_ID=$(aws ec2 create-route-table --vpc-id $VPC\_ID --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $ROUTE\_TABLE\_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW\_ID



\# Associate subnets with route table

aws ec2 associate-route-table --subnet-id $SUBNET1\_ID --route-table-id $ROUTE\_TABLE\_ID

aws ec2 associate-route-table --subnet-id $SUBNET2\_ID --route-table-id $ROUTE\_TABLE\_ID



\# Create security group

SG\_ID=$(aws ec2 create-security-group \\

&nbsp;   --group-name fargate-demo-sg \\

&nbsp;   --description "Security group for Fargate demo" \\

&nbsp;   --vpc-id $VPC\_ID \\

&nbsp;   --query 'GroupId' --output text)



\# Add inbound rules

aws ec2 authorize-security-group-ingress \\

&nbsp;   --group-id $SG\_ID \\

&nbsp;   --protocol tcp \\

&nbsp;   --port 3000 \\

&nbsp;   --cidr 0.0.0.0/0



aws ec2 authorize-security-group-ingress \\

&nbsp;   --group-id $SG\_ID \\

&nbsp;   --protocol tcp \\

&nbsp;   --port 80 \\

&nbsp;   --cidr 0.0.0.0/0



echo "Subnet 1 ID: $SUBNET1\_ID"

echo "Subnet 2 ID: $SUBNET2\_ID"

echo "Security Group ID: $SG\_ID"



d. Run the Container

\# Run task on Fargate

aws ecs run-task \\

&nbsp;   --cluster fargate-lab-cluster \\

&nbsp;   --task-definition fargate-demo-task \\

&nbsp;   --launch-type FARGATE \\

&nbsp;   --network-configuration "awsvpcConfiguration={subnets=\[$SUBNET1\_ID,$SUBNET2\_ID],securityGroups=\[$SG\_ID],assignPublicIp=ENABLED}"



\# List running tasks

aws ecs list-tasks --cluster fargate-lab-cluster



\# Get task details

TASK\_ARN=$(aws ecs list-tasks --cluster fargate-lab-cluster --query 'taskArns\[0]' --output text)

aws ecs describe-tasks --cluster fargate-lab-cluster --tasks $TASK\_ARN



###### **Set up Load Balancing for the Containerized Service using an Application Load Balancer**



1. **Create ALB**



ALB\_ARN=$(aws elbv2 create-load-balancer \\

&nbsp;   --name fargate-demo-alb \\

&nbsp;   --subnets $SUBNET1\_ID $SUBNET2\_ID \\

&nbsp;   --security-groups $SG\_ID \\

&nbsp;   --query 'LoadBalancers\[0].LoadBalancerArn' --output text)



echo "ALB ARN: $ALB\_ARN"



\# Get ALB DNS name

ALB\_DNS=$(aws elbv2 describe-load-balancers \\

&nbsp;   --load-balancer-arns $ALB\_ARN \\

&nbsp;   --query 'LoadBalancers\[0].DNSName' --output text)



echo "ALB DNS: $ALB\_DNS"



2\. Create target group



TG\_ARN=$(aws elbv2 create-target-group \\

&nbsp;   --name fargate-demo-tg \\

&nbsp;   --protocol HTTP \\

&nbsp;   --port 3000 \\

&nbsp;   --vpc-id $VPC\_ID \\

&nbsp;   --target-type ip \\

&nbsp;   --health-check-path /health \\

&nbsp;   --health-check-interval-seconds 30 \\

&nbsp;   --health-check-timeout-seconds 5 \\

&nbsp;   --healthy-threshold-count 2 \\

&nbsp;   --unhealthy-threshold-count 3 \\

&nbsp;   --query 'TargetGroups\[0].TargetGroupArn' --output text)



echo "Target Group ARN: $TG\_ARN"



3\. Create listener



aws elbv2 create-listener \\

&nbsp;   --load-balancer-arn $ALB\_ARN \\

&nbsp;   --protocol HTTP \\

&nbsp;   --port 80 \\

&nbsp;   --default-actions Type=forward,TargetGroupArn=$TG\_ARN



4\. Create ECS service with load balancer

aws ecs create-service \\

&nbsp;   --cluster fargate-lab-cluster \\

&nbsp;   --service-name fargate-demo-service \\

&nbsp;   --task-definition fargate-demo-task \\

&nbsp;   --desired-count 2 \\

&nbsp;   --launch-type FARGATE \\

&nbsp;   --network-configuration "awsvpcConfiguration={subnets=\[$SUBNET1\_ID,$SUBNET2\_ID],securityGroups=\[$SG\_ID],assignPublicIp=ENABLED}" \\

&nbsp;   --load-balancers targetGroupArn=$TG\_ARN,containerName=fargate-demo-container,containerPort=3000



\# Wait for service to stabilize

echo "Waiting for service to become stable..."

aws ecs wait services-stable --cluster fargate-lab-cluster --services fargate-demo-service



\# Check service status

aws ecs describe-services --cluster fargate-lab-cluster --services fargate-demo-service



5\. Test the application through load balancer

echo "Testing application at: http://$ALB\_DNS"

curl -s http://$ALB\_DNS | jq .



\# Test multiple times to see load balancing

for i in {1..5}; do

&nbsp; echo "Request $i:"

&nbsp; curl -s http://$ALB\_DNS | jq .hostname

&nbsp; sleep 1

done



###### **Monitor and Scale Services using CloudWatch**



1. Create cloudwatch dashboard



aws cloudwatch put-dashboard \\

&nbsp;   --dashboard-name "Fargate-Demo-Dashboard" \\

&nbsp;   --dashboard-body file://dashboard-body.json



2\. Set up Auto Scaling



\# Register scalable target

aws application-autoscaling register-scalable-target \\

&nbsp;   --service-namespace ecs \\

&nbsp;   --resource-id service/fargate-lab-cluster/fargate-demo-service \\

&nbsp;   --scalable-dimension ecs:service:DesiredCount \\

&nbsp;   --min-capacity 1 \\

&nbsp;   --max-capacity 10



\# Create scaling policy

POLICY\_ARN=$(aws application-autoscaling put-scaling-policy \\

&nbsp;   --service-namespace ecs \\

&nbsp;   --resource-id service/fargate-lab-cluster/fargate-demo-service \\

&nbsp;   --scalable-dimension ecs:service:DesiredCount \\

&nbsp;   --policy-name fargate-demo-scaling-policy \\

&nbsp;   --policy-type TargetTrackingScaling \\

&nbsp;   --target-tracking-scaling-policy-configuration '{

&nbsp;       "TargetValue": 70.0,

&nbsp;       "PredefinedMetricSpecification": {

&nbsp;           "PredefinedMetricType": "ECSServiceAverageCPUUtilization"

&nbsp;       },

&nbsp;       "ScaleOutCooldown": 300,

&nbsp;       "ScaleInCooldown": 300

&nbsp;   }' \\

&nbsp;   --query 'PolicyARN' --output text)



echo "Scaling Policy ARN: $POLICY\_ARN"



3\. Create CloudWatch Alarms

\# Create CPU utilization alarm

aws cloudwatch put-metric-alarm \\

&nbsp;   --alarm-name "Fargate-Demo-High-CPU" \\

&nbsp;   --alarm-description "Alarm when CPU exceeds 80%" \\

&nbsp;   --metric-name CPUUtilization \\

&nbsp;   --namespace AWS/ECS \\

&nbsp;   --statistic Average \\

&nbsp;   --period 300 \\

&nbsp;   --threshold 80 \\

&nbsp;   --comparison-operator GreaterThanThreshold \\

&nbsp;   --evaluation-periods 2 \\

&nbsp;   --dimensions Name=ServiceName,Value=fargate-demo-service Name=ClusterName,Value=fargate-lab-cluster



\# Create memory utilization alarm

aws cloudwatch put-metric-alarm \\

&nbsp;   --alarm-name "Fargate-Demo-High-Memory" \\

&nbsp;   --alarm-description "Alarm when Memory exceeds 80%" \\

&nbsp;   --metric-name MemoryUtilization \\

&nbsp;   --namespace AWS/ECS \\

&nbsp;   --statistic Average \\

&nbsp;   --period 300 \\

&nbsp;   --threshold 80 \\

&nbsp;   --comparison-operator GreaterThanThreshold \\

&nbsp;   --evaluation-periods 2 \\

&nbsp;   --dimensions Name=ServiceName,Value=fargate-demo-service Name=ClusterName,Value=fargate-lab-cluster



4\. chmod +x load\_test.sh



\# Run load test (in background)

echo "Starting load test..."

./load\_test.sh $ALB\_DNS \&

LOAD\_TEST\_PID=$!



echo "Load test running with PID: $LOAD\_TEST\_PID"

echo "Monitor scaling in AWS Console or run: aws ecs describe-services --cluster fargate-lab-cluster --services fargate-demo-service"

echo "To stop load test: kill $LOAD\_TEST\_PID"



5\. Monitor service scaling

watch -n 30 'aws ecs describe-services --cluster fargate-lab-cluster --services fargate-demo-service --query "services\[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}"'



\# View scaling activities

aws application-autoscaling describe-scaling-activities \\

&nbsp;   --service-namespace ecs \\

&nbsp;   --resource-id service/fargate-lab-cluster/fargate-demo-service



###### **Test Application Functionality**



\# Test application endpoints

echo "Testing main endpoint:"

curl -s http://$ALB\_DNS | jq .



echo "Testing health endpoint:"

curl -s http://$ALB\_DNS/health | jq .



\# Check service health

aws elbv2 describe-target-health --target-group-arn $TG\_ARN

Verify Monitoring Setup

\# List CloudWatch alarms

aws cloudwatch describe-alarms --alarm-names "Fargate-Demo-High-CPU" "Fargate-Demo-High-Memory"



\# Check dashboard

echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Fargate-Demo-Dashboard"



###### **Troubleshooting** 



Issue: Task fails to start

Solution: Check CloudWatch logs for container errors

aws logs describe-log-streams --log-group-name /ecs/fargate-demo-task



Issue: Load balancer health checks failing

Solution: Verify security group allows traffic on port 3000 and health check endpoint is accessible



Issue: Auto scaling not working

Solution: Ensure CloudWatch metrics are being published and scaling policies are correctly configured



Issue: Cannot access application

Solution: Check if subnets have internet gateway route and security groups allow inbound traffic

