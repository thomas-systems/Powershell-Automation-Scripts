<#
.SYNOPSIS
    Applies tenant versioning policy and starts auto-trimming on multiple SharePoint Online sites.
    This script is usefull for cleaning up SharePoint storage.
    DO YOUR RESEARCH BEFORE EXECUTING!

.DESCRIPTION
    For each SharePoint Online site in the provided SiteURLs.txt, the script:
    - Sets site to inherit tenant versioning policy
    - Enables AutoExpirationVersionTrim
    - Starts a version trimming batch job

.NOTES
    Author: Thomas-Systems
    Version: 1.0

.EXAMPLE
    .\Trim-SharePointSites.ps1
#>

# ---------------------------------------------
# 1. Load Site URLs
# ---------------------------------------------
$SiteUrlsPath = Join-Path $PSScriptRoot "SiteURLs.txt"

if (-not (Test-Path $SiteUrlsPath)) {
    Write-Host "SiteURLs.txt not found! Please create it with one site URL per line." -ForegroundColor Red
    pause
    exit
}

$SiteUrls = Get-Content $SiteUrlsPath

# ---------------------------------------------
# 2. Connect to SPO Admin
# ---------------------------------------------
$Tenant = Read-Host -Prompt "Enter your tenant name (example: contoso)"
$AdminUrl = "https://$Tenant-admin.sharepoint.com"

Write-Host "Connecting to SharePoint Online Admin: $AdminUrl" -ForegroundColor Cyan
Connect-SPOService -Url $AdminUrl -Credential (Get-Credential)

# ---------------------------------------------
# 3. Loop through sites and apply trimming
# ---------------------------------------------
foreach ($SiteUrl in $SiteUrls) {
    Write-Host "`nProcessing site: $SiteUrl" -ForegroundColor Yellow

    try {
        # Set tenant versioning policy
        Set-SPOSite -Identity $SiteUrl -InheritVersionPolicyFromTenant -Confirm:$false
        Write-Host "Tenant Policy Set" -ForegroundColor Green

        # Enable AutoExpirationVersionTrim
        Set-SPOSite -Identity $SiteUrl -EnableAutoExpirationVersionTrim $true -ApplyToExistingDocumentLibraries -Confirm:$false
        Write-Host "AutoExpirationVersionTrim Enabled" -ForegroundColor Green

        # Start trimming batch job
        New-SPOSiteFileVersionBatchDeleteJob -Identity $SiteUrl -Automatic -Confirm:$false
        Write-Host "Trim Batch Started" -ForegroundColor Green
    }
    catch {
        Write-Host "Error processing $SiteUrl: $_" -ForegroundColor Red
    }
}

Write-Host "All sites processed! Script completed." -ForegroundColor Cyan
Pause
