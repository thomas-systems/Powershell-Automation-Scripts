<#
.SYNOPSIS
    Interactive Active Directory user search and overview script.

.DESCRIPTION
    This script allows administrators to search Active Directory for a user
    using common identifiers such as Display Name, Email, UPN, SamAccountName,
    or Employee Number. It returns a detailed overview of the user account,
    including manager information, account status, license groups, Citrix
    access, and messaging attributes.

.AUTHOR
    Thomas-Systems

.VERSION
    1.0.0

.REQUIREMENTS
    - ActiveDirectory PowerShell module
    - Appropriate AD read permissions

.NOTES
    - License and Citrix group name filters are placeholders.
      Update or remove them to match your environment.
    - Designed for interactive use in PowerShell console.
#>

Import-Module ActiveDirectory

# Header
Write-Host
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "   Search Active Directory           " -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host
do {
    
    $searchTerm = Read-Host "Enter a user search term (DisplayName, Email, UPN, SamAccountName, EmployeeNumber)"

    
    $ldapFilter = "(|(displayName=*$searchTerm*)(mail=*$searchTerm*)(userPrincipalName=*$searchTerm*)(sAMAccountName=*$searchTerm*)(employeeID=*$searchTerm*))"
    $user = Get-ADUser -LDAPFilter $ldapFilter -Properties * 

    if ($null -eq $user) {
        Write-Host "User not found!" -ForegroundColor Red
    } else {
        
        $managerName = if ($user.Manager) {
            (Get-ADUser -Identity $user.Manager -Properties DisplayName).DisplayName
        } else { "No Manager Assigned" }

        ## Make sure to CHANGE the License Groups to your groups or remove block.
        $licensesList = @()
        $citrixGroupsList = @()
        $user.MemberOf | ForEach-Object {
            $groupName = (Get-ADGroup $_).Name
            if ($groupName -like "LicenseGroup*") { $licensesList += $groupName }
            if ($groupName -like "CitrixGroup*") { $citrixGroupsList += $groupName }
        }
        $licenses = if ($licensesList) { $licensesList -join ", " } else { "None" }

        
        $citrix = if ($citrixGroupsList.Count -gt 0) { "YES (" + ($citrixGroupsList -join ", ") + ")" } else { "NO" }

        
        $accountExpiration = if ($user.AccountExpirationDate) { $user.AccountExpirationDate } else { "Never" }

        
        $proxyAddresses = if ($user.ProxyAddresses) { $user.ProxyAddresses -join ", " } else { "None" }
        $targetAddress  = if ($user.TargetAddress)  { $user.TargetAddress }  else { "None" }

        
        $userOverview = [PSCustomObject]@{
            DisplayName         = $user.DisplayName
            SamAccountName      = $user.SamAccountName
            UserPrincipalName   = $user.UserPrincipalName
            Email               = $user.Mail
            EmployeeNumber      = $user.EmployeeID
            EmployeeType        = $user.EmployeeType
            Title               = $user.Title
            Department          = $user.Department
            Manager             = $managerName
            Enabled             = $user.Enabled
            WhenCreated         = $user.WhenCreated
            LastLogon           = $user.LastLogonDate
            PasswordLastSet     = $user.PasswordLastSet
            AccountExpiration   = $accountExpiration
            Office              = $user.PhysicalDeliveryOfficeName
            OfficePhone         = $user.OfficePhone
            MobilePhone         = $user.MobilePhone
            Notes               = $user.Info
            Licenses            = $licenses
            Citrix              = $citrix
            ProxyAddresses      = $proxyAddresses
            TargetAddress       = $targetAddress
            #CustomAttribute1 = $user.customAttribute1
            ## Add more Attributes here..
        }

        # Show Results
        $userOverview | Format-List
    }

    # Question
    $continue = Read-Host "Do you want to search another user? (Y/N)"
} while ($continue -match '^[Yy]')
