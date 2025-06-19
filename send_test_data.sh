#!/bin/bash

# Script to send test data to socketer application
# Usage: ./send_test_data.sh [port]

PORT=${1:-8080}

echo "=== Sending test data to socketer on port $PORT ==="
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

# Function to send data with a delay
send_data() {
    local message="$1"
    echo "Sending: $message"
    echo "$message" | nc localhost $PORT
    sleep 0.5
}

# Send various test messages
send_data "Hello, World!"
send_data "This is a test message from bash script"
send_data "Current time: $(date)"
send_data "Test with special characters: !@#$%^&*()"
send_data "Multi-line test"$'\n'"Second line"$'\n'"Third line"
send_data "JSON test: {\"name\":\"test\",\"value\":123}"
send_data "Binary data test: $(echo -e '\x41\x42\x43\x44')"

echo
echo "Test data sent successfully!"
echo "Check the output file in your specified output directory."
