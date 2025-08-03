#!/bin/bash

echo "Starting load test..."
echo "Testing User Service..."

# Test user service with multiple concurrent requests
for i in {1..10}; do
    curl -s "http://localhost:3001/users" > /dev/null &
done

echo "Testing Product Service..."

# Test product service with multiple concurrent requests
for i in {1..10}; do
    curl -s "http://localhost:3002/products" > /dev/null &
done

echo "Testing Order Service..."

# Test order creation
for i in {1..5}; do
    curl -s -X POST "http://localhost:3003/orders" \
        -H "Content-Type: application/json" \
        -d "{\"userId\": $i, \"products\": [{\"productId\": 1, \"quantity\": 1}]}" > /dev/null &
done

wait
echo "Load test completed!"