<#
.SYNOPSIS
    Microsoft 365 Unused License Audit

.DESCRIPTION
    Checks all users with assigned licenses and identifies licenses that are unused.
    Outputs only unused licenses and the number of days unused.
    Exports output to desktop of logged in user.
#>

param(
    [int]$DaysInactive = 30
)

# Connect to Microsoft Graph
try {
    Connect-MgGraph -Scopes "User.Read.All","Directory.Read.All","AuditLog.Read.All"
} catch {
    Write-Host "Failed to connect to Microsoft Graph. Ensure you have permissions." -ForegroundColor Red
    exit
}

Write-Host "Fetching all users with licenses..." -ForegroundColor Cyan

# Get all users with assigned licenses and their sign-in activity
$Users = Get-MgUser -All -Property "DisplayName,UserPrincipalName,AssignedLicenses,SignInActivity" |
         Where-Object { $_.AssignedLicenses.Count -gt 0 }

if (-not $Users) {
    Write-Host "No licensed users found." -ForegroundColor Yellow
    exit
}

# Map SKU IDs to friendly names
$SkuMap = @{}
$SubscribedSkus = Get-MgSubscribedSku
foreach ($sku in $SubscribedSkus) {
    $SkuMap[$sku.SkuId.ToString()] = $sku.SkuPartNumber
}

$Report = @()

foreach ($User in $Users) {
    $LastSignIn = $null
    if ($User.SignInActivity -and $User.SignInActivity.LastSignInDateTime) {
        $LastSignIn = [datetime]$User.SignInActivity.LastSignInDateTime
    }

    $InactiveDays = if ($LastSignIn) { (New-TimeSpan -Start $LastSignIn -End (Get-Date)).Days } else { "Never" }

    # Only report if user is inactive
    $IsUnused = if (-not $LastSignIn -or ($LastSignIn -and $InactiveDays -ge $DaysInactive)) { $true } else { $false }
    if (-not $IsUnused) { continue }

    # Convert license GUIDs to friendly names
    $UnusedLicenses = ($User.AssignedLicenses | ForEach-Object {
        $SkuMap[$_.SkuId.ToString()]
    }) -join ", "

    # Fallback if SKU not in map
    if (-not $UnusedLicenses) {
        $UnusedLicenses = ($User.AssignedLicenses | ForEach-Object { $_.SkuId }) -join ", "
    }

    $Report += [PSCustomObject]@{
        DisplayName       = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        UnusedLicenses    = $UnusedLicenses
        DaysUnused        = $InactiveDays
    }
}

# Export report
$ReportPath = "$env:USERPROFILE\Desktop\M365-Unused-Licenses_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
$Report | Export-Csv $ReportPath -NoTypeInformation -Encoding UTF8

Write-Host "`nUnused license audit complete." -ForegroundColor Green
Write-Host "Report saved to: $ReportPath"
