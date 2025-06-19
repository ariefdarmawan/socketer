#!/bin/bash

# Make all scripts executable
echo "Making all scripts executable..."

chmod +x test.sh
chmod +x manual_test.sh
chmod +x send_test_data.sh
chmod +x concurrent_test.sh
chmod +x load_test.sh
chmod +x build.sh

echo "All scripts are now executable:"
ls -la *.sh

echo
echo "You can now run:"
echo "  ./build.sh          - Build the application"  
echo "  ./test.sh           - Run basic tests"
echo "  ./concurrent_test.sh - Run concurrent tests"
echo "  ./load_test.sh      - Run load tests"
echo "  ./manual_test.sh    - Run manual testing"
