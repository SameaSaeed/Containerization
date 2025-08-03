1\. Create Secrets

\# Create an API key file

echo "api\_key\_abc123xyz789" > ~/lab\_secrets/api\_key.txt



\# Create secrets from files

docker secret create db\_config ~/lab\_secrets/db\_config.json

docker secret create api\_key ~/lab\_secrets/api\_key.txt



\# Verify secrets were created

docker secret ls



2\. Deploy a web application that uses multiple secrets

docker service create \\

&nbsp; --name web\_app \\

&nbsp; --secret db\_username \\

&nbsp; --secret db\_password \\

&nbsp; --secret db\_config \\

&nbsp; --secret api\_key \\

&nbsp; --env DB\_USERNAME\_FILE=/run/secrets/db\_username \\

&nbsp; --env DB\_PASSWORD\_FILE=/run/secrets/db\_password \\

&nbsp; --env DB\_CONFIG\_FILE=/run/secrets/db\_config \\

&nbsp; --env API\_KEY\_FILE=/run/secrets/api\_key \\

&nbsp; --publish 8080:80 \\

&nbsp; nginx:alpine



\# Verify the service is running

docker service ps web\_app



3\. Custom Secret Mounts

\# Create a service with custom secret mount points

docker service create \\

&nbsp; --name custom\_app \\

&nbsp; --secret source=db\_config,target=/app/config/database.json \\

&nbsp; --secret source=api\_key,target=/app/keys/api.key \\

&nbsp; --publish 9090:80 \\

&nbsp; nginx:alpine



\# Verify custom mount points

CUSTOM\_CONTAINER\_ID=$(docker ps --filter "name=custom\_app" --format "{{.ID}}")

docker exec $CUSTOM\_CONTAINER\_ID ls -la /app/config/

docker exec $CUSTOM\_CONTAINER\_ID ls -la /app/keys/



###### **Security Best Practices and Verification**



1. Verify Secrets Are Not Exposed in Logs

\# Check service logs to ensure secrets aren't visible

docker service logs web\_app | grep -i password || echo "No passwords found in logs - Good!"

docker service logs mysql\_db | grep -i password || echo "No passwords found in logs - Good!"



\# Check container environment variables

CONTAINER\_ID=$(docker ps --filter "name=web\_app" --format "{{.ID}}" | head -1)

docker exec $CONTAINER\_ID env | grep -i password || echo "No password environment variables - Good!"



2\. Examine Secret Storage Security

\# Check Docker's secret storage (this will show encrypted data)

sudo ls -la /var/lib/docker/swarm/certificates/



\# Verify secrets are encrypted at rest

docker secret inspect db\_password --format "{{.Spec.Name}}: Created {{.CreatedAt}}"



\# Show that secrets have proper access controls

docker secret inspect db\_password --format "{{json .}}" | grep -i "encrypt"



3\. Test Secret Access Controls

\# Try to access secrets from a container without proper secret assignment

docker run --rm alpine:latest ls -la /run/secrets/ 2>/dev/null || echo "No secrets accessible - Security working correctly!"



\# Compare with a container that has secrets

CONTAINER\_WITH\_SECRETS=$(docker ps --filter "name=web\_app" --format "{{.ID}}" | head -1)

docker exec $CONTAINER\_WITH\_SECRETS ls -la /run/secrets/



4\. Clean Up Unused Secrets

\# Remove services first (secrets can't be deleted while in use)

docker service rm web\_app custom\_app mysql\_db



\# Wait for services to be fully removed

sleep 10



\# List all secrets

docker secret ls



\# Remove old secrets

docker secret rm db\_password api\_key



\# Verify cleanup

docker secret ls



###### **Troubleshooting** 



Issue 1: "This node is not a swarm manager"

Solution: Initialize Docker Swarm mode:

docker swarm init



Issue 2: "Secret is in use by service"

Solution: Remove or update the service first:

docker service rm <service\_name>

\# or

docker service update --secret-rm <secret\_name> <service\_name>



Issue 3: Service fails to start with secrets

Solution: Check secret names and file paths:

docker service logs <service\_name>

docker secret ls



Issue 4: Cannot read secret files in container

Solution: Verify the secret is properly mounted:

docker exec <container\_id> ls -la /run/secrets/

###### 

###### **Best Practices Summary**



Never use environment variables for secrets - Use secret files instead

Rotate secrets regularly - Create new versions and update services

Use least privilege access - Only assign secrets to services that need them

Monitor secret usage - Regularly audit which services use which secrets

Clean up unused secrets - Remove old secrets to reduce attack surface

Use descriptive secret names - Include version numbers or dates when appropriate

