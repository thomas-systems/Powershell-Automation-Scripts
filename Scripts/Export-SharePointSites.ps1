<#
.SYNOPSIS
    Exports all SharePoint Online site URLs to a text file.

.DESCRIPTION
    This script connects to SharePoint Online using PnP.PowerShell and retrieves
    all site collections from the tenant. All site URLs are exported to a
    text file inside the "Exports" folder.

.NOTES
    Author: Thomas-Systems
    Version: 1.0

.EXAMPLE
    .\Export-SharePointSites.ps1
#>

# -------------------------------------
# 1. PHP Module Install
# -------------------------------------
Write-Host "Checking PnP.PowerShell module..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name "PnP.PowerShell")) {
    Write-Host "PnP.PowerShell not found. Installing..." -ForegroundColor Yellow
    Install-Module PnP.PowerShell -Scope CurrentUser -Force
}

Import-Module PnP.PowerShell

# -------------------------------------
# 2. Ask for tenant name
# -------------------------------------
$Tenant = Read-Host -Prompt "Enter your tenant name (example: contoso)"
$AdminUrl = "https://$Tenant-admin.sharepoint.com"

Write-Host "Connecting to: $AdminUrl" -ForegroundColor Cyan

# -------------------------------------
# 3. Connect to SharePoint Admin Center
# -------------------------------------
Connect-PnPOnline -Url $AdminUrl -Interactive

# -------------------------------------
# 4. Create export folder
# -------------------------------------
$ExportFolder = Join-Path $PSScriptRoot "Exports"

if (-not (Test-Path $ExportFolder)) {
    Write-Host "Creating export folder at $ExportFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ExportFolder | Out-Null
}

# -------------------------------------
# 5. Get all site collections
# -------------------------------------
Write-Host "Retrieving all SharePoint Online sites..." -ForegroundColor Cyan

$Sites = Get-PnPTenantSite -IncludeOneDriveSites:$false

if (-not $Sites) {
    Write-Host "No sites found or missing permissions." -ForegroundColor Red
    exit
}

# -------------------------------------
# 6. Export URLs
# -------------------------------------
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$OutputPath = Join-Path $ExportFolder "SharePoint-SiteUrls-$Date.txt"

$Sites.Url | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "---------------------------------" -ForegroundColor Green
Write-Host " Export complete!" -ForegroundColor Green
Write-Host " $($Sites.Count) site URLs exported" -ForegroundColor Green
Write-Host " Saved to: $OutputPath" -ForegroundColor Green
Write-Host "---------------------------------" -ForegroundColor Green
