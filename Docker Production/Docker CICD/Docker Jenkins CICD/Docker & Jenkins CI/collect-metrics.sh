#!/bin/bash

METRICS_FILE="/tmp/jenkins-metrics.json"
JENKINS_URL="http://localhost:8080"
JOB_NAME="docker-ci-pipeline"

# Collect build metrics
collect_metrics() {
    echo "Collecting Jenkins build metrics..."
    
    # Get build history
    curl -s "${JENKINS_URL}/job/${JOB_NAME}/api/json?tree=builds[number,result,duration,timestamp]" | \
        python3 -c "
import json, sys
from datetime import datetime

data = json.load(sys.stdin)
builds = data['builds']

metrics = {
    'total_builds': len(builds),
    'successful_builds': len([b for b in builds if b['result'] == 'SUCCESS']),
    'failed_builds': len([b for b in builds if b['result'] == 'FAILURE']),
    'average_duration': sum([b['duration'] for b in builds if b['duration']]) / len(builds) if builds else 0,
    'last_build': builds[0] if builds else None,
    'success_rate': len([b for b in builds if b['result'] == 'SUCCESS']) / len(builds) * 100 if builds else 0
}

print(json.dumps(metrics, indent=2))
" > ${METRICS_FILE}

    echo "Metrics saved to ${METRICS_FILE}"
    cat ${METRICS_FILE}
}

# Display metrics dashboard
display_dashboard() {
    clear
    echo "=== Jenkins Docker CI/CD Metrics Dashboard ==="
    echo "=============================================="
    
    if [ -f ${METRICS_FILE} ]; then
        python3 -c "
import json
with open('${METRICS_FILE}') as f:
    metrics = json.load(f)

print(f'Total Builds: {metrics[\"total_builds\"]}')
print(f'Successful Builds: {metrics[\"successful_builds\"]}')
print(f'Failed Builds: {metrics[\"failed_builds\"]}')
print(f'Success Rate: {metrics[\"success_rate\"]:.1f}%')
print(f'Average Duration: {metrics[\"average_duration\"]/1000:.1f}s')

if metrics['last_build']:
    print(f'Last Build: #{metrics[\"last_build\"][\"number\"]} - {metrics[\"last_build\"][\"result\"]}')
"
    else
        echo "No metrics available yet. Run collect_metrics first."
    fi
    
    echo -e "\n=== Docker Images Built ==="
    docker images | grep jenkins-docker-demo || echo "No images found"
    
    echo -e "\n=== Active Containers ==="
    docker ps --filter "name=staging-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main function
case "$1" in
    "collect")
        collect_metrics
        ;;
    "dashboard")
        display_dashboard
        ;;
    *)
        echo "Usage: $0 {collect|dashboard}"
        echo "  collect   - Collect build metrics from Jenkins"
        echo "  dashboard - Display metrics dashboard"
        ;;
esac