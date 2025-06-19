#!/bin/bash

# Simple Load Test Script for Socketer (Bash)
# This script sends a massive amount of data quickly to test queueing

# Default parameters
PORT=8080
SERVER="localhost"
TOTAL_MESSAGES=100

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --server)
            SERVER="$2"
            shift 2
            ;;
        --messages)
            TOTAL_MESSAGES="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "OPTIONS:"
            echo "  --port PORT        Port to connect to (default: 8080)"
            echo "  --server SERVER    Server to connect to (default: localhost)"
            echo "  --messages NUM     Total messages to send (default: 100)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Load Test for Socketer (Bash) ==="
echo "Sending $TOTAL_MESSAGES messages as fast as possible..."
echo

# Check if nc (netcat) is available
if ! command -v nc &> /dev/null; then
    echo "Error: 'nc' (netcat) is not installed."
    exit 1
fi

# Create temporary directory for results
temp_dir=$(mktemp -d)
start_time=$(date +%s.%3N)

echo "Starting $TOTAL_MESSAGES concurrent connections..."

# Send all messages simultaneously
pids=()
for ((i=1; i<=TOTAL_MESSAGES; i++)); do
    (
        message_start=$(date +%s.%3N)
        timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        elapsed=$(echo "$message_start - $start_time" | bc -l 2>/dev/null || echo "0")
        message=$(printf "LOAD-%03d: Fast message at %s (elapsed: %.3fms)" "$i" "$timestamp" "$(echo "$elapsed * 1000" | bc -l 2>/dev/null || echo "0")")
        
        if echo "$message" | nc -w 1 "$SERVER" "$PORT" 2>/dev/null; then
            echo "SUCCESS:$i:$timestamp" > "$temp_dir/result_$i"
        else
            echo "FAILED:$i:Connection failed" > "$temp_dir/result_$i"
        fi
    ) &
    pids+=($!)
done

echo "All $TOTAL_MESSAGES jobs started. Waiting for completion..."

# Wait for all background processes
for pid in "${pids[@]}"; do
    wait "$pid"
done

end_time=$(date +%s.%3N)
total_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1")
total_time_ms=$(echo "$total_time * 1000" | bc -l 2>/dev/null || echo "1000")

# Analyze results
successful=0
failed=0

for ((i=1; i<=TOTAL_MESSAGES; i++)); do
    if [ -f "$temp_dir/result_$i" ]; then
        result=$(cat "$temp_dir/result_$i")
        if [[ $result == SUCCESS:* ]]; then
            ((successful++))
        else
            ((failed++))
        fi
    else
        ((failed++))
    fi
done

# Calculate statistics
avg_time=$(echo "scale=2; $total_time_ms / $TOTAL_MESSAGES" | bc -l 2>/dev/null || echo "0")
messages_per_sec=$(echo "scale=2; $TOTAL_MESSAGES / $total_time" | bc -l 2>/dev/null || echo "0")

echo
echo "=== Load Test Results ==="
echo "Total messages: $TOTAL_MESSAGES"
echo -e "Successful: \033[32m$successful\033[0m"
echo -e "Failed: \033[31m$failed\033[0m"
printf "Total time: %.2fms\n" "$total_time_ms"
printf "Average time per message: %.2fms\n" "$avg_time"
printf "Messages per second: %.2f\n" "$messages_per_sec"

if [ "$failed" -gt 0 ]; then
    echo
    echo "Failed messages:"
    for ((i=1; i<=TOTAL_MESSAGES; i++)); do
        if [ -f "$temp_dir/result_$i" ]; then
            result=$(cat "$temp_dir/result_$i")
            if [[ $result == FAILED:* ]]; then
                echo "  Message $i: $(echo $result | cut -d: -f3-)"
            fi
        fi
    done
fi

# Cleanup
rm -rf "$temp_dir"

echo
echo "Load test completed. Check output file for data integrity."

# Additional stress test
echo
echo "=== Quick Stress Test ==="
echo "Sending 50 messages with minimal interval..."

stress_success=0
stress_failed=0

for ((i=1; i<=50; i++)); do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    message=$(printf "STRESS-%02d: Rapid fire at %s" "$i" "$timestamp")
    
    if echo "$message" | nc -w 1 "$SERVER" "$PORT" 2>/dev/null; then
        ((stress_success++))
        echo -n "."
    else
        ((stress_failed++))
        echo -n "X"
    fi
    
    # Very small delay to avoid overwhelming
    sleep 0.01
done

echo
echo "Stress test - Successful: $stress_success, Failed: $stress_failed"
