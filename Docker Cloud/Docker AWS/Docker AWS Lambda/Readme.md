###### **Pushing Docker images to ECR in AWS**



1\. Build the Docker image with a descriptive tag

docker build -t my-lambda-function:latest .



\# Verify the image was created successfully

docker images | grep my-lambda-function



2\. Run the container locally on port 9000

docker run -p 9000:8080 my-lambda-function:latest



\# Test the Lambda function with a sample event

curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" \\

&nbsp; -d '{

&nbsp;   "httpMethod": "GET",

&nbsp;   "path": "/test",

&nbsp;   "queryStringParameters": {

&nbsp;     "name": "Docker",

&nbsp;     "version": "1.0"

&nbsp;   }

&nbsp; }'



3\. Configure AWS CLI (you'll be prompted for credentials)

aws configure



\# Verify your AWS identity

aws sts get-caller-identity



4\. Create ECR repository

aws ecr create-repository \\

&nbsp; --repository-name my-lambda-function \\

&nbsp; --region us-east-1



\# Get the repository URI (save this for later use)

aws ecr describe-repositories \\

&nbsp; --repository-names my-lambda-function \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'repositories\[0].repositoryUri' \\

&nbsp; --output text



\# Get login token and authenticate Docker with ECR

aws ecr get-login-password --region us-east-1 | \\

&nbsp; docker login --username AWS --password-stdin \\

&nbsp; $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com



\# Get your AWS account ID

ACCOUNT\_ID=$(aws sts get-caller-identity --query Account --output text)



5\. Tag and Push the Image



\# Tag the image for ECR

docker tag my-lambda-function:latest \\

&nbsp; $ACCOUNT\_ID.dkr.ecr.us-east-1.amazonaws.com/my-lambda-function:latest



\# Push the image to ECR

docker push $ACCOUNT\_ID.dkr.ecr.us-east-1.amazonaws.com/my-lambda-function:latest



\# Verify the image was pushed successfully

aws ecr list-images --repository-name my-lambda-function --region us-east-1



###### **Deploy the Container as a Lambda Function**



1. Deploy the Lambda container



a.

\# Create IAM Role for Lambda

aws iam create-role \\

&nbsp; --role-name lambda-docker-execution-role \\

&nbsp; --assume-role-policy-document file://lambda-trust-policy.json



\# Attach basic execution policy

aws iam attach-role-policy \\

&nbsp; --role-name lambda-docker-execution-role \\

&nbsp; --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole



b. Deploy your containerized Lambda function:



\# Get the role ARN

ROLE\_ARN=$(aws iam get-role \\

&nbsp; --role-name lambda-docker-execution-role \\

&nbsp; --query 'Role.Arn' \\

&nbsp; --output text)



\# Get your account ID and construct image URI

ACCOUNT\_ID=$(aws sts get-caller-identity --query Account --output text)

IMAGE\_URI="$ACCOUNT\_ID.dkr.ecr.us-east-1.amazonaws.com/my-lambda-function:latest"



\# Create the Lambda function

aws lambda create-function \\

&nbsp; --function-name my-docker-lambda \\

&nbsp; --package-type Image \\

&nbsp; --code ImageUri=$IMAGE\_URI \\

&nbsp; --role $ROLE\_ARN \\

&nbsp; --timeout 30 \\

&nbsp; --memory-size 256 \\

&nbsp; --region us-east-1



c. Invoke the Lambda function

aws lambda invoke \\

&nbsp; --function-name my-docker-lambda \\

&nbsp; --payload file://test-event.json \\

&nbsp; --region us-east-1 \\

&nbsp; response.json



\# View the response

cat response.json | python3 -m json.tool



2\. Trigger the Lambda Function via AWS API Gateway



a. Create the REST API

API\_ID=$(aws apigateway create-rest-api \\

&nbsp; --name my-docker-lambda-api \\

&nbsp; --description "API for Docker Lambda function" \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'id' \\

&nbsp; --output text)



echo "API ID: $API\_ID"



\# Get the root resource ID

ROOT\_RESOURCE\_ID=$(aws apigateway get-resources \\

&nbsp; --rest-api-id $API\_ID \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'items\[0].id' \\

&nbsp; --output text)



echo "Root Resource ID: $ROOT\_RESOURCE\_ID"



\# Create a new resource

RESOURCE\_ID=$(aws apigateway create-resource \\

&nbsp; --rest-api-id $API\_ID \\

&nbsp; --parent-id $ROOT\_RESOURCE\_ID \\

&nbsp; --path-part hello \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'id' \\

&nbsp; --output text)



echo "Resource ID: $RESOURCE\_ID"



\# Create GET method

aws apigateway put-method \\

&nbsp; --rest-api-id $API\_ID \\

&nbsp; --resource-id $RESOURCE\_ID \\

&nbsp; --http-method GET \\

&nbsp; --authorization-type NONE \\

&nbsp; --region us-east-1



b. Configure Lambda Integration



\# Get Lambda function ARN

LAMBDA\_ARN=$(aws lambda get-function \\

&nbsp; --function-name my-docker-lambda \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'Configuration.FunctionArn' \\

&nbsp; --output text)



\# Create integration

aws apigateway put-integration \\

&nbsp; --rest-api-id $API\_ID \\

&nbsp; --resource-id $RESOURCE\_ID \\

&nbsp; --http-method GET \\

&nbsp; --type AWS\_PROXY \\

&nbsp; --integration-http-method POST \\

&nbsp; --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA\_ARN/invocations" \\

&nbsp; --region us-east-1



\# Grant API Gateway permission to invoke Lambda

aws lambda add-permission \\

&nbsp; --function-name my-docker-lambda \\

&nbsp; --statement-id api-gateway-invoke \\

&nbsp; --action lambda:InvokeFunction \\

&nbsp; --principal apigateway.amazonaws.com \\

&nbsp; --source-arn "arn:aws:execute-api:us-east-1:$(aws sts get-caller-identity --query Account --output text):$API\_ID/\*/\*" \\

&nbsp; --region us-east-1



c. Deploy the API



\# Create deployment

aws apigateway create-deployment \\

&nbsp; --rest-api-id $API\_ID \\

&nbsp; --stage-name prod \\

&nbsp; --region us-east-1



\# Get the API endpoint URL

API\_URL="https://$API\_ID.execute-api.us-east-1.amazonaws.com/prod/hello"

echo "API Endpoint: $API\_URL"



d. Test the API Gateway Integration



\# Test the API endpoint

curl -X GET "$API\_URL?name=Docker\&environment=AWS"



\# Test with different parameters

curl -X GET "$API\_URL?message=Success\&test=true"



###### **Monitor and Log Function Execution with CloudWatch**



1. View CloudWatch Logs



\# List log groups for your Lambda function

aws logs describe-log-groups \\

&nbsp; --log-group-name-prefix "/aws/lambda/my-docker-lambda" \\

&nbsp; --region us-east-1



\# Get the latest log stream

LOG\_STREAM=$(aws logs describe-log-streams \\

&nbsp; --log-group-name "/aws/lambda/my-docker-lambda" \\

&nbsp; --order-by LastEventTime \\

&nbsp; --descending \\

&nbsp; --max-items 1 \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'logStreams\[0].logStreamName' \\

&nbsp; --output text)



echo "Latest Log Stream: $LOG\_STREAM"



\# View recent log events

aws logs get-log-events \\

&nbsp; --log-group-name "/aws/lambda/my-docker-lambda" \\

&nbsp; --log-stream-name "$LOG\_STREAM" \\

&nbsp; --region us-east-1 \\

&nbsp; --query 'events\[\*].\[timestamp,message]' \\

&nbsp; --output table



2\. Generate Test Traffic and Monitor



\# Make multiple API calls to generate logs

for i in {1..5}; do

&nbsp; echo "Making request $i..."

&nbsp; curl -s "$API\_URL?request=$i\&timestamp=$(date +%s)" | python3 -m json.tool

&nbsp; sleep 2

done



3\. View Lambda Metrics



\# Get function invocation metrics

aws cloudwatch get-metric-statistics \\

&nbsp; --namespace AWS/Lambda \\

&nbsp; --metric-name Invocations \\

&nbsp; --dimensions Name=FunctionName,Value=my-docker-lambda \\

&nbsp; --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\

&nbsp; --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \\

&nbsp; --period 300 \\

&nbsp; --statistics Sum \\

&nbsp; --region us-east-1



4\. Create Custom Log Queries



\# Run the query (Note: This requires the query to be run via AWS Console or SDK)

echo "Log Insights Query created. You can run this in the AWS Console:"

cat log-query.txt



\# Get function duration metrics

aws cloudwatch get-metric-statistics \\

&nbsp; --namespace AWS/Lambda \\

&nbsp; --metric-name Duration \\

&nbsp; --dimensions Name=FunctionName,Value=my-docker-lambda \\

&nbsp; --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \\

&nbsp; --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \\

&nbsp; --period 300 \\

&nbsp; --statistics Average,Maximum \\

&nbsp; --region us-east-1



###### **Troubleshooting** 



Issue 1: Docker build fails

Solution: Ensure Dockerfile syntax is correct and base image is accessible

Check: Verify internet connectivity and Docker daemon is running



Issue 2: ECR authentication fails

Solution: Ensure AWS CLI is configured with proper permissions

Check: Verify IAM user has ECR permissions



Issue 3: Lambda function creation fails

Solution: Check IAM role permissions and image URI format

Check: Ensure ECR image exists and is accessible



Issue 4: API Gateway returns 502 error

Solution: Verify Lambda integration configuration and permissions

Check: Ensure Lambda function returns proper response format



Issue 5: CloudWatch logs not appearing

Solution: Check IAM role has CloudWatch Logs permissions

Check: Verify function is being invoked

