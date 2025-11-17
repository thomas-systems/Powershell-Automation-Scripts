<#
.HEADER
    Retrieves all Microsoft 365 users using Microsoft Graph and exports them to CSV.

.DESCRIPTION
    This script connects to Microsoft Graph, collects user details
    Output is saved to a timestamped CSV file in the "Exports" folder.

.NOTES
    Author: Thomas-Systems
    Version: 1.0

.RUN SCRIPT
    .\Get-M365Users.ps1
#>

# -----------------------------
#   1. Install Modules
# -----------------------------
Write-Host "Checking Microsoft Graph module..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph")) {
    Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

# -----------------------------
#   2. Create Export Folder
# -----------------------------
$ExportFolder = Join-Path $PSScriptRoot "Exports"

if (-not (Test-Path $ExportFolder)) {
    Write-Host "Creating export folder: $ExportFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ExportFolder | Out-Null
}

# -----------------------------
#   3. Connect to Graph
# -----------------------------
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All" | Out-Null
Select-MgProfile -Name "beta"

# -----------------------------
#   4. Retrieve Users
# -----------------------------
Write-Host "Retrieving Microsoft 365 users..." -ForegroundColor Cyan

$Users = Get-MgUser -All -Property DisplayName,UserPrincipalName,Mail,AccountEnabled,AssignedLicenses,AssignedPlans,CreatedDateTime,UserType

if (-not $Users) {
    Write-Host "No users found or insufficient permissions." -ForegroundColor Red
    exit
}

$Output = foreach ($User in $Users) {

    # Convert license GUIDs to readable names
    $LicenseNames = ($User.AssignedLicenses.SkuId | ForEach-Object {
        Get-MgSubscribedSku | Where-Object { $_.SkuId -eq $_ } | Select-Object -ExpandProperty SkuPartNumber
    }) -join "; "

    [pscustomobject]@{
        DisplayName       = $User.DisplayName
        UserPrincipalName = $User.UserPrincipalName
        Mail              = $User.Mail
        Enabled           = $User.AccountEnabled
        UserType          = $User.UserType
        Created           = $User.CreatedDateTime
        Licenses          = $LicenseNames
    }
}

# -----------------------------
#   5. Export CSV
# -----------------------------
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$CSVPath = Join-Path $ExportFolder "M365-Users-$Timestamp.csv"

$Output | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8

Write-Host "Export finished!" -ForegroundColor Green
Write-Host "Export saved to: $CSVPath" -ForegroundColor Green

# -----------------------------
#   6. Disconnect Graph
# -----------------------------
Disconnect-MgGraph
