#!/bin/bash

# Simple manual test script for socketer application
# Usage: ./manual_test.sh [port] [output_dir]

PORT=${1:-8080}
OUTPUT_DIR=${2:-output}

echo "=== Manual Test for Socketer ==="
echo "Port: $PORT"
echo "Output Directory: $OUTPUT_DIR"
echo

# Build the application
echo "Building application..."
go build -o socketer .

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Starting socketer on port $PORT with output directory '$OUTPUT_DIR'"
echo "Press Ctrl+C to stop the application"
echo
echo "To test the application, open another terminal and run:"
echo "  echo 'Hello World' | nc localhost $PORT"
echo "  echo 'Test message' | nc localhost $PORT"
echo
echo "Or use telnet:"
echo "  telnet localhost $PORT"
echo

# Start the application
./socketer --port $PORT --output "$OUTPUT_DIR"
