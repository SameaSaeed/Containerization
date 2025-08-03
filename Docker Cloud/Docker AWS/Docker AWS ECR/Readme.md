##### Docker AWS ECR



###### **Setup**



docker --version

docker info



Check if AWS CLI is configured:

aws --version

aws sts get-caller-identity



If not configured, set up AWS CLI with your credentials:

aws configure



Get the authentication token and authenticate Docker to ECR:

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

Replace <your-account-id> with your actual AWS account ID.



Verify successful authentication by checking for the success message:

Login Succeeded



List your ECR repositories to confirm access:

aws ecr describe-repositories



###### **Push a Docker Image to ECR**



1. Build the Docker Image



Build the Docker image:

docker build -t my-web-app .



Verify the image was created:

docker images | grep my-web-app



Test the image locally (optional):

docker run -d -p 8080:80 --name test-app my-web-app

curl http://localhost:8080



docker stop test-app

docker rm test-app



2\. Tag the Image for ECR



Tag your image with the ECR repository URI:

docker tag my-web-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest



Also create a version tag:

docker tag my-web-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v1.0



Verify the tags:

docker images | grep my-web-app



3\. Tag the Image for ECR



Tag your image with the ECR repository URI:

docker tag my-web-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest



Also create a version tag:

docker tag my-web-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v1.0



Verify the tags:

docker images | grep my-web-app

###### 

###### **Pull the Image from ECR on a Different EC2 Instance**



1. Setup



2\. Pull the image from ECR:

docker pull <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest



Verify the image was pulled:

docker images | grep my-web-app



Run the container:

docker run -d -p 80:80 --name my-ecr-app <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest



Test the application:

curl http://localhost

Check container status:

docker ps



Test Different Image Tags

Pull the versioned image:

docker pull <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v1.0



Compare image details:

docker inspect <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:latest

docker inspect <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v1.0



###### **Set up Automated Image Scanning for Vulnerabilities**



a. Enable Image Scanning via AWS Console

Return to the AWS ECR console

Navigate to your my-web-app repository

Click on the repository name to view details

Go to the Image Scanning tab

Click Edit and ensure Scan on push is enabled

Save the configuration



b. Configure Enhanced Scanning (Optional)

In the ECR console, go to Private registry settings

Click on Scanning configuration

Enable enhanced scanning for more comprehensive vulnerability detection

Configure scanning rules:

Scan frequency: Continuous scanning

Scan filters: All repositories or specific repositories



c. Push a New Image to Trigger Scanning

Return to your primary EC2 instance

Make a small change to your application:



Build and push the updated image:

docker build -t my-web-app:v2.0 .

docker tag my-web-app:v2.0 <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v2.0

docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/my-web-app:v2.0



d. View Scanning Results

In the ECR console, navigate to your repository

Click on the Images tab

Wait for the scan to complete (this may take a few minutes)

View the scan results by clicking on the image digest

Review any vulnerabilities found and their severity levels



e. Use CLI to Check Scan Results



List images with scan status:

aws ecr describe-images --repository-name my-web-app



Get detailed scan results:

aws ecr describe-image-scan-findings --repository-name my-web-app --image-id imageTag=v2.0



Filter for high-severity vulnerabilities:

aws ecr describe-image-scan-findings --repository-name my-web-app --image-id imageTag=v2.0 --query 'imageScanFindings.findings\[?severity==`HIGH`]'



###### **Additional ECR Management Tasks**



Create a repository policy for controlled access

Create a lifecycle policy to manage image retention

aws ecr put-lifecycle-policy --repository-name my-web-app --lifecycle-policy-text file://lifecycle-policy.json



###### **Troubleshooting** 



**Authentication Issues**

Problem: Docker login fails with authentication error Solution:



\# Ensure AWS CLI is properly configured

aws configure list

\# Re-authenticate with ECR

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com



**Push/Pull Issues**

Problem: Image push fails with "repository does not exist" error Solution:



\# Verify repository exists

aws ecr describe-repositories --repository-names my-web-app

\# Check repository URI format

aws ecr describe-repositories --repository-names my-web-app --query 'repositories\[0].repositoryUri'



**Permission Issues**

Problem: Access denied when performing ECR operations Solution:



\# Check current IAM identity

aws sts get-caller-identity

\# Verify ECR permissions

aws iam list-attached-user-policies --user-name <your-username>



###### **Best Practices for ECR**



Security Best Practices

Use Private Repositories: Always use private repositories for proprietary applications

Enable Image Scanning: Always enable vulnerability scanning for production images

Implement Least Privilege: Use IAM policies to grant minimal required permissions

Use Image Tags Wisely: Implement consistent tagging strategies (semantic versioning)



Operational Best Practices

Lifecycle Policies: Implement lifecycle policies to manage storage costs

Multi-Region Replication: Consider cross-region replication for disaster recovery

Monitoring: Set up CloudWatch alarms for repository metrics

Automation: Use CI/CD pipelines for automated image builds and pushes

