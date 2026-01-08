<#
.SYNOPSIS
    Export Exchange Online user mailbox sizes to a CSV file.

.DESCRIPTION
    This script connects to Exchange Online, retrieves all user mailboxes, 
    gathers mailbox statistics (size and item count), and exports the data 
    to a CSV file on the user's Desktop.

.NOTES
    Author: Thomas-Systems

.EXAMPLE
    .\Export-MailboxStats.ps1
    Connects to Exchange Online, retrieves mailbox data, and saves it as "UserMailboxSizes.csv" on the Desktop.
#>

# Make sure ExchangeOnlineManagement module is installed
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing Exchange Online module..." -ForegroundColor Yellow
    Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser
}

# Import module
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop

Write-Host "Retrieving user mailboxes..." -ForegroundColor Cyan
Write-Host "Please wait, this may take some time..." -ForegroundColor Cyan

# Get all UserMailboxes
$mailboxes = Get-EXOMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox -ErrorAction Stop

# Loop
$mailboxData = @()
foreach ($mb in $mailboxes) {
    $stats = Get-EXOMailboxStatistics -Identity $mb.UserPrincipalName
    $mailboxData += [PSCustomObject]@{
        DisplayName       = $mb.DisplayName
        UserPrincipalName = $mb.UserPrincipalName
        MailboxSize       = $stats.TotalItemSize
        ItemCount         = $stats.ItemCount
    }
}

# Export to CSV to Desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$csvPath = Join-Path -Path $desktopPath -ChildPath "UserMailboxSizes.csv"

$mailboxData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "User mailbox export completed!" -ForegroundColor Green
Write-Host "CSV saved to $csvPath" -ForegroundColor Green

# Disconnect session
Disconnect-ExchangeOnline -Confirm:$false
