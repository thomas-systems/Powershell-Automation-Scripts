<#
.SYNOPSIS
    Export all Intune-managed devices for any tenant to CSV using Graph (Interactive)

.DESCRIPTION
    Connects to Microsoft Graph interactively,
    retrieves all managed devices (including EAS by default), and exports them to CSV.
    Intune Admin Permissions are needed to run the script.

 .EXAMPLE
 .\Get-Intune-Devices.ps1

CSV exports will be saved in the same folder as the script.

#>

#=============================
# Install Module Graph
#=============================
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
    Write-Host "Microsoft.Graph.DeviceManagement module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force -AllowClobber
}

#=============================
# Connect to Microsoft Graph
#=============================
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

#=============================
# Get Managed Devices
#=============================
function Get-ManagedDevices {
    Write-Host "Retrieving all managed devices"
    $allDevices = @()
    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        $allDevices += $response.value
        $uri = $response.'@odata.nextLink'
    } while ($uri -ne $null)

    return $allDevices
}

#=============================
# Export Devices
#=============================
$ManagedDevices = Get-ManagedDevices

$csvPath = Join-Path $PSScriptRoot "Intune-Devices.csv"

$ManagedDevices | ForEach-Object {
    [PSCustomObject]@{
        DeviceName        = $_.deviceName
        UserPrincipalName = $_.userPrincipalName
        DeviceType        = $_.deviceType
        OperatingSystem   = $_.operatingSystem
        IMEI              = $_.imei
    }
} | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Write-Host "Export complete! CSV saved at: $csvPath"

#=============================
# Disconnect Graph
#=============================
Disconnect-MgGraph
