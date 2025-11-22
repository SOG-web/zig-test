#!/bin/bash

# Configuration
URL_ARENA="http://localhost:8082/api/v1/test"
URL_MAIN="http://localhost:8082/api/v1/test-service"
CONCURRENT_REQUESTS=1000
TOTAL_REQUESTS=10000

echo "Starting Load Test..."
echo "Target 1: $URL_ARENA (Arena Allocator)"
echo "Target 2: $URL_MAIN (Main Allocator)"
echo "Concurrent Requests: $CONCURRENT_REQUESTS"
echo "Total Requests per Target: $TOTAL_REQUESTS"

# Function to run load test
run_test() {
    local url=$1
    local name=$2
    echo "Running test for $name..."
    
    # Use seq to generate requests and xargs to run them in parallel
    seq 1 $TOTAL_REQUESTS | xargs -n 1 -P $CONCURRENT_REQUESTS -I {} curl -s -o /dev/null -w "%{http_code}" "$url" | sort | uniq -c
    
    echo "Test for $name completed."
}

# Run tests based on argument
if [ "$1" == "arena" ]; then
    run_test "$URL_ARENA" "Arena Allocator"
elif [ "$1" == "main" ]; then
    run_test "$URL_MAIN" "Main Allocator"
else
    # Run both if no argument provided
    run_test "$URL_ARENA" "Arena Allocator"
    echo "--------------------------------"
    run_test "$URL_MAIN" "Main Allocator"
fi

echo "Load Test Finished."
