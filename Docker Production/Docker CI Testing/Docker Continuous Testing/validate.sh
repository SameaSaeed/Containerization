#!/bin/bash

echo "=== Lab 69 Validation Checklist ==="
echo ""

# Test 1: Docker containers running
echo "1. Checking Docker containers..."
if docker ps | grep -q selenium; then
    echo "✓ Selenium containers are running"
else
    echo "✗ Selenium containers not found"
fi

# Test 2: Selenium Hub accessible
echo "2. Checking Selenium Hub accessibility..."
if curl -s http://localhost:4444/status | grep -q "\"ready\":true"; then
    echo "✓ Selenium Hub is accessible and ready"
else
    echo "✗ Selenium Hub is not accessible or not ready"
fi

# Test 3: Chrome Node registration
echo "3. Checking for Chrome Node registration..."
if curl -s http://localhost:4444/status | grep -q "chrome"; then
    echo "✓ Chrome Node is registered with Selenium Hub"
else
    echo "✗ Chrome Node is not registered"
fi

# Test 4: Run a simple Selenium test (headless)
echo "4. Running headless Selenium test..."
python3 <<EOF
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

options = Options()
options.add_argument('--headless')
options.add_argument('--no-sandbox')

try:
    driver = webdriver.Remote(
        command_executor='http://localhost:4444/wd/hub',
        options=options
    )
    driver.get("https://example.com")
    title = driver.title
    if "Example Domain" in title:
        print("✓ Headless test passed: Example Domain loaded")
    else:
        print("✗ Headless test failed: Unexpected page title")
    driver.quit()
except Exception as e:
    print(f"✗ Selenium test failed: {e}")
EOF

echo ""
echo "=== Validation Completed ==="
