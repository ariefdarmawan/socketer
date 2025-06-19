# Concurrent Test Script for Socketer (PowerShell)
# This script simulates multiple senders sending data simultaneously

param(
    [int]$Port = 8080,
    [string]$Server = "localhost",
    [int]$NumSenders = 5,
    [int]$MessagesPerSender = 10,
    [int]$DelayMs = 100
)

Write-Host "=== Concurrent Socketer Test (PowerShell) ===" -ForegroundColor Green
Write-Host "Server: $Server"
Write-Host "Port: $Port"
Write-Host "Number of Senders: $NumSenders"
Write-Host "Messages per Sender: $MessagesPerSender"
Write-Host "Delay between messages: ${DelayMs}ms"
Write-Host

# Function to send data from a specific sender
function Send-DataFromSender {
    param(
        [string]$Server,
        [int]$Port,
        [int]$SenderId,
        [int]$MessageCount,
        [int]$DelayMs
    )
    
    $results = @()
    
    for ($i = 1; $i -le $MessageCount; $i++) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($Server, $Port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $message = "SENDER-$($SenderId.ToString('D2')): Message $($i.ToString('D2')) at $timestamp"
            
            $writer.WriteLine($message)
            $writer.Flush()
            
            $results += "✓ Sender $SenderId sent message $i"
            
            $writer.Close()
            $stream.Close()
            $client.Close()
            
            if ($DelayMs -gt 0) {
                Start-Sleep -Milliseconds $DelayMs
            }
        }
        catch {
            $results += "✗ Sender $SenderId failed on message ${i}: $_"
        }
    }
    
    return $results
}

# Start multiple senders concurrently
Write-Host "Starting $NumSenders concurrent senders..." -ForegroundColor Yellow

$jobs = @()
for ($senderId = 1; $senderId -le $NumSenders; $senderId++) {
    $job = Start-Job -ScriptBlock ${function:Send-DataFromSender} -ArgumentList $Server, $Port, $senderId, $MessagesPerSender, $DelayMs
    $jobs += $job
    Write-Host "Started Sender $senderId (Job ID: $($job.Id))"
}

Write-Host "`nWaiting for all senders to complete..." -ForegroundColor Yellow

# Wait for all jobs to complete and collect results
$allResults = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -Wait
    $allResults += $result
    Remove-Job -Job $job
}

# Display results
Write-Host "`n=== Test Results ===" -ForegroundColor Green
$successCount = 0
$failureCount = 0

foreach ($result in $allResults) {
    if ($result -like "✓*") {
        Write-Host $result -ForegroundColor Green
        $successCount++
    } else {
        Write-Host $result -ForegroundColor Red
        $failureCount++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total messages attempted: $($NumSenders * $MessagesPerSender)"
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor Red
Write-Host "Success rate: $([math]::Round(($successCount / ($NumSenders * $MessagesPerSender)) * 100, 2))%"

# Additional test: Burst mode (no delay)
Write-Host "`n=== Burst Mode Test ===" -ForegroundColor Magenta
Write-Host "Sending 20 messages simultaneously (no delay)..."

$burstJobs = @()
for ($i = 1; $i -le 20; $i++) {
    $burstJob = Start-Job -ScriptBlock {
        param($Server, $Port, $MessageId)
        try {
            $client = New-Object System.Net.Sockets.TcpClient($Server, $Port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $message = "BURST-$($MessageId.ToString('D2')): Simultaneous message at $timestamp"
            
            $writer.WriteLine($message)
            $writer.Flush()
            
            $writer.Close()
            $stream.Close()
            $client.Close()
            
            return "✓ Burst message $MessageId sent"
        }
        catch {
            return "✗ Burst message $MessageId failed: $_"
        }
    } -ArgumentList $Server, $Port, $i
    
    $burstJobs += $burstJob
}

# Wait for burst jobs
$burstResults = @()
foreach ($burstJob in $burstJobs) {
    $burstResult = Receive-Job -Job $burstJob -Wait
    $burstResults += $burstResult
    Remove-Job -Job $burstJob
}

$burstSuccess = ($burstResults | Where-Object { $_ -like "✓*" }).Count
$burstFailed = ($burstResults | Where-Object { $_ -like "✗*" }).Count

Write-Host "Burst test - Successful: $burstSuccess, Failed: $burstFailed"

Write-Host "`n=== Test Completed ===" -ForegroundColor Green
Write-Host "Check the output file to verify data integrity and ordering."
