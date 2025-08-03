#!/bin/bash

ISSUE_TYPE=${1:-latency}
ENVIRONMENT=${2:-green}

echo "=== Network Issue Simulation ==="
echo "Issue Type: $ISSUE_TYPE"
echo "Target Environment: $ENVIRONMENT"
echo "==============================="

case $ISSUE_TYPE in
    "latency")
        echo "Simulating high latency in $ENVIRONMENT environment..."
        # Add network delay using tc (traffic control)
        docker exec ${ENVIRONMENT}-app sh -c "apk add --no-cache iproute2 && tc qdisc add dev eth0 root netem delay 2000ms" 2>/dev/null || echo "Latency simulation requires additional setup"
        ;;
    "packet-loss")
        echo "Simulating packet loss in $ENVIRONMENT environment..."
        docker exec ${ENVIRONMENT}-app sh -c "apk add --no-cache iproute2 && tc qdisc add dev eth0 root netem loss 50%" 2>/dev/null || echo "Packet loss simulation requires additional setup"
        ;;
    "stop")
        echo "Stopping $ENVIRONMENT environment..."
        docker stop ${ENVIRONMENT}-app
        ;;
    "restart")
        echo "Restarting $ENVIRONMENT environment..."
        docker restart ${ENVIRONMENT}-app
        ;;
    "reset")
        echo "Resetting network conditions for $ENVIRONMENT environment..."
        docker exec ${ENVIRONMENT}-app sh -c "tc qdisc del dev eth0 root" 2>/dev/null || echo "No network rules to reset"
        ;;
    *)
        echo "Usage: $0 {latency|packet-loss|stop|restart|reset} {blue|green}"
        exit 1
        ;;
esac