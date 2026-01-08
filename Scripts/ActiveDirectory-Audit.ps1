<#
.SYNOPSIS
    Active Directory Security Audit with Dashboard Output

.DESCRIPTION
    Performs a Active Directory audit and presents results
    in a dashboard-style output with security insights.

    Designed for:
      • Security reviews
      • Compliance audits
      • Identity governance
      • Sys Admins

.AUTHOR
    Thomas-Systems
.VERSION
    1.0
#>

Import-Module ActiveDirectory -ErrorAction Stop

######################################################################################################
# CONFIGURATION
######################################################################################################

$InactiveDays   = 90
$NewUserDays    = 14
$ReportPath     = "C:\Reports"
$ReportFile     = "ActiveDirectory-Audit_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"

# Add more if needed.
$PrivilegedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins"
)

######################################################################################################
# INITIALIZATION
######################################################################################################

$Today        = Get-Date
$InactiveCut  = $Today.AddDays(-$InactiveDays)
$NewUserCut   = $Today.AddDays(-$NewUserDays)

if (-not (Test-Path $ReportPath)) {
    New-Item -ItemType Directory -Path $ReportPath | Out-Null
}

Write-Host "`n=== Active Directory Security Audit ===" -ForegroundColor Cyan
Write-Host "Scan started: $Today`n"

######################################################################################################
# PRIVILEGED ACCOUNT DISCOVERY
######################################################################################################

$PrivilegedUsers = foreach ($Group in $PrivilegedGroups) {
    try {
        Get-ADGroupMember $Group -Recursive |
        Where-Object objectClass -eq "user" |
        Select-Object -ExpandProperty SamAccountName
    } catch {}
} | Sort-Object -Unique

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
    $Inactive     = $NeverLoggedOn -or ($User.LastLogonDate -lt $InactiveCut)
    $NewAccount   = $User.WhenCreated -gt $NewUserCut
    $NoDesc       = [string]::IsNullOrWhiteSpace($User.Description)
    $Privileged   = $PrivilegedUsers -contains $User.SamAccountName

    # Risk scoring
    $RiskScore = 0
    if ($Privileged)              { $RiskScore += 3 }
    if ($Inactive -and $User.Enabled) { $RiskScore += 3 }
    if ($User.PasswordNotRequired){ $RiskScore += 4 }
    if ($User.PasswordNeverExpires){ $RiskScore += 2 }
    if ($NeverLoggedOn)            { $RiskScore += 1 }

    switch ($RiskScore) {
        {$_ -ge 7} { $RiskLevel = "CRITICAL" }
        {$_ -ge 4} { $RiskLevel = "HIGH" }
        {$_ -ge 2} { $RiskLevel = "MEDIUM" }
        default    { $RiskLevel = "LOW" }
    }

    [PSCustomObject]@{
        DisplayName           = $User.DisplayName
        SamAccountName        = $User.SamAccountName
        Enabled               = $User.Enabled
        Privileged            = $Privileged
        LastLogonDate         = $User.LastLogonDate
        Inactive              = $Inactive
        NeverLoggedOn         = $NeverLoggedOn
        PasswordExpired       = $User.PasswordExpired
        PasswordNeverExpires  = $User.PasswordNeverExpires
        PasswordNotRequired   = $User.PasswordNotRequired
        RiskScore             = $RiskScore
        RiskLevel             = $RiskLevel
        DescriptionMissing    = $NoDesc
        AccountCreated        = $User.WhenCreated
    }
}

######################################################################################################
# EXPORT
######################################################################################################

$FullPath = Join-Path $ReportPath $ReportFile
$Results | Sort-Object RiskScore -Descending |
    Export-Csv -Path $FullPath -NoTypeInformation -Encoding UTF8

######################################################################################################
# DASHBOARD OUTPUT
######################################################################################################

Clear-Host
Write-Host "================ ACTIVE DIRECTORY AUDIT DASHBOARD ================" -ForegroundColor Cyan

function Stat($Label, $Value, $Color="White") {
    Write-Host ("{0,-35}: {1}" -f $Label, $Value) -ForegroundColor $Color
}

Stat "Total Users"                $Results.Count
Stat "Enabled Users"              ($Results | Where-Object Enabled).Count
Stat "Disabled Users"             ($Results | Where-Object { -not $_.Enabled }).Count

Write-Host "`n--- Activity & Hygiene ---" -ForegroundColor Yellow
Stat "Inactive (Enabled) Users"   ($Results | Where-Object { $_.Inactive -and $_.Enabled }).Count "Red"
Stat "Never Logged On"            ($Results | Where-Object NeverLoggedOn).Count "Red"
Stat "Missing Description"        ($Results | Where-Object DescriptionMissing).Count

Write-Host "`n--- Password & Auth Risks ---" -ForegroundColor Yellow
Stat "Password Expired"           ($Results | Where-Object PasswordExpired).Count
Stat "Password Never Expires"     ($Results | Where-Object PasswordNeverExpires).Count "Red"
Stat "Password Not Required"      ($Results | Where-Object PasswordNotRequired).Count "Red"

Write-Host "`n--- Privileged Access ---" -ForegroundColor Yellow
Stat "Privileged Accounts"        ($Results | Where-Object Privileged).Count "Red"
Stat "Privileged + Inactive"      ($Results | Where-Object { $_.Privileged -and $_.Inactive }).Count "Red"
Stat "New Privileged Accounts"    ($Results | Where-Object { $_.Privileged -and $_.AccountCreated -gt $NewUserCut }).Count "Red"

Write-Host "`n--- Risk Distribution ---" -ForegroundColor Yellow
Stat "CRITICAL Risk Users"        ($Results | Where-Object RiskLevel -eq "CRITICAL").Count "Red"
Stat "HIGH Risk Users"            ($Results | Where-Object RiskLevel -eq "HIGH").Count "DarkYellow"
Stat "MEDIUM Risk Users"          ($Results | Where-Object RiskLevel -eq "MEDIUM").Count
Stat "LOW Risk Users"             ($Results | Where-Object RiskLevel -eq "LOW").Count

Write-Host "`n=================================================================="
Write-Host "Report exported to:" -ForegroundColor Green
Write-Host $FullPath -ForegroundColor Yellow

######################################################################################################
# ORGANISATIONAL INSIGHTS
######################################################################################################

Write-Host "`n=== ORGANISATIONAL SECURITY INSIGHTS ===" -ForegroundColor Cyan

if (($Results | Where-Object { $_.Privileged -and $_.Inactive }).Count -gt 0) {
    Write-Host "• Inactive privileged accounts detected — review immediately." -ForegroundColor Red
}

if (($Results | Where-Object PasswordNotRequired).Count -gt 0) {
    Write-Host "• Accounts with 'Password Not Required' found — critical misconfiguration." -ForegroundColor Red
}

if (($Results | Where-Object PasswordNeverExpires).Count -gt 0) {
    Write-Host "• Passwords set to never expire increase credential compromise risk." -ForegroundColor Yellow
}

if (($Results | Where-Object NeverLoggedOn).Count -gt 10) {
    Write-Host "• Large number of never-used accounts — possible provisioning issues." -ForegroundColor Yellow
}

Write-Host "`nRecommended actions:"
Write-Host "• Disable or remove inactive accounts"
Write-Host "• Enforce password policies"
Write-Host "• Review privileged access regularly"
Write-Host "• Maintain proper account descriptions"

Pause
