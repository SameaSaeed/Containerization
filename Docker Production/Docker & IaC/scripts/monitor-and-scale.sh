#!/bin/bash

set -e

ENVIRONMENT=${1:-development}
CPU_THRESHOLD=${2:-80}
MEMORY_THRESHOLD=${3:-80}
MIN_REPLICAS=${4:-2}
MAX_REPLICAS=${5:-10}

echo "Starting monitoring and auto-scaling for $ENVIRONMENT environment..."
echo "CPU Threshold: $CPU_THRESHOLD%, Memory Threshold: $MEMORY_THRESHOLD%"
echo "Replica range: $MIN_REPLICAS - $MAX_REPLICAS"

while true; do
  echo "$(date): Checking container metrics..."
  
  # Get current replica count
  current_replicas=$(docker ps --filter "name=web" --format "table {{.Names}}" | tail -n +2 | wc -l)
  
  # Get average CPU and memory usage
  avg_cpu=$(docker stats --no-stream --format "table {{.CPUPerc}}" | tail -n +2 | sed 's/%//g' | awk '{sum+=$1} END {print sum/NR}')
  avg_memory=$(docker stats --no-stream --format "table {{.MemPerc}}" | tail -n +2 | sed 's/%//g' | awk '{sum+=$1} END {print sum/NR}')
  
  echo "Current replicas: $current_replicas, Avg CPU: ${avg_cpu}%, Avg Memory: ${avg_memory}%"
  
  # Scale up if needed
  if (( $(echo "$avg_cpu > $CPU_THRESHOLD" | bc -l) )) || (( $(echo "$avg_memory > $MEMORY_THRESHOLD" | bc -l) )); then
    if [ $current_replicas -lt $MAX_REPLICAS ]; then
      new_replicas=$((current_replicas + 1))
      echo "High resource usage detected. Scaling up to $new_replicas replicas..."
      ./scale.sh web $new_replicas $ENVIRONMENT
    else
      echo "Already at maximum replicas ($MAX_REPLICAS)"
    fi
  # Scale down if needed
  elif (( $(echo "$avg_cpu < 30" | bc -l) )) && (( $(echo "$avg_memory < 30" | bc -l) )); then
    if [ $current_replicas -gt $MIN_REPLICAS ]; then
      new_replicas=$((current_replicas - 1))
      echo "Low resource usage detected. Scaling down to $new_replicas replicas..."
      ./scale.sh web $new_replicas $ENVIRONMENT
    else
      echo "Already at minimum replicas ($MIN_REPLICAS)"
    fi
  else
    echo "Resource usage within normal range"
  fi
  
  sleep 60
done