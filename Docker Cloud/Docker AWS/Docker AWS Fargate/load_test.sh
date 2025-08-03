#!/bin/bash
ALB_DNS=$1
if [ -z "$ALB_DNS" ]; then
    echo "Usage: $0 <ALB_DNS_NAME>"
    exit 1
fi

echo "Starting load test against $ALB_DNS"
echo "Press Ctrl+C to stop"

while true; do
    for i in {1..10}; do
        curl -s http://$ALB_DNS > /dev/null &
    done
    sleep 1
done