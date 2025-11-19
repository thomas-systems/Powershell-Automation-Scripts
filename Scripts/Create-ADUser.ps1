<#
.SYNOPSIS
    Simple Create-ADUser script.
    Creates a minimal user in your Active Directory
    Tweak it for your requirements!
    Very Basic Script.

.DESCRIPTION
    Creates a new Active Directory user based on minimal information. 
    Includes password creation and enables the user.

.AUTHOR
    Thomas-Systems
#>

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "=== Create AD User ===" -ForegroundColor Cyan

# Input Correct Information
do {
    $GivenName     = Read-Host "Enter First Name"
} until ($GivenName)

do {
    $Surname       = Read-Host "Enter Last Name"
} until ($Surname)

do {
    $Sam           = Read-Host "Enter SamAccountName (username)"
} until ($Sam)

do {
    $UPNdomain     = Read-Host "Enter UPN domain (e.g. company.local or company.com)"
} until ($UPNdomain)

# Attribute Mapping
$DisplayName      = "$GivenName $Surname"
$UPN              = "$Sam@$UPNdomain"

Write-Host "\nCreating user:" -ForegroundColor Yellow
Write-Host "  Display Name : $DisplayName"
Write-Host "  Username      : $Sam"
Write-Host "  UPN          : $UPN"

# Create a Password for the user
do {
    $Password1 = Read-Host "Enter Password" -AsSecureString
    $Password2 = Read-Host "Confirm Password" -AsSecureString

    $p1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password1))
    $p2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password2))

    if ($p1 -ne $p2) {
        Write-Host "Passwords do not match. Try again." -ForegroundColor Red
    }
} until ($p1 -eq $p2)

# Specify OU use the default Users OU
Write-Host "You may specify an OU or press Enter to use the default Users container." -ForegroundColor Cyan
$OU = Read-Host "Enter DN of OU (optional)"

# User Parameters
try {
    $UserParams = @{
        GivenName        = $GivenName
        Surname          = $Surname
        Name             = $DisplayName
        DisplayName      = $DisplayName
        SamAccountName   = $Sam
        UserPrincipalName= $UPN
        AccountPassword  = $Password1
        Enabled          = $true
    }

    if ($OU) {
        $UserParams["Path"] = $OU
    }
    # Creates the user based on Parameters.
    New-ADUser @UserParams -ErrorAction Stop
    Write-Host "User created successfully." -ForegroundColor Green
} catch {
    Write-Host "Error creating user: $($_.Exception.Message)" -ForegroundColor Red
    exit
    pause
}

Write-Host "User $DisplayName created!" -ForegroundColor Green

Pause
