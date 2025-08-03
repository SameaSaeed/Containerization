#!/bin/sh

# Check if the application is responding
if wget --no-verbose --tries=1 --spider --timeout=5 http://localhost:3000/health 2>/dev/null; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed"
    exit 1
fi