<#
.SYNOPSIS
    Universal Active Directory User Audit Script

.DESCRIPTION
    Performs a read-only audit of Active Directory user accounts.
    Designed to run safely in any organisation without modifying data.

    The audit identifies:
      • Disabled user accounts
      • Inactive users (based on last logon)
      • Accounts that never logged on
      • Expired passwords
      • Passwords that never expire
      • Accounts with password not required
      • Privileged accounts (Domain / Enterprise / Schema Admins)
      • Recently created users
      • Accounts missing a description

    Results are exported to CSV for reporting and compliance purposes.

.AUTHOR
    Thomas-Systems

.VERSION
    1.2

.REQUIREMENTS
    - RSAT ActiveDirectory module
    - Read access to Active Directory
#>

Import-Module ActiveDirectory -ErrorAction Stop

######################################################################################################
# CONFIGURATION
######################################################################################################

# Inactivity threshold (days)
$InactiveDays = 90

# Recently created account threshold (days)
$NewUserDays = 14

# Report output
$ReportPath = "C:\Reports"
$ReportFile = "ActiveDirectory-Audit_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"

# Standard privileged groups (may not exist in all environments)
$PrivilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins"
)

######################################################################################################
# PRE CHECKS...
######################################################################################################

if (-not (Test-Path $ReportPath)) {
    New-Item -Path $ReportPath -ItemType Directory | Out-Null
}

$Today       = Get-Date
$InactiveCut = $Today.AddDays(-$InactiveDays)
$NewUserCut  = $Today.AddDays(-$NewUserDays)

Write-Host "Starting Active Directory user audit..." -ForegroundColor Cyan

######################################################################################################
# PRIVILEGED ACCOUNTS
######################################################################################################

$PrivilegedUsers = @()

foreach ($Group in $PrivilegedGroups) {
    try {
        $Members = Get-ADGroupMember $Group -Recursive -ErrorAction Stop |
            Where-Object { $_.objectClass -eq "user" } |
            Select-Object -ExpandProperty SamAccountName

        $PrivilegedUsers += $Members
    } catch {
        # Group may not exist or be accessible — ignore safely
        continue
    }
}

$PrivilegedUsers = $PrivilegedUsers | Sort-Object -Unique

######################################################################################################
# USER DATA COLLECTION
######################################################################################################

$Users = Get-ADUser -Filter * -Properties `
    Enabled,
    DisplayName,
    SamAccountName,
    UserPrincipalName,
    LastLogonDate,
    PasswordExpired,
    PasswordNeverExpires,
    PasswordNotRequired,
    WhenCreated,
    Description

$Results = foreach ($User in $Users) {

    $NeverLoggedOn = -not $User.LastLogonDate
    $IsInactive   = $NeverLoggedOn -or ($User.LastLogonDate -lt $InactiveCut)
    $IsNewUser    = $User.WhenCreated -gt $NewUserCut
    $NoDesc       = [string]::IsNullOrWhiteSpace($User.Description)
    $Privileged   = $PrivilegedUsers -contains $User.SamAccountName

    [PSCustomObject]@{
        DisplayName           = $User.DisplayName
        SamAccountName        = $User.SamAccountName
        UserPrincipalName     = $User.UserPrincipalName
        Enabled               = $User.Enabled
        PrivilegedAccount     = $Privileged
        LastLogonDate         = $User.LastLogonDate
        NeverLoggedOn         = $NeverLoggedOn
        InactiveOverDays      = $InactiveDays
        IsInactive            = $IsInactive
        PasswordExpired       = $User.PasswordExpired
        PasswordNeverExpires  = $User.PasswordNeverExpires
        PasswordNotRequired   = $User.PasswordNotRequired
        RecentlyCreated       = $IsNewUser
        DescriptionMissing    = $NoDesc
        AccountCreated        = $User.WhenCreated
    }
}

######################################################################################################
# EXPORT RESULTS
######################################################################################################

$FullPath = Join-Path $ReportPath $ReportFile

$Results |
    Sort-Object Enabled, IsInactive |
    Export-Csv -Path $FullPath -NoTypeInformation -Encoding UTF8

######################################################################################################
# AUDIT OUTPUT
######################################################################################################

Write-Host "Audit completed successfully." -ForegroundColor Green
Write-Host "------------------------------------------------"

Write-Host ("Total users              : {0}" -f $Results.Count)
Write-Host ("Enabled users            : {0}" -f ($Results | Where-Object Enabled).Count)
Write-Host ("Disabled users           : {0}" -f ($Results | Where-Object { -not $_.Enabled }).Count)
Write-Host ("Inactive users           : {0}" -f ($Results | Where-Object IsInactive).Count)
Write-Host ("Never logged on           : {0}" -f ($Results | Where-Object NeverLoggedOn).Count)
Write-Host ("Password expired         : {0}" -f ($Results | Where-Object PasswordExpired).Count)
Write-Host ("Password never expires   : {0}" -f ($Results | Where-Object PasswordNeverExpires).Count)
Write-Host ("Password not required    : {0}" -f ($Results | Where-Object PasswordNotRequired).Count)
Write-Host ("Privileged accounts      : {0}" -f ($Results | Where-Object PrivilegedAccount).Count)
Write-Host ("Recently created users   : {0}" -f ($Results | Where-Object RecentlyCreated).Count)
Write-Host ("Missing description      : {0}" -f ($Results | Where-Object DescriptionMissing).Count)

Write-Host "------------------------------------------------"
Write-Host "Report exported to:" -ForegroundColor Green
Write-Host $FullPath -ForegroundColor Yellow

Pause
