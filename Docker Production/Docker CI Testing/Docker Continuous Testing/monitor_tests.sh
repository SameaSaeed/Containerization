#!/bin/bash

echo "=== Selenium Docker Test Monitoring ==="
echo ""

# Check container status
echo "1. Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check Selenium Hub status
echo "2. Selenium Hub Status:"
if curl -s http://localhost:4444/wd/hub/status > /dev/null; then
    echo "✓ Selenium Hub is running"
    curl -s http://localhost:4444/wd/hub/status | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Ready: {data[\"value\"][\"ready\"]}')
print(f'Message: {data[\"value\"][\"message\"]}')
"
else
    echo "✗ Selenium Hub is not accessible"
fi
echo ""

# Check available browsers
echo "3. Available Browsers:"
curl -s http://localhost:4444/wd/hub/status | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    nodes = data['value']['nodes']
    for node in nodes:
        for slot in node['slots']:
            stereotype = slot['stereotype']
            print(f'Browser: {stereotype[\"browserName\"]} {stereotype.get(\"browserVersion\", \"latest\")}')
except:
    print('Unable to retrieve browser information')
"
echo ""

# Check resource usage
echo "4. Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""

# Check logs for errors
echo "5. Recent Container Logs:"
echo "--- Selenium Hub ---"
docker logs --tail 5 selenium-hub 2>/dev/null || echo "No selenium-hub container found"
echo ""
echo "--- Chrome Node ---"
docker logs --tail 5 chrome-node 2>/dev/null || echo "No chrome-node container found"
echo ""

# Check test reports
echo "6. Test Reports:"
if [ -d "reports" ]; then
    ls -la reports/
else
    echo "No reports directory found"
fi
echo ""

# Check screenshots
echo "7. Screenshots:"
if [ -d "screenshots" ]; then
    ls -la screenshots/
else
    echo "No screenshots directory found"
fi