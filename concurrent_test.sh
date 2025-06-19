#!/bin/bash

# Concurrent Test Script for Socketer (Bash)
# This script simulates multiple senders sending data simultaneously

# Default parameters
PORT=8080
SERVER="localhost"
NUM_SENDERS=5
MESSAGES_PER_SENDER=10
DELAY_MS=100

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
        --senders)
            NUM_SENDERS="$2"
            shift 2
            ;;
        --messages)
            MESSAGES_PER_SENDER="$2"
            shift 2
            ;;
        --delay)
            DELAY_MS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "OPTIONS:"
            echo "  --port PORT              Port to connect to (default: 8080)"
            echo "  --server SERVER          Server to connect to (default: localhost)"
            echo "  --senders NUM            Number of concurrent senders (default: 5)"
            echo "  --messages NUM           Messages per sender (default: 10)"
            echo "  --delay MS               Delay between messages in ms (default: 100)"
            echo "  --help                   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Concurrent Socketer Test (Bash) ==="
echo "Server: $SERVER"
echo "Port: $PORT"
echo "Number of Senders: $NUM_SENDERS"
echo "Messages per Sender: $MESSAGES_PER_SENDER"
echo "Delay between messages: ${DELAY_MS}ms"
echo

# Check if nc (netcat) is available
if ! command -v nc &> /dev/null; then
    echo "Error: 'nc' (netcat) is not installed."
    echo "Please install it with:"
    echo "  Ubuntu/Debian: sudo apt-get install netcat"
    echo "  CentOS/RHEL: sudo yum install nc"
    echo "  Arch Linux: sudo pacman -S gnu-netcat"
    exit 1
fi

# Function to send data from a specific sender
send_data_from_sender() {
    local sender_id=$1
    local message_count=$2
    local delay_ms=$3
    local success_count=0
    local failure_count=0
    
    for ((i=1; i<=message_count; i++)); do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        message=$(printf "SENDER-%02d: Message %02d at %s" "$sender_id" "$i" "$timestamp")
        
        if echo "$message" | nc -w 1 "$SERVER" "$PORT" 2>/dev/null; then
            echo "✓ Sender $sender_id sent message $i"
            ((success_count++))
        else
            echo "✗ Sender $sender_id failed on message $i"
            ((failure_count++))
        fi
        
        if [ "$delay_ms" -gt 0 ]; then
            sleep "$(echo "scale=3; $delay_ms/1000" | bc -l 2>/dev/null || echo "0.1")"
        fi
    done
    
    echo "Sender $sender_id completed: $success_count success, $failure_count failures"
}

# Create temporary directory for logs
temp_dir=$(mktemp -d)
echo "Using temporary directory: $temp_dir"

echo "Starting $NUM_SENDERS concurrent senders..."

# Start multiple senders in background
pids=()
for ((sender_id=1; sender_id<=NUM_SENDERS; sender_id++)); do
    send_data_from_sender "$sender_id" "$MESSAGES_PER_SENDER" "$DELAY_MS" > "$temp_dir/sender_$sender_id.log" &
    pids+=($!)
    echo "Started Sender $sender_id (PID: ${pids[-1]})"
done

echo
echo "Waiting for all senders to complete..."

# Wait for all background processes to complete
total_success=0
total_failure=0

for pid in "${pids[@]}"; do
    wait "$pid"
done

# Collect and display results
echo
echo "=== Test Results ==="
for ((sender_id=1; sender_id<=NUM_SENDERS; sender_id++)); do
    if [ -f "$temp_dir/sender_$sender_id.log" ]; then
        while IFS= read -r line; do
            if [[ $line == ✓* ]]; then
                echo -e "\033[32m$line\033[0m"  # Green
                ((total_success++))
            elif [[ $line == ✗* ]]; then
                echo -e "\033[31m$line\033[0m"  # Red
                ((total_failure++))
            else
                echo "$line"
            fi
        done < "$temp_dir/sender_$sender_id.log"
    fi
done

echo
echo "=== Summary ==="
total_attempted=$((NUM_SENDERS * MESSAGES_PER_SENDER))
success_rate=$(echo "scale=2; $total_success * 100 / $total_attempted" | bc -l 2>/dev/null || echo "0")

echo "Total messages attempted: $total_attempted"
echo -e "Successful: \033[32m$total_success\033[0m"
echo -e "Failed: \033[31m$total_failure\033[0m"
echo "Success rate: ${success_rate}%"

# Additional test: Burst mode (no delay)
echo
echo "=== Burst Mode Test ==="
echo "Sending 20 messages simultaneously (no delay)..."

burst_pids=()
burst_temp_dir=$(mktemp -d)

for ((i=1; i<=20; i++)); do
    (
        timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
        message=$(printf "BURST-%02d: Simultaneous message at %s" "$i" "$timestamp")
        
        if echo "$message" | nc -w 1 "$SERVER" "$PORT" 2>/dev/null; then
            echo "✓ Burst message $i sent"
        else
            echo "✗ Burst message $i failed"
        fi
    ) > "$burst_temp_dir/burst_$i.log" &
    burst_pids+=($!)
done

# Wait for burst test to complete
for pid in "${burst_pids[@]}"; do
    wait "$pid"
done

# Collect burst results
burst_success=0
burst_failure=0

for ((i=1; i<=20; i++)); do
    if [ -f "$burst_temp_dir/burst_$i.log" ]; then
        while IFS= read -r line; do
            if [[ $line == ✓* ]]; then
                ((burst_success++))
            elif [[ $line == ✗* ]]; then
                ((burst_failure++))
            fi
        done < "$burst_temp_dir/burst_$i.log"
    fi
done

echo "Burst test - Successful: $burst_success, Failed: $burst_failure"

# Cleanup
rm -rf "$temp_dir" "$burst_temp_dir"

echo
echo "=== Test Completed ==="
echo "Check the output file to verify data integrity and ordering."
