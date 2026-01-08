<#
.SYNOPSIS
    Universal Windows System Export Script

.DESCRIPTION
    Collects a complete baseline inventory of a Windows system for
    operational, security, and troubleshooting purposes.

    The script gathers:
      • OS & patch information
      • Hardware (CPU, RAM, BIOS)
      • Disk usage
      • Network configuration
      • Local Administrators group members
      • Installed software
      • Running services
      • Startup items

    Results are exported to CSV and TXT formats for documentation, reporting,
    change tracking, and auditing.

.PARAMETER OutputPath
    Optional. The folder where the reports will be saved. Default: C:\Reports

.EXAMPLE
    .\Windows-System-Export.ps1
    Runs the script and saves reports to C:\Reports.

.EXAMPLE
    .\Windows-Hardware-Export.ps1 -OutputPath "D:\SysAdminReports"
    Runs the script and saves reports to a custom folder.

.AUTHOR
    Thomas-Systems

.VERSION
    1.0

.REQUIREMENTS
    - PowerShell 5.1 or later
    - Local admin rights recommended (for full visibility)
#>

param(
    [string]$OutputPath = "C:\Reports"
)

######################################################################################################
# INITIAL SETUP
######################################################################################################

$Timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$CsvFile   = "System-Baseline_$env:COMPUTERNAME_$Timestamp.csv"
$TxtFile   = "System-Baseline_$env:COMPUTERNAME_$Timestamp.txt"

if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory | Out-Null
}

$CsvData = @()
$TxtData = @()

function Add-Section { param ($Title) $TxtData += "`n=== $Title ===" }

######################################################################################################
# SYSTEM INFORMATION
######################################################################################################

Add-Section "System Information"

$OS  = Get-CimInstance Win32_OperatingSystem
$CS  = Get-CimInstance Win32_ComputerSystem
$BIOS = Get-CimInstance Win32_BIOS

$CsvData += [PSCustomObject]@{ Category = "System"; Name = "ComputerName"; Value = $env:COMPUTERNAME }
$CsvData += [PSCustomObject]@{ Category = "System"; Name = "OS"; Value = "$($OS.Caption) ($($OS.Version))" }
$CsvData += [PSCustomObject]@{ Category = "System"; Name = "LastBootTime"; Value = $OS.LastBootUpTime }
$CsvData += [PSCustomObject]@{ Category = "System"; Name = "BIOSVersion"; Value = $BIOS.SMBIOSBIOSVersion }

$TxtData += "Computer Name : $env:COMPUTERNAME"
$TxtData += "OS            : $($OS.Caption)"
$TxtData += "Version       : $($OS.Version)"
$TxtData += "Last Boot     : $($OS.LastBootUpTime)"
$TxtData += "BIOS Version  : $($BIOS.SMBIOSBIOSVersion)"

######################################################################################################
# HARDWARE
######################################################################################################

Add-Section "Hardware"

$TxtData += "Manufacturer  : $($CS.Manufacturer)"
$TxtData += "Model         : $($CS.Model)"
$TxtData += "RAM (GB)      : {0:N2}" -f ($CS.TotalPhysicalMemory / 1GB)

$CsvData += [PSCustomObject]@{ Category = "Hardware"; Name = "Manufacturer"; Value = $CS.Manufacturer }
$CsvData += [PSCustomObject]@{ Category = "Hardware"; Name = "Model"; Value = $CS.Model }
$CsvData += [PSCustomObject]@{ Category = "Hardware"; Name = "RAM_GB"; Value = [math]::Round($CS.TotalPhysicalMemory / 1GB, 2) }

######################################################################################################
# DISK USAGE
######################################################################################################

Add-Section "Disk Usage"

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $FreePct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
    $TxtData += ("{0}  {1:N1} GB free ({2}%)" -f $_.DeviceID, ($_.FreeSpace / 1GB), $FreePct)
    $CsvData += [PSCustomObject]@{ Category = "Disk"; Name = $_.DeviceID; Value = "$FreePct% free" }
}

######################################################################################################
# NETWORK
######################################################################################################

Add-Section "Network Configuration"

Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "169.*" } |
    ForEach-Object {
        $TxtData += "$($_.InterfaceAlias) - $($_.IPAddress)"
        $CsvData += [PSCustomObject]@{ Category = "Network"; Name = $_.InterfaceAlias; Value = $_.IPAddress }
    }

######################################################################################################
# LOCAL ADMINISTRATORS
######################################################################################################

Add-Section "Local Administrators"

try {
    $Admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
    foreach ($Admin in $Admins) {
        $TxtData += $Admin.Name
        $CsvData += [PSCustomObject]@{ Category = "LocalAdmin"; Name = "Member"; Value = $Admin.Name }
    }
} catch {
    $TxtData += "Unable to enumerate local administrators."
}

######################################################################################################
# INSTALLED SOFTWARE
######################################################################################################

Add-Section "Installed Software"

$Software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object DisplayName

foreach ($App in $Software) {
    $CsvData += [PSCustomObject]@{ Category = "Software"; Name = $App.DisplayName; Value = $App.DisplayVersion }
}

$TxtData += "Total installed applications: $($Software.Count)"

######################################################################################################
# SERVICES
######################################################################################################

Add-Section "Running Services"

Get-Service | Where-Object Status -eq "Running" | ForEach-Object {
    $CsvData += [PSCustomObject]@{ Category = "Service"; Name = $_.Name; Value = $_.DisplayName }
}

$TxtData += "Running services captured."

######################################################################################################
# STARTUP ITEMS
######################################################################################################

Add-Section "Startup Items"

Get-CimInstance Win32_StartupCommand | ForEach-Object {
    $CsvData += [PSCustomObject]@{ Category = "Startup"; Name = $_.Name; Value = $_.Command }
}

######################################################################################################
# EXPORT
######################################################################################################

$CsvData | Export-Csv (Join-Path $OutputPath $CsvFile) -NoTypeInformation -Encoding UTF8
$TxtData | Out-File (Join-Path $OutputPath $TxtFile) -Encoding UTF8

Write-Host "`nSystem baseline inventory completed." -ForegroundColor Green
Write-Host "Reports saved to:" -ForegroundColor Yellow
Write-Host $OutputPath

Pause
