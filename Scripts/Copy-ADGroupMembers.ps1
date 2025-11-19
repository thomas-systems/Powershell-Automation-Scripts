<#
.SYNOPSIS
    Universal PowerShell script to copy members from one AD group to another.

.DESCRIPTION
    This script allows any IT admin to safely copy users from a source Active Directory group
    to a target Active Directory group.

.AUTHOR
    Thomas-Systems
#>

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host
Write-Host "=== Active Directory Group Member Copy Tool ===" -ForegroundColor Cyan
Write-Host

# --- Get Source Group Members ---
do {
    $source = Read-Host "Enter the source group (the group to copy members from)"
    try {
        $members = $null
        $members = (Get-ADGroup -Identity $source -Properties Members).Members

        if ($members) {
            Write-Host "Found $($members.Count) member(s) in '$source':" -ForegroundColor Green
            $members | ForEach-Object { (Get-ADUser $_).Name }
        } else {
            Write-Host "The group exists but has no members." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Source group not found. Please try again." -ForegroundColor Red
    }
} while (-not $members -and -not (Get-ADGroup -Filter "Name -eq '$source'"))

# --- Get Target Group ---
do {
    $target = Read-Host "Enter the target group (the group to add members to)"
    try {
        $targetconfirmed = (Get-ADGroup -Identity $target).Name
        Write-Host "Target group found: $targetconfirmed" -ForegroundColor Green
    }
    catch {
        Write-Host "Target group not found. Please try again." -ForegroundColor Red
    }
} while (-not $targetconfirmed)

# --- Confirmation Prompt ---
do {
    $continue = Read-Host "Are you sure you want to copy all users from '$source' to '$target'? (Y/N)"
    switch ($continue.ToUpper()) {
        'Y' {
            try {
                Add-ADGroupMember -Identity $target -Members $members -ErrorAction Stop
                Write-Host "Users successfully added to '$target'." -ForegroundColor Green
            }
            catch {
                Write-Host "Error adding users: $_" -ForegroundColor Red
            }
            $continue = $null
        }
        'N' {
            Write-Host "Operation cancelled. No users were added." -ForegroundColor Yellow
            $continue = $null
        }
        Default {
            Write-Host "Please type 'Y' or 'N'." -ForegroundColor Red
        }
    }
} while ($continue)

Write-Host "=== Script Completed ===" -ForegroundColor Cyan

Pause
