#!/bin/bash

# Test script for socketer application on Linux
# This script will build and test the socketer application

echo "=== Socketer Application Test Script (Linux) ==="
echo

# Clean up any existing files
echo "Cleaning up..."
rm -f socketer
rm -rf test_output
echo

# Build the application
echo "Building socketer application..."
cd ..
go build -o socketer .
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi
echo "Build successful!"
cd test
echo

# Create test output directory
echo "Creating test output directory..."
mkdir -p test_output
echo

# Start the socketer application in background
echo "Starting socketer application on port 8080..."
../socketer -p 8080 -o test_output &
SOCKETER_PID=$!
echo "Socketer started with PID: $SOCKETER_PID"

# Wait a moment for the server to start
sleep 2

# Test 1: Send some test data
echo
echo "=== Test 1: Sending test messages ==="
echo "Test message 1" | nc localhost 8080
echo "Test message 2" | nc localhost 8080
echo "Test message 3" | nc localhost 8080

# Wait a moment for data to be written
sleep 1

# Test 2: Send data with telnet (if available)
echo
echo "=== Test 2: Testing with telnet (if available) ==="
if command -v telnet &> /dev/null; then
    echo "Using telnet to send data..."
    (echo "Telnet test message 1"; echo "Telnet test message 2"; sleep 1) | telnet localhost 8080 2>/dev/null
else
    echo "Telnet not available, skipping telnet test"
fi

# Wait a moment for data to be written
sleep 1

# Test 3: Send binary data
echo
echo "=== Test 3: Sending binary data ==="
echo -e "Binary data: \x41\x42\x43\x44" | nc localhost 8080

# Wait a moment for data to be written
sleep 1

# Check the output file
echo
echo "=== Checking output file ==="
OUTPUT_FILE="test_output/$(date +%Y%m%d).txt"
if [ -f "$OUTPUT_FILE" ]; then
    echo "Output file exists: $OUTPUT_FILE"
    echo "File contents:"
    echo "----------------------------------------"
    cat "$OUTPUT_FILE"
    echo "----------------------------------------"
    echo "File size: $(wc -c < "$OUTPUT_FILE") bytes"
    echo "Number of lines: $(wc -l < "$OUTPUT_FILE") lines"
else
    echo "Output file not found: $OUTPUT_FILE"
fi

# Stop the socketer application
echo
echo "=== Stopping socketer application ==="
kill $SOCKETER_PID 2>/dev/null
sleep 1

# Check if process is still running
if kill -0 $SOCKETER_PID 2>/dev/null; then
    echo "Force killing socketer application..."
    kill -9 $SOCKETER_PID 2>/dev/null
fi

echo "Socketer application stopped"

# Show directory contents
echo
echo "=== Test output directory contents ==="
ls -la test_output/

echo
echo "=== Test completed ==="
echo "Note: Make sure you have 'nc' (netcat) installed for this test to work properly"
echo "      You can install it with: sudo apt-get install netcat (Ubuntu/Debian)"
echo "      or: sudo yum install nc (CentOS/RHEL)"
