##### Docker and Database



1\. Pull the latest MySQL image

docker pull mysql:8.0



\# Verify the image has been downloaded

docker images | grep MySQL



2\. Run a MySQL container with basic configuration

docker run --name mysql-basic \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=mypassword123 \\

&nbsp; -d mysql:8.0



\# Check container logs to ensure MySQL is ready

docker logs mysql-basic



3\. Create a custom bridge network for our database setup

docker network create mysql-network



\# Verify the network was created

docker network ls



4\. Create a MySQL container connected to our custom network

docker run --name mysql-server \\

&nbsp; --network mysql-network \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=SecurePass123 \\

&nbsp; -e MYSQL\_DATABASE=company\_db \\

&nbsp; -e MYSQL\_USER=app\_user \\

&nbsp; -e MYSQL\_PASSWORD=AppPass456 \\

&nbsp; -p 3306:3306 \\

&nbsp; -d mysql:8.0



\# Verify the container is running on the custom network

docker network inspect mysql-network



\# Monitor MySQL startup logs

docker logs -f mysql-server



5\. Initialize the Database with Custom Schema



\# Copy the SQL file into the container

docker cp ~/mysql-lab/sql-scripts/init-schema.sql mysql-server:/tmp/



\# Execute the schema file

docker exec -it mysql-server mysql -u root -pSecurePass123 -e "source /tmp/init-schema.sql"



\# Verify the schema was created

docker exec -it mysql-server mysql -u root -pSecurePass123 -e "USE company\_db; SHOW TABLES;"



\# Check if data was inserted correctly

docker exec -it mysql-server mysql -u root -pSecurePass123 -e "USE company\_db; SELECT \* FROM employees;"



\# Check the view

docker exec -it mysql-server mysql -u root -pSecurePass123 -e "USE company\_db; SELECT \* FROM employee\_summary;"



6\. Backup and Restore MySQL Data Using Volumes



a. Run MySQL with volume mounting

docker run --name mysql-persistent \\

&nbsp; --network mysql-network \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=SecurePass123 \\

&nbsp; -e MYSQL\_DATABASE=company\_db \\

&nbsp; -e MYSQL\_USER=app\_user \\

&nbsp; -e MYSQL\_PASSWORD=AppPass456 \\

&nbsp; -v ~/mysql-lab/mysql-data:/var/lib/mysql \\

&nbsp; -v ~/mysql-lab/backups:/backups \\

&nbsp; -p 3306:3306 \\

&nbsp; -d mysql:8.0



\# Wait for MySQL to be ready

sleep 30



b.

1\. Copy and execute our schema in the new container

docker cp ~/mysql-lab/sql-scripts/init-schema.sql mysql-persistent:/tmp/

docker exec -it mysql-persistent mysql -u root -pSecurePass123 -e "source /tmp/init-schema.sql"



2\. Create a full database backup

docker exec mysql-persistent mysqldump -u root -pSecurePass123 --all-databases > ~/mysql-lab/backups/full-backup-$(date +%Y%m%d-%H%M%S).sql



3\. Create a specific database backup

docker exec mysql-persistent mysqldump -u root -pSecurePass123 company\_db > ~/mysql-lab/backups/company-db-backup-$(date +%Y%m%d-%H%M%S).sql



\# Verify backup files were created

ls -la ~/mysql-lab/backups/



c.

\# Add some test data

docker exec -it mysql-persistent mysql -u root -pSecurePass123 -e "

USE company\_db; 

INSERT INTO employees (first\_name, last\_name, email, department, salary, hire\_date) 

VALUES ('Test', 'User', 'test.user@company.com', 'Engineering', 80000.00, CURDATE());"



\# Stop and remove the container

docker stop mysql-persistent

docker rm mysql-persistent



\# Start a new container with the same volume

docker run --name mysql-restored \\

&nbsp; --network mysql-network \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=SecurePass123 \\

&nbsp; -v ~/mysql-lab/mysql-data:/var/lib/mysql \\

&nbsp; -p 3306:3306 \\

&nbsp; -d mysql:8.0



\# Wait for startup

sleep 30



\# Verify data persistence

docker exec -it mysql-restored mysql -u root -pSecurePass123 -e "USE company\_db; SELECT \* FROM employees WHERE first\_name='Test';"



d.

\# Create a new container for restore testing

docker run --name mysql-restore-test \\

&nbsp; --network mysql-network \\

&nbsp; -e MYSQL\_ROOT\_PASSWORD=SecurePass123 \\

&nbsp; -p 3307:3306 \\

&nbsp; -d mysql:8.0



\# Wait for startup

sleep 30



\# Find the latest backup file

BACKUP\_FILE=$(ls -t ~/mysql-lab/backups/company-db-backup-\*.sql | head -1)



\# Restore from backup

docker exec -i mysql-restore-test mysql -u root -pSecurePass123 -e "CREATE DATABASE company\_db;"

docker exec -i mysql-restore-test mysql -u root -pSecurePass123 company\_db < "$BACKUP\_FILE"



\# Verify restore

docker exec -it mysql-restore-test mysql -u root -pSecurePass123 -e "USE company\_db; SELECT COUNT(\*) as employee\_count FROM employees;"



 **Create a MySQL Client Container and Connect to Database**



**a.**

\# Create a MySQL client container

docker run --name mysql-client \\

&nbsp; --network mysql-network \\

&nbsp; -it --rm mysql:8.0 mysql -h mysql-restored -u root -pSecurePass123



Run



-- Show databases

SHOW DATABASES;



-- Use our company database

USE company\_db;



-- Show tables

SHOW TABLES;



-- Run a query

SELECT department, COUNT(\*) as employee\_count, AVG(salary) as avg\_salary 

FROM employees 

GROUP BY department;



-- Exit the client

EXIT;



b.

Create a Persistent Client Container



\# Create a client container that stays running

docker run --name mysql-admin-client \\

&nbsp; --network mysql-network \\

&nbsp; -d mysql:8.0 tail -f /dev/null



\# Use the client container to run commands

docker exec -it mysql-admin-client mysql -h mysql-restored -u app\_user -pAppPass456 company\_db

In the MySQL session, try these operations:



-- Test user permissions

SELECT \* FROM employees LIMIT 5;



-- Try to create a new employee record

INSERT INTO employees (first\_name, last\_name, email, department, salary, hire\_date) 

VALUES ('Client', 'Test', 'client.test@company.com', 'Engineering', 85000.00, CURDATE());



-- Verify the insertion

SELECT \* FROM employees WHERE first\_name = 'Client';



-- Exit

EXIT;



###### **Troubleshooting** 



**Issue 1: Container Won't Start**



\# Check container logs

docker logs mysql-restored



\# 1. Ensure port 3306 is not already in use

sudo netstat -tlnp | grep 3306



\# 2. Check if another MySQL container is running

docker ps | grep mysql



\# 3. Remove conflicting containers

docker rm -f $(docker ps -aq --filter name=mysql)



**Issue 2: Connection Refused**



\# Wait for MySQL to fully initialize

docker logs -f mysql-restored



\# Look for "ready for connections" message

\# This can take 30-60 seconds on first startup



**Issue 3: Permission Denied**



\# Check volume permissions

ls -la ~/mysql-lab/mysql-data/



\# Fix permissions if needed

sudo chown -R 999:999 ~/mysql-lab/mysql-data/

