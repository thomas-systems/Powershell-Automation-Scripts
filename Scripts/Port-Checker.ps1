<#
.SYNOPSIS
    Minimal TCP Port Connectivity Checker

.DESCRIPTION
    Checks if specific ports are open on a list of servers.
    Useful for network troubleshooting, firewall verification, or service monitoring.

    Works cross-platform (Windows/Linux/macOS) using PowerShell Core.

.PARAMETER Servers
    Array of hostnames or IP addresses to check.

.PARAMETER Ports
    Array of TCP ports to test on each server.

.EXAMPLE
    .\Port-Checker.ps1 -Servers "google.com","github.com" -Ports 80,443
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$Servers,

    [Parameter(Mandatory=$true)]
    [int[]]$Ports
)

function Test-Port {
    param($Server, $Port)
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $async = $tcp.BeginConnect($Server, $Port, $null, $null)
        $wait  = $async.AsyncWaitHandle.WaitOne(2000)  # 2s timeout
        if ($wait -and $tcp.Connected) {
            $tcp.EndConnect($async)
            $tcp.Close()
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

Write-Host "`n=== PORT CHECKER ===" -ForegroundColor Cyan

foreach ($server in $Servers) {
    foreach ($port in $Ports) {
        $result = if (Test-Port $server $port) { "OPEN" } else { "CLOSED" }
        $color  = if ($result -eq "OPEN") { "Green" } else { "Red" }
        Write-Host ("{0}:{1} -> {2}" -f $server, $port, $result) -ForegroundColor $color
    }
}

Write-Host "`nCheck complete." -ForegroundColor Cyan
Pause
