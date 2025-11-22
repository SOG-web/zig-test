#!/bin/bash

# Configuration
URL_ERROR_ARENA="http://localhost:8080/api/v1/test-error-arena"
URL_ERROR_MAIN="http://localhost:8080/api/v1/test-error-main"
CONCURRENT_REQUESTS=100
TOTAL_REQUESTS=1000

echo "Starting Error Case Load Test..."
echo "Target 1: $URL_ERROR_ARENA (Arena Allocator + Error)"
echo "Target 2: $URL_ERROR_MAIN (Main Allocator + Error)"
echo "Concurrent Requests: $CONCURRENT_REQUESTS"
echo "Total Requests per Target: $TOTAL_REQUESTS"

# Function to run load test
run_test() {
    local url=$1
    local name=$2
    echo "Running test for $name..."
    
    # Use seq to generate requests and xargs to run them in parallel
    # We expect 500 errors, so we count them
    seq 1 $TOTAL_REQUESTS | xargs -n 1 -P $CONCURRENT_REQUESTS -I {} curl -s -o /dev/null -w "%{http_code}" "$url" | sort | uniq -c
    
    echo "Test for $name completed."
}

# Run tests based on argument
if [ "$1" == "arena" ]; then
    run_test "$URL_ERROR_ARENA" "Arena Allocator (Error)"
elif [ "$1" == "main" ]; then
    run_test "$URL_ERROR_MAIN" "Main Allocator (Error)"
else
    # Run both if no argument provided
    run_test "$URL_ERROR_ARENA" "Arena Allocator (Error)"
    echo "--------------------------------"
    run_test "$URL_ERROR_MAIN" "Main Allocator (Error)"
fi

echo "Error Case Load Test Finished."
