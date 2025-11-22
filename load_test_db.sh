#!/bin/bash

# Configuration
URL_DB="http://localhost:8082/api/v1/test-db"
CONCURRENT_REQUESTS=2000
TOTAL_REQUESTS=10000

echo "Starting Database Load Test..."
echo "Target: $URL_DB"
echo "Concurrent Requests: $CONCURRENT_REQUESTS"
echo "Total Requests: $TOTAL_REQUESTS"

# Function to run load test
run_test() {
    local url=$1
    local name=$2
    echo "Running test for $name..."
    
    # Use seq to generate requests and xargs to run them in parallel
    seq 1 $TOTAL_REQUESTS | xargs -n 1 -P $CONCURRENT_REQUESTS -I {} curl -s -o /dev/null -w "%{http_code}" "$url" | sort | uniq -c
    
    echo "Test for $name completed."
}

# Run tests
run_test "$URL_DB" "Database Query"

echo "Database Load Test Finished."
