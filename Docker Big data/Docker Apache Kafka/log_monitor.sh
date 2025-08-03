#!/bin/bash

echo "=== Kafka Log Monitor ==="

# Function to monitor logs
monitor_logs() {
    echo "Monitoring logs for $1..."
    docker logs -f --tail 20 $1 &
    PID=$!
    sleep 10
    kill $PID 2>/dev/null
    echo
}

# Monitor each component
monitor_logs "kafka-broker"
monitor_logs "zookeeper"
monitor_logs "kafka-producer"
monitor_logs "kafka-consumer"

echo "Log monitoring complete."