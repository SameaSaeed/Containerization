##### Docker and GitHub Actions CI/CD



1\. Create the GitHub Actions directory structure:

mkdir -p .github/workflows

ls -la .github/



2\. Create the docker.yml Docker Workflow File

3\. Create a Docker Compose File for Testing

4\. Create a simple nginx configuration



**Configure GitHub Actions to Build Docker Images on Push Events**



1\.

git add .

git commit -m "Initial commit: Add Node.js app and GitHub Actions workflow"

git push origin main



2\. Verify the Workflow Execution

Go to your GitHub repository in your web browser

Click on the Actions tab

You should see your workflow Docker CI/CD Pipeline running

Click on the workflow run to see detailed logs

Note: The workflow will fail at the Docker Hub push step because we haven't configured the secrets yet. This is expected.



**Push the Image to Docker Hub Automatically After Each Successful Build**



1. Create Docker Hub Repository

2\. Configure GitHub Secrets

3\. Security Best Practice: Instead of using your password, create a Docker Hub access token:

Go to Docker Hub → Account Settings → Security

Click New Access Token

Give it a name like "GitHub Actions"

Copy the token and use it as your DOCKER\_PASSWORD secret



**Test the Complete Pipeline**



1. Make a small change to trigger the workflow. Edit the app.js file:

sed -i 's/version: '\\''1.0.0'\\''/version: '\\''1.0.1'\\''/' app.js



2\. Commit and push the change:

git add app.js

git commit -m "Update version to 1.0.1"

git push origin main



3\. Go to GitHub Actions and watch the workflow:

The build-and-test job should complete successfully

The build-and-push job should now also complete successfully

Check your Docker Hub repository to see the pushed image



**Verify the Docker Image**



Check your Docker Hub repository at https://hub.docker.com/r/YOUR\_USERNAME/docker-cicd-demo



You should see tags like:

latest

main-<commit-sha>

Branch-specific tags



**Add a Docker Compose Step to Test the Container in the Pipeline**



1. Update the workflow file to include Docker Compose testing

2\. Create a More Comprehensive Docker Compose Test File

3\. Add Integration Test Scripts

4\. Test the Enhanced Pipeline



Commit all the new changes:

git add .

git commit -m "Add comprehensive Docker Compose testing to CI/CD pipeline"

git push origin main





Monitor the GitHub Actions workflow:

Go to your repository's Actions tab

Watch the enhanced workflow run

Verify that all Docker Compose tests pass



**Troubleshooting**



**Issue 1: Docker Hub Authentication Fails**

Symptoms: Build-and-push job fails with authentication error



Solutions:

Verify your Docker Hub credentials in GitHub Secrets

Use an access token instead of password

Check that secret names match exactly: DOCKER\_USERNAME and DOCKER\_PASSWORD



**Issue 2: Docker Compose Services Don't Start**

Symptoms: Services fail health checks or don't respond



Solutions:

Increase wait times in the workflow

Check service dependencies in docker-compose.yml

Verify port mappings don't conflict

Review service logs in the workflow output



**Issue 3: Tests Fail Intermittently**

Symptoms: Tests pass locally but fail in CI/CD



Solutions:

Add longer sleep/wait times for services to start

Implement proper health checks

Use retry logic for network requests

Check for port conflicts



**Issue 4: Image Build Fails**

Symptoms: Docker build step fails



Solutions:

Verify Dockerfile syntax

Check that all required files are included

Ensure the base image is available

Review build context and .dockerignore

