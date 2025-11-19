<#
.SYNOPSIS
    Export-ADGroupMembers Script
.DESCRIPTION
    - Prompts for group name (supports wildcard *)
    - Shows found groups and asks for confirmation
    - Exports each group member to CSV file
    - Exports combined results to AllGroups.csv
#>

# Do
function Start-GroupExport {
    do {
    Import-Module ActiveDirectory -ErrorAction Stop

# Make sure that export folder exists, or creates it.
$outPath = Join-Path $PSScriptRoot "output"
if (-not (Test-Path $outPath)) { New-Item -ItemType Directory -Path $outPath | Out-Null }

$groups = $null

# Group Section
do {
    try {
        $entry = Read-Host "Enter group name (supports *)"
        $groups = Get-ADGroup -Filter "Name -like '$entry'" -ErrorAction Stop

        if (!$groups) { throw "No groups returned" }

        Write-Host "\nGroups found:" -ForegroundColor Cyan
        $groups.Name | ForEach-Object { Write-Host " - $_" }

        $choice = Read-Host "Press Y to continue, any other key to retry"
        if ($choice -notmatch '^(Y|y)$') { $groups = $null }

    } catch {
        Write-Host "No groups found, please try again." -ForegroundColor Red
        $groups = $null
    }
} while (!$groups)

# Export AD Group Members
$LatestQuery = @()

foreach ($group in $groups) {
    Write-Host "Exporting members for group: $($group.Name) ..." -ForegroundColor Yellow

    $output = @()

    $members = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue

    foreach ($m in $members) {
        if ($m.objectClass -eq "user") {
            $user = Get-ADUser $m -Properties mail
            $output += [PSCustomObject]@{
                Member      = $user.Name
                MailAddress = $user.Mail
                Group       = $group.Name
                # Add more here if needed.
            }
        } else {
            $output += [PSCustomObject]@{
                Member      = $m.Name
                MailAddress = "N/A"
                Group       = $group.Name
                # Add more here if needed.
            }
        }
    }

    $csvName = Join-Path $outPath ("$($group.Name).csv")
    $output | Export-Csv $csvName -NoTypeInformation -Delimiter ';' -Encoding UTF8

    Write-Host "CSV Exported to: $csvName" -ForegroundColor Green

    $LatestQuery += $output
}

# Export Combined File.
$combined = Join-Path $outPath "AllGroups.csv"
$LatestQuery | Export-Csv $combined -NoTypeInformation -Delimiter ';' -Encoding UTF8
Write-Host "Combined export saved to: $combined" -ForegroundColor Green

Write-Host "Completed - Find the files here: $outPath" -ForegroundColor Cyan

        # Loop loop.
        $again = Read-Host "Do you want to export another group? (Y/N)"
    } while ($again -match '^(Y|y)$')
}

# Run actual function
Start-GroupExport
