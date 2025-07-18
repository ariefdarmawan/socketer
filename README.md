# Socketer

Aplikasi Go sederhana untuk menerima data melalui TCP socket dan menyimpannya ke file log.

## Fitur

- Menerima parameter port melalui command line argument `--port`
- Menerima parameter folder output melalui `--output`
- Menerima parameter ukuran queue buffer melalui `--queue-size` (default: 1000)
- Membuat TCP socket listener di port yang ditentukan
- Menerima data dari client dan menyimpannya ke file dengan format `yyyyMMdd.txt`
- **Mekanisme Queueing**: Data yang diterima dimasukkan ke queue buffer dan ditulis secara sequential untuk menghindari race condition
- Setiap data yang diterima akan ditambahkan dengan timestamp
- Mendukung multiple client connections secara bersamaan
- Thread-safe writing dengan goroutine terpisah untuk file operations

## Cara Menggunakan

### Build aplikasi:
```bash
# Dari root folder
go build -o socketer.exe main.go

# Atau menggunakan build script
./test/build.sh
```

### Menjalankan aplikasi:

#### Dengan parameter default (port 8080, output ke folder ./logs):
```bash
./socketer.exe
```

#### Dengan parameter custom:
```bash
# Menggunakan parameter lengkap
./socketer.exe --port 9999 --output ./mylogs --queue-size 2000

# Menggunakan alias (shorthand)
./socketer.exe -p 9999 -o ./mylogs -q 2000
```

#### Parameter yang tersedia:
- `--port`, `-p`: Port untuk listening (default: 8080)
- `--output`, `-o`: Direktori output untuk file log (default: ./logs)
- `--queue-size`, `-q`: Ukuran buffer queue (default: 1000)

#### Melihat help:
```bash
./socketer.exe -h
```

## Contoh Penggunaan

1. Jalankan server:
```bash
# Menggunakan parameter lengkap
./socketer.exe --port 8080 --output ./logs --queue-size 1500

# Menggunakan alias
./socketer.exe -p 8080 -o ./logs -q 1500

# Dengan parameter minimal
./socketer.exe -p 9000
```

2. Kirim data menggunakan telnet atau netcat:
```bash
# Menggunakan telnet
telnet localhost 8080

# Menggunakan PowerShell
$client = New-Object System.Net.Sockets.TcpClient("localhost", 8080)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.WriteLine("Hello from PowerShell!")
$writer.Flush()
$client.Close()
```

## Format Output

Data akan disimpan dalam file dengan format nama `yyyyMMdd.txt` di folder output yang ditentukan.

Setiap baris dalam file akan memiliki format:
```
[yyyy-MM-dd HH:mm:ss] data_yang_diterima
```

Contoh:
```
[2025-06-19 10:30:45] Hello World!
[2025-06-19 10:31:02] This is a test message
```

## Testing

### Windows (PowerShell)
Run the test script:
```powershell
.\test\test.ps1
```

### Linux/Unix (Bash)
Make the scripts executable and run them:
```bash
# Make scripts executable
chmod +x test/*.sh

# Run automated test
./test/test.sh

# Or run manual test
./test/manual_test.sh [port] [output_dir]

# Or send test data to running application
./test/send_test_data.sh [port]
```

### Manual Testing
1. Start the application:
```bash
./socketer --port 8080 --output ./data
```

2. In another terminal, send data using netcat:
```bash
echo "Hello World" | nc localhost 8080
```

Or using telnet:
```bash
telnet localhost 8080
```

## Available Scripts

### Basic Testing
- `test/test.ps1` - Automated test script for Windows PowerShell
- `test/test.sh` - Automated test script for Linux/Unix bash
- `test/manual_test.sh` - Manual testing script for Linux/Unix
- `test/send_test_data.sh` - Script to send test data to running application

### Concurrent/Load Testing
- `test/concurrent_test.ps1` - Test multiple senders simultaneously (PowerShell)
- `test/concurrent_test.sh` - Test multiple senders simultaneously (Bash)
- `test/load_test.ps1` - High-volume load testing (PowerShell)
- `test/load_test.sh` - High-volume load testing (Bash)

### Build and Utility
- `test/build.sh` - Build script for Linux/Unix
- `test/make_executable.sh` - Make all scripts executable on Unix systems

### Usage Examples

#### Concurrent Testing
```powershell
# PowerShell - Test with 10 senders, 5 messages each
.\test\concurrent_test.ps1 -NumSenders 10 -MessagesPerSender 5 -Port 8080

# Bash - Test with custom parameters
./test/concurrent_test.sh --senders 10 --messages 5 --delay 50 --port 8080
```

#### Load Testing
```powershell
# PowerShell - Send 200 messages rapidly
.\test\load_test.ps1 -TotalMessages 200 -Port 8080

# Bash - High volume test
./test/load_test.sh --messages 500 --port 8080
```

## Requirements

- Go 1.16 or later
- For testing: `netcat` (nc) or `telnet` command available in your system
  - Ubuntu/Debian: `sudo apt-get install netcat`
  - CentOS/RHEL: `sudo yum install nc`
  - Arch Linux: `sudo pacman -S gnu-netcat`
#   s o c k e t e r 
 
 