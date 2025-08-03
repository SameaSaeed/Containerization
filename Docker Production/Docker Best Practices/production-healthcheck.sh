#!/bin/bash

# Production health check script
set -e

# Configuration
HEALTH_URL="http://localhost:5000/health"
MAX_RESPONSE_TIME=5
LOG_FILE="/tmp/healthcheck.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Perform health check
start_time=$(date +%s)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $MAX_RESPONSE_TIME "$HEALTH_URL")
end_time=$(date +%s)
response_time=$((end_time - start_time))

# Check results
if [ "$HTTP_CODE" -eq 200 ] && [ "$response_time" -le "$MAX_RESPONSE_TIME" ]; then
    log_message "Health check PASSED - HTTP $HTTP_CODE, Response time: ${response_time}s"
    exit 0
else
    log_message "Health check FAILED - HTTP $HTTP_CODE, Response time: ${response_time}s"
    exit 1
fi