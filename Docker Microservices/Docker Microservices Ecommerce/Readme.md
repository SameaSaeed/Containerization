###### **Microservices Networking**



a.

\# Create networks for different tiers

docker network create --driver bridge microservices-frontend

docker network create --driver bridge microservices-backend

docker network create --driver bridge microservices-database



\# Deploy database

docker run -d --name postgres-db \\

  --network microservices-database \\

  -e POSTGRES\_PASSWORD=dbpass \\

  postgres:13



\# Deploy API service (connected to backend and database)

docker run -d --name api-service \\

  --network microservices-backend \\

  nginx:alpine



docker network connect microservices-database api-service



\# Deploy frontend (connected to frontend and backend)

docker run -d --name frontend-app \\

  --network microservices-frontend \\

  nginx:alpine



docker network connect microservices-backend frontend-app



b. Create isolated development environments:



\# Create development environment networks

docker network create dev-env-1

docker network create dev-env-2



\# Deploy isolated development stacks

docker run -d --name dev1-web --network dev-env-1 nginx:alpine

docker run -d --name dev1-db --network dev-env-1 mysql:8.0 -e MYSQL\_ROOT\_PASSWORD=dev1pass



docker run -d --name dev2-web --network dev-env-2 nginx:alpine

docker run -d --name dev2-db --network dev-env-2 mysql:8.0 -e MYSQL\_ROOT\_PASSWORD=dev2pass



###### **Building Microservices**



###### 1\. Build 



a. Project structure



mkdir microservices-lab

cd microservices-lab



\# Create directories for each service

mkdir user-service

mkdir order-service

mkdir product-service

mkdir api-gateway

mkdir docker-compose-files



\# Create a shared network configuration

mkdir shared-configs



b. Build Services



\# Build User service

cd user-service

docker build -t user-service:latest .



\# Build Product Service

cd ../product-service

docker build -t product-service:latest .



\# Build Order Service

cd ../order-service

docker build -t order-service:latest .



Verify images were built:

docker images | grep -E "(user-service|product-service|order-service)"



cd ..

docker network create microservices-network



c. Deploy Microservices Using Docker Compose



cd docker-compose-files

docker-compose up -d

docker-compose ps

docker-compose logs -f

docker-compose logs -f user-service



d. Test Service Communication



Test each service individually:



\# Test User Service

curl -X GET http://localhost:3001/health

curl -X GET http://localhost:3001/users



\# Test Product Service

curl -X GET http://localhost:3002/health

curl -X GET http://localhost:3002/products



\# Test Order Service

curl -X GET http://localhost:3003/health

curl -X GET http://localhost:3003/orders

Test inter-service communication by creating an order:



curl -X POST http://localhost:3003/orders \\

  -H "Content-Type: application/json" \\

  -d '{

    "userId": 1,

    "products": \[

      {

        "productId": 1,

        "quantity": 2

      },

      {

        "productId": 2,

        "quantity": 1

      }

    ]

  }'



e. Scale Microservices



docker-compose up -d --scale product-service=3

docker-compose ps



cd ..

mkdir nginx-lb

cd nginx-lb



f.  Monitor Performance



chmod +x monitor-services.sh

./monitor-services.sh



chmod +x load-test.sh

./load-test.sh



###### 2\. Integrate API Gateway



cd api-gateway

