<#
.HEADER
    Exports all empty Active Directory groups for cleanup.

.DESCRIPTION
    This script scans Active Directory for security and distribution groups
    that contain zero members. The results are exported to a CSV
    file inside the "Exports" folder.

.REQUIREMENTS
    - ActiveDirectory PowerShell module
    - Domain-joined system or RSAT tools installed

.NOTES
    Author: Thomas-Systems
    Version: 1.0

.RUN COMMAND
    .\Get-EmptyADGroups.ps1
#>

# -----------------------------
#   1. AD Module
# -----------------------------
Write-Host "Checking ActiveDirectory module..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module not found. Please install RSAT tools." -ForegroundColor Red
    exit
}

Import-Module ActiveDirectory

# -----------------------------
#   2. Create Export Folder
# -----------------------------
$ExportFolder = Join-Path $PSScriptRoot "Exports"

if (-not (Test-Path $ExportFolder)) {
    Write-Host "Creating export directory: $ExportFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ExportFolder | Out-Null
}

# -----------------------------
#   3. Get Empty AD Groups
# -----------------------------
Write-Host "Searching for empty AD groups..." -ForegroundColor Cyan

$Groups = Get-ADGroup -Filter * -Properties Members

$EmptyGroups = $Groups | Where-Object { ($_.Members).Count -eq 0 }

# -----------------------------
#   4. Export Results
# -----------------------------
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$CSVPath = Join-Path $ExportFolder "Empty-AD-Groups-$Date.csv"

$EmptyGroups |
    Select-Object Name, SamAccountName, GroupCategory, GroupScope, DistinguishedName |
    Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8

# -----------------------------
#   5. Output status
# -----------------------------
Write-Host ""
Write-Host "-----------------------------" -ForegroundColor Green
Write-Host " Export finished!" -ForegroundColor Green
Write-Host " Found $($EmptyGroups.Count) empty groups." -ForegroundColor Green
Write-Host " Saved to: $CSVPath" -ForegroundColor Green
Write-Host "-----------------------------" -ForegroundColor Green
Write-Host ""
