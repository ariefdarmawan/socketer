# Test script untuk socketer
# Jalankan script ini setelah socketer berjalan

# Fungsi untuk mengirim data ke socketer
function Send-DataToSocketer {
    param(
        [string]$Server = "localhost",
        [int]$Port = 8080,
        [string]$Message
    )
    
    try {
        $client = New-Object System.Net.Sockets.TcpClient($Server, $Port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        
        $writer.WriteLine($Message)
        $writer.Flush()
        
        Write-Host "Message sent: $Message"
        
        $writer.Close()
        $stream.Close()
        $client.Close()
    }
    catch {
        Write-Host "Error: $_"
    }
}

# Contoh penggunaan
Write-Host "Mengirim test messages ke socketer..."

Send-DataToSocketer -Message "Hello from PowerShell test script!"
Start-Sleep 1

Send-DataToSocketer -Message "Test message 1"
Start-Sleep 1

Send-DataToSocketer -Message "Test message 2"
Start-Sleep 1

Send-DataToSocketer -Message "Test message 3"

Write-Host "Test selesai. Cek file log di folder output."
