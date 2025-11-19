# Minimal and Simple Active Directory User Expiry Date Changer
# Author: Thomas-Systems

Import-Module ActiveDirectory

Write-Host
Write-Host "Active Directory Expiry Date Changer" -ForegroundColor Cyan
Write-Host

while ($true) {

    # Select user
    $User = $null
    while (-not $User) {
        try {
            $Sam = Read-Host "Enter SamAccountName of user (e.g. ttest)"
            $User = Get-ADUser -Identity $Sam -Properties DisplayName, AccountExpirationDate
            Write-Host "Found User:" $User.DisplayName -ForegroundColor Green

            $Confirm = Read-Host "Is this the correct user? (Y/N)"
            if ($Confirm -notmatch "^y$") { $User = $null }
        }
        catch {
            Write-Host "User not found. Try again." -ForegroundColor Yellow
        }
    }

    # Show current expiry
    if ($User.AccountExpirationDate) {
        Write-Host "Current expiry date:" $User.AccountExpirationDate.ToShortDateString()
    } else {
        Write-Host "User has no expiry date set." -ForegroundColor Yellow
    }

    # Ask for new expiry date
    $NewDate = $null
    while (-not $NewDate) {
        $InputDate = Read-Host "Enter new expiry date (format: dd-mm-yyyy)"
        try {
            $NewDate = Get-Date $InputDate
        }
        catch {
            Write-Host "Invalid date format. Use dd-mm-yyyy." -ForegroundColor Yellow
        }
    }

    # Set expiry date
    try {
        Set-ADAccountExpiration -Identity $User -DateTime $NewDate
        Write-Host "Expiry date updated to:" $NewDate.ToShortDateString() -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to set expiry date." -ForegroundColor Red
    }

    # Continue?
    $Again = Read-Host "Change expiry date for another user? (Y/N)"
    if ($Again -notmatch "^y$") { break }
}

Write-Host "Expiry date changer completed." -ForegroundColor Cyan

Pause
