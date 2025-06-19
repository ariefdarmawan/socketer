#!/bin/bash

# Build script for socketer application
echo "Building socketer application..."

# Change to parent directory where main.go is located
cd ..

# Build for current platform
go build -o socketer .

if [ $? -eq 0 ]; then
    echo "Build successful! Binary created: socketer"
    echo "Run with: ./socketer --port 8080 --output ./logs"
else
    echo "Build failed!"
    exit 1
fi

# Make executable (in case it's not)
chmod +x socketer

echo "Done!"
