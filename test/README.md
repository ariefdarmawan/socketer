# Test Scripts for Socketer

This folder contains all testing and utility scripts for the Socketer application.

## Scripts Overview

### Basic Testing
- **`test.ps1`** - Automated test script for Windows PowerShell
- **`test.sh`** - Automated test script for Linux/Unix bash
- **`manual_test.sh`** - Manual testing script for Linux/Unix
- **`send_test_data.sh`** - Script to send test data to running application

### Concurrent/Load Testing
- **`concurrent_test.ps1`** - Test multiple senders simultaneously (PowerShell)
- **`concurrent_test.sh`** - Test multiple senders simultaneously (Bash)
- **`load_test.ps1`** - High-volume load testing (PowerShell)
- **`load_test.sh`** - High-volume load testing (Bash)

### Build and Utility
- **`build.sh`** - Build script for Linux/Unix
- **`make_executable.sh`** - Make all scripts executable on Unix systems

## Quick Start

### For Windows (PowerShell):
```powershell
# Run basic test
.\test.ps1

# Run concurrent test
.\concurrent_test.ps1 -NumSenders 5 -MessagesPerSender 10

# Run load test
.\load_test.ps1 -TotalMessages 100
```

### For Linux/Unix (Bash):
```bash
# Make scripts executable (run once)
./make_executable.sh

# Build the application
./build.sh

# Run basic test
./test.sh

# Run concurrent test with custom parameters
./concurrent_test.sh --senders 10 --messages 5 --delay 100

# Run load test
./load_test.sh --messages 200

# Manual testing
./manual_test.sh 8080 ../logs
```

## Test Data Format

All test scripts send data with identifiers:
- **SENDER-XX**: Messages from concurrent test senders
- **LOAD-XXX**: Messages from load test
- **BURST-XX**: Messages from burst mode tests
- **STRESS-XX**: Messages from stress tests

Each message includes:
- Sender/test identifier
- Message sequence number
- Timestamp with millisecond precision
- Client identification

## Output Verification

After running tests, check the output files in the specified output directory (default: `../logs/`) to verify:
1. **Data integrity**: All messages are recorded
2. **Sequential order**: Messages are written in order despite concurrent sending
3. **Timestamp accuracy**: Each message has proper timestamp
4. **No data loss**: Success rate matches expected message count

## Prerequisites

### Windows:
- PowerShell 5.0 or later
- Go 1.16 or later

### Linux/Unix:
- Bash shell
- `netcat` (nc) command
- `bc` calculator (for timing calculations)
- Go 1.16 or later

Install netcat:
```bash
# Ubuntu/Debian
sudo apt-get install netcat

# CentOS/RHEL
sudo yum install nc

# Arch Linux
sudo pacman -S gnu-netcat
```
