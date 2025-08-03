##### Docker in Infrastructure as Code Lab



**Create a Multi-Tier Application Structure**



mkdir -p ~/docker-iac-lab

cd ~/docker-iac-lab

mkdir -p {web-app,database,infrastructure,scripts}



**Deploy the Stack**



\# Build the web application image

docker-compose build



\# Start the entire stack

docker-compose up -d



\# Verify all services are running

docker-compose ps



**Test the deployment:**



\# Test the web application

curl http://localhost/



\# Test the health endpoint

curl http://localhost/health



\# Check logs

docker-compose logs web



##### Integrate Docker with Terraform for Infrastructure Provisioning



1. Create infrastructure files

2\. Deploy Infrastructure with Terraform



First, build the web application image:

cd ~/docker-iac-lab/web-app

docker build -t docker-iac-web:latest .



Now deploy with Terraform:

cd ~/docker-iac-lab/infrastructure



\# Initialize Terraform

terraform init



\# Plan the deployment

terraform plan



\# Apply the configuration

terraform apply -auto-approve



\# Check the outputs

terraform output



3\. Test the Terraform-managed containers:



\# Test web applications

curl http://localhost:5001/

curl http://localhost:5002/



\# List Terraform-managed resources

terraform state list



##### Integrate Docker with Ansible for Configuration Management



1. Create Ansible Playbook



2\. Deploy with Ansible

Install Ansible Docker collection:



ansible-galaxy collection install community.docker

Run the Ansible playbook:



\# Check syntax

ansible-playbook -i inventory.ini docker-playbook.yml --syntax-check



\# Run the playbook

ansible-playbook -i inventory.ini docker-playbook.yml



\# Test the deployment

curl http://localhost:8080/

curl http://localhost:8080/health



##### Deploy Containers Automatically with CI/CD Pipelines



a.

1. Create a GitHub actions workflow
2. Create a staging Docker compose
3. Create automated deployment, health-check, automated scaling, rollback/update, and monitoring scripts



b.

\# Test scaling up

./scale.sh web 4 development



\# Verify scaling

docker-compose ps



\# Test health checks after scaling

./health-check.sh development



\# Test update process

./update.sh latest development rolling



\# Test rollback (if needed)

\# ./rollback.sh previous development



##### Testing



**Complete system test**



\# Test Docker Compose deployment

echo "Testing Docker Compose deployment..."

docker-compose up -d

sleep 30

curl -f http://localhost/health



\# Test Terraform deployment

echo "Testing Terraform deployment..."

cd infrastructure

terraform apply -auto-approve

sleep 30

curl -f http://localhost:5001/health

curl -f http://localhost:5002/health



\# Test Ansible deployment

echo "Testing Ansible deployment..."

cd ../ansible-config

ansible-playbook -i inventory.ini docker-playbook.yml

sleep 30

curl -f http://localhost:8080/health



\# Test scaling

echo "Testing scaling..."

cd ../scripts

./scale.sh web 3 development

sleep 20

./health-check.sh development



##### Troubleshooting



Issue 1: Docker containers fail to start

Solution: Check Docker daemon status with sudo systemctl status docker

Verify the image exists with docker images

Check logs with docker logs <container-name>



Issue 2: Terraform fails to apply

Solution: Run terraform init again

Check Docker provider version compatibility

Verify Docker socket permissions



Issue 3: Ansible playbook fails

Solution: Install required collections: ansible-galaxy collection install community.docker

Check Python Docker library: pip install docker

Verify inventory file syntax



Issue 4: Health checks fail

Solution: Wait longer for containers to start

Check container logs for application errors

Verify network connectivity between containers



Issue 5: Port conflicts

Solution: Use different external ports in configurations

Check for existing services: netstat -tlnp

Stop conflicting services before deployment

