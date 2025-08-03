#!/bin/bash

set -e

TARGET_ENV=${1:-green}
PERCENTAGE=${2:-10}

echo "=== Canary Deployment Script ==="
echo "Target Environment: $TARGET_ENV"
echo "Traffic Percentage: $PERCENTAGE%"
echo "==============================="

# Calculate weights
if [ "$TARGET_ENV" = "green" ]; then
    GREEN_WEIGHT=$PERCENTAGE
    BLUE_WEIGHT=$((100 - PERCENTAGE))
else
    BLUE_WEIGHT=$PERCENTAGE
    GREEN_WEIGHT=$((100 - PERCENTAGE))
fi

# Create canary nginx configuration
cat > nginx/conf/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server blue-app:3000 weight=$BLUE_WEIGHT;
        server green-app:3000 weight=$GREEN_WEIGHT;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}

# Reload nginx
docker exec nginx-lb nginx -s reload

echo "Canary deployment configured: Blue($BLUE_WEIGHT%) Green($GREEN_WEIGHT%)"