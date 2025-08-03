#!/bin/bash

# Find the most recent results directory
RESULTS_DIR=$(ls -td results_* | head -n1)

if [ -z "$RESULTS_DIR" ]; then
    echo "No results directory found. Please run benchmark.sh first."
    exit 1
fi

echo "=== Performance Analysis Report ==="
echo "Analyzing results from: $RESULTS_DIR"
echo "Generated on: $(date)"
echo

# Function to extract key metrics from Apache Bench results
analyze_ab_results() {
    local file=$1
    local test_name=$2
    
    echo "--- $test_name ---"
    
    if [ -f "$file" ]; then
        echo "Requests per second: $(grep 'Requests per second' $file | awk '{print $4}')"
        echo "Time per request (mean): $(grep 'Time per request' $file | head -n1 | awk '{print $4}')"
        echo "Transfer rate: $(grep 'Transfer rate' $file | awk '{print $3}')"
        echo "Failed requests: $(grep 'Failed requests' $file | awk '{print $3}')"
        echo "50% response time: $(grep '50%' $file | awk '{print $2}')"
        echo "95% response time: $(grep '95%' $file | awk '{print $2}')"
        echo "99% response time: $(grep '99%' $file | awk '{print $2}')"
    else
        echo "Results file not found: $file"
    fi
    echo
}

# Function to analyze Siege results
analyze_siege_results() {
    local file=$1
    local test_name=$2
    
    echo "--- $test_name ---"
    
    if [ -f "$file" ]; then
        echo "Transactions: $(grep 'Transactions:' $file | awk '{print $2}')"
        echo "Availability: $(grep 'Availability:' $file | awk '{print $2}')"
        echo "Elapsed time: $(grep 'Elapsed time:' $file | awk '{print $3}')"
        echo "Data transferred: $(grep 'Data transferred:' $file | awk '{print $3}')"
        echo "Response time: $(grep 'Response time:' $file | awk '{print $3}')"
        echo "Transaction rate: $(grep 'Transaction rate:' $file | awk '{print $3}')"
        echo "Throughput: $(grep 'Throughput:' $file | awk '{print $2}')"
    else
        echo "Results file not found: $file"
    fi
    echo
}

# Analyze all test results
analyze_ab_results "$RESULTS_DIR/ab_basic.txt" "Apache Bench - Basic Load Test"
analyze_ab_results "$RESULTS_DIR/ab_high_concurrency.txt" "Apache Bench - High Concurrency Test"
analyze_ab_results "$RESULTS_DIR/ab_cpu_intensive.txt" "Apache Bench - CPU Intensive Test"
analyze_siege_results "$RESULTS_DIR/siege_sustained.txt" "Siege - Sustained Load Test"

# Container resource analysis
echo "--- Container Resource Usage ---"
if [ -f "$RESULTS_DIR/container_stats.txt" ]; then
    echo "Container resource usage during load test:"
    cat "$RESULTS_DIR/container_stats.txt"
else
    echo "Container stats file not found"
fi
echo

echo "=== Summary and Recommendations ==="
echo "1. Compare response times across different test scenarios"
echo "2. Monitor failed requests - should be 0 for a healthy application"
echo "3. Check 95th and 99th percentile response times for user experience"
echo "4. Monitor container resource usage to identify bottlenecks"
echo "5. Use these metrics to establish performance baselines"
echo