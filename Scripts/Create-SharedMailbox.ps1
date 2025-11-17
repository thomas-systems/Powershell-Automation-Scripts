<#
.SYNOPSIS
    Create a new shared mailbox in Exchange Online.

.DESCRIPTION
    This script connects to Exchange Online, prompts for the mailbox name, alias, and default domain,
    confirms the domain, and creates the new shared mailbox.
    Logs all actions to file.
    
  - Requirements: 
    - PowerShell 5.1 or higher
    - Exchange Online Management module installed
    - Atleast Exchange Admin permissions

.EXAMPLE
    .\Create-SharedMailbox.ps1
#>

# =============================
# Install required module if missing
# =============================
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "ExchangeOnlineManagement module not found. Installing..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}

# =============================
# Connect to Exchange Online
# =============================
Connect-ExchangeOnline -ShowBanner:$false

# =============================
# Logging Function
# =============================
$logFile = "$PSScriptRoot\Create-SharedMailbox.log"
Write-Host "Logging to $logFile" -ForegroundColor Green

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$date [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# =============================
# Prompt for mailbox info
# =============================
$mailboxName = Read-Host "Enter display name for the new shared mailbox"
$mailboxAlias = Read-Host "Enter alias for the shared mailbox"

# Get default domain
$defaultDomain = (Get-AcceptedDomain | Where-Object {$_.Default -eq $true}).DomainName
Write-Host "Found default domain: $defaultDomain" -ForegroundColor Cyan
$confirmDomain = Read-Host "Use this domain for the new mailbox? (y/n)"
if ($confirmDomain -ne 'y') {
    $defaultDomain = Read-Host "Enter the domain to use for the new shared mailbox"
}

$userPrincipalName = "$mailboxAlias@$defaultDomain"

# ================================
#  Create shared mailbox (Cloud)
# ================================
try {
    New-Mailbox -Shared -Name $mailboxName -Alias $mailboxAlias -PrimarySmtpAddress $userPrincipalName -Confirm:$false
    Write-Log "Successfully created shared mailbox: $userPrincipalName" "SUCCESS"
    Write-Host -Foregroundcolor Green "Successfully created shared mailbox: $userPrincipalName"
    Pause
}
catch {
    Write-Log "Error creating shared mailbox $userPrincipalName"
    Write-Host "Error creating shared mailbox $userPrincipalName"
}

# =============================
# Disconnect session
# =============================
Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Disconnected from Exchange Online." -ForegroundColor Cyan
