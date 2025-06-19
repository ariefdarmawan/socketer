# Simple Load Test Script for Socketer (PowerShell)
# This script sends a massive amount of data quickly to test queueing

param(
    [int]$Port = 8080,
    [string]$Server = "localhost",
    [int]$TotalMessages = 100
)

Write-Host "=== Load Test for Socketer ===" -ForegroundColor Green
Write-Host "Sending $TotalMessages messages as fast as possible..."
Write-Host

$jobs = @()
$startTime = Get-Date

# Send all messages simultaneously
for ($i = 1; $i -le $TotalMessages; $i++) {
    $job = Start-Job -ScriptBlock {
        param($Server, $Port, $MessageId, $StartTime)
        try {
            $client = New-Object System.Net.Sockets.TcpClient($Server, $Port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            
            $elapsed = (Get-Date) - $StartTime
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $message = "LOAD-$($MessageId.ToString('D3')): Fast message at $timestamp (elapsed: $($elapsed.TotalMilliseconds)ms)"
            
            $writer.WriteLine($message)
            $writer.Flush()
            
            $writer.Close()
            $stream.Close()
            $client.Close()
            
            return @{
                Success = $true
                MessageId = $MessageId
                Timestamp = $timestamp
            }
        }
        catch {
            return @{
                Success = $false
                MessageId = $MessageId
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $Server, $Port, $i, $startTime
    
    $jobs += $job
}

Write-Host "All $TotalMessages jobs started. Waiting for completion..."

# Wait for all jobs and collect results
$results = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -Wait
    $results += $result
    Remove-Job -Job $job
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalMilliseconds

# Analyze results
$successful = ($results | Where-Object { $_.Success -eq $true }).Count
$failed = ($results | Where-Object { $_.Success -eq $false }).Count

Write-Host "`n=== Load Test Results ===" -ForegroundColor Cyan
Write-Host "Total messages: $TotalMessages"
Write-Host "Successful: $successful" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Total time: ${totalTime}ms"
Write-Host "Average time per message: $([math]::Round($totalTime / $TotalMessages, 2))ms"
Write-Host "Messages per second: $([math]::Round($TotalMessages / ($totalTime / 1000), 2))"

if ($failed -gt 0) {
    Write-Host "`nFailed messages:" -ForegroundColor Red
    $results | Where-Object { $_.Success -eq $false } | ForEach-Object {
        Write-Host "  Message $($_.MessageId): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host "`nLoad test completed. Check output file for data integrity."
