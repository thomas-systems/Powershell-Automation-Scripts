<#
.SYNOPSIS
    Universal Create-CloudMailbox Script for onprem Active Directory + Exchange Online
    ## For other mailbox types (hybrid) DO NOT USE THIS SCRIPT! Use Enable-RemoteMailbox instead for ECP.
    ## This Script is for Active Directory User --> Exchange Online Cloud Mailbox Provisioning.

.DESCRIPTION
    A simple script that:
      • Prompts for a user
      • Sets basic mail attributes
      • Triggers Azure AD Connect sync
      • Waits for mailbox creation
      • Applies basic CAS policies (Optional: Security)

.AUTHOR
    Thomas-Systems
#>

Import-Module ActiveDirectory -ErrorAction Stop

######################################################################################################
#  CHANGE THESE VARIABLES! - Active Directory License group for example M365-E3-Group
$ProvisioningGroup = "M365-MailboxProvisioningGroup" # Can be a license group as well.
$LicenseGroup      = "M365-BaseLicenseGroup" # Make sure to add license with Exchange Online.
# For Example Microsoft 365 E3/ Microsoft 365 E5 licenses.
######################################################################################################

# Create-Mailbox Function
function Create-Mailbox {
    do {
        Clear-Host
        Write-Host "==== Create Mailbox ====" -ForegroundColor Cyan
        $sam = Read-Host "Enter SamAccountName"

        try {
            $User = Get-ADUser $sam -Properties UserPrincipalName, DisplayName, Mail
        } catch {
            Write-Host "User not found." -ForegroundColor Red
            $User = $null
        }

        if ($User) {
            Write-Host "Found: $($User.DisplayName) [$($User.UserPrincipalName)]" -ForegroundColor Green
            $ok = Read-Host "Correct user? (Y/N)"
        }
    } while (-not $User -or $ok -notmatch "^(Y|Yes)$")

    # Set mail attributes
    $UPN = $User.UserPrincipalName
    $Mail = $User.Mail
    if (-not $Mail) { $Mail = $UPN }

    Write-Host "Setting mail attributes..." -ForegroundColor Cyan
    Set-ADUser $User -Add @{ mail = $Mail; proxyAddresses = @("SMTP:$UPN", "smtp:$UPN") } -ErrorAction SilentlyContinue

    # Azure AD Sync
    Write-Host "Starting Azure AD sync..." -ForegroundColor Cyan
    Start-ADSyncSyncCycle -PolicyType Delta
    Start-sleep 15
    Start-ADSyncSyncCycle -PolicyType Delta

    return $User
}

# Provision-Mailbox Function
function Provision-Mailbox {
    param([string]$SamAccountName, [string]$UserPrincipalName)

    Write-Host "Provisioning mailbox..." -ForegroundColor Cyan

    # Add USER to provisioning Group (License group is OK as well)
    Add-ADGroupMember -Identity $ProvisioningGroup -Members $SamAccountName -ErrorAction SilentlyContinue

    # Sync changes to AAD
    Start-ADSyncSyncCycle -PolicyType Delta

    # Connect to Exchange (Login with Exchange Online Admin)
    Connect-ExchangeOnline -ShowBanner:$false | Out-Null

    Write-Host "Waiting for mailbox provisioning..." -ForegroundColor Yellow
    $Timeout = 600
    $Elapsed = 0
    $Interval = 15
    $Ready = $false

    while ($Elapsed -lt $Timeout -and -not $Ready) {
        try {
            if (Get-Mailbox -Identity $UserPrincipalName -ErrorAction Stop) { $Ready = $true; break }
        } catch {}
        Start-Sleep $Interval
        $Elapsed += $Interval
        Write-Host -NoNewline "."
    }

    if ($Ready) {
        Write-Host "Mailbox created succesfully." -ForegroundColor Green
    } else {
        Write-Host "Error: Mailbox not detected" -ForegroundColor Red
    }

    # Add User to License Group
    Add-ADGroupMember -Identity $LicenseGroup -Members $SamAccountName -ErrorAction SilentlyContinue

    # Basic CAS config - OPTIONAL For Security Purposes
    try {
        Set-CASMailbox -Identity $UserPrincipalName -PopEnabled $false -ActiveSyncEnabled $true -EwsEnabled $true
    } catch {}

    Disconnect-ExchangeOnline -Confirm:$false
}

# MAIN SCRIPT LOOP 
do {
    $User = Create-Mailbox
    Provision-Mailbox -SamAccountName $User.SamAccountName -UserPrincipalName $User.UserPrincipalName
    $again = Read-Host "Process another user mailbox? (Y/N)"
} until ($again -match "^(N|No)$")

Write-Host "Script Completed." -ForegroundColor Green

Pause
