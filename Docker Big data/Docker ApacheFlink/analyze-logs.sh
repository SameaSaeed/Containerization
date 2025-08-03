#!/bin/bash

echo "=== Flink Log Analysis ==="
echo ""

echo "=== Job Manager Errors ==="
docker logs flink-jobmanager 2>&1 | grep -i error | tail -10
echo ""

echo "=== Task Manager Performance ==="
for tm in flink-taskmanager1 flink-taskmanager2 flink-taskmanager3; do
    echo "--- $tm ---"
    docker logs $tm 2>&1 | grep -i "memory\|cpu\|performance" | tail -5
    echo ""
done

echo "=== Network Issues ==="
docker logs flink-jobmanager 2>&1 | grep -i "connection\|network\|timeout" | tail -5
echo ""