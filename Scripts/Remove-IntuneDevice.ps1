<#
.SYNOPSIS
    Script to remove a device from:
    - Windows Autopilot
    - Intune
    - Azure AD / Entra ID

    REQUIREMENTS
    - PowerShell 5.1 or higher.
    - Microsoft Graph PS Module

.NOTES
    - Atleast the Intune Admin Role is needed.

.EXAMPLE
.\Remove-IntuneDevice.ps1

#>


# Graph Module - Required
Import-Module Microsoft.Graph.Intune -ErrorAction SilentlyContinue
if (-not (Get-Module Microsoft.Graph.Intune)) {
    Write-Host "Installing Microsoft.Graph.Intune module..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Intune -Scope CurrentUser -Force
    Import-Module Microsoft.Graph
}


# Connect to Graph
Write-Host "Sign in to Graph" -ForegroundColor Cyan
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"


# Ask for Serial Number
$Serial = Read-Host "Enter the Device Serial Number"
Write-Host ""


# Remove Intune Device Function
function Remove-IntuneDevice {
    param([string]$Serial)

    Write-Host "Checking Intune..." -ForegroundColor Cyan

    $intunedevice = Get-MgDeviceManagementManagedDevice `
            -Filter "serialNumber eq '$Serial'" `
            -ErrorAction SilentlyContinue

    if (!$intunedevice) {
        Write-Warning "No Intune device found for serial: $Serial"
        return
    }

    if ($intunedevice.Count -gt 1) {
        Write-Warning "Multiple Intune matches found – review manually."
        return
    }

    Write-Host "Intune device found:" -ForegroundColor Green
    $intunedevice | Select-Object deviceName, serialNumber, userDisplayName | Format-Table

    $confirm = Read-Host "Delete Device from Intune? (Y/N)"
    if ($confirm -ne "Y") { return }

    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $intunedevice.Id
    Write-Host "Removed from Intune." -ForegroundColor Green
}


# Execute Functions
Remove-IntuneDevice -Serial $Serial

Write-Host ""
Write-Host "Script Finished." -ForegroundColor Green
