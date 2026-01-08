Import-Module ExchangeOnlineManagement

Write-Host "Connecting to Exchange Online…" -ForegroundColor Cyan
Connect-ExchangeOnline -ShowBanner:$false

Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "   ALL LOCATIONS + ROOMS" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# RoomLists = Locations
$RoomLists = Get-DistributionGroup -RecipientTypeDetails RoomList | Sort-Object DisplayName

if (-not $RoomLists) {
    Write-Host "No locations (RoomLists) found!" -ForegroundColor Yellow
} else {
    foreach ($RL in $RoomLists) {
        Write-Host ""
        Write-Host "Location: $($RL.DisplayName)" -ForegroundColor Green
        Write-Host "Members (Rooms):"

        $Members = Get-DistributionGroupMember -Identity $RL.PrimarySmtpAddress -ErrorAction SilentlyContinue

        if ($Members) {
            $Members | Select DisplayName, PrimarySmtpAddress | Format-Table -AutoSize
        } else {
            Write-Host "  - No rooms assigned." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=======================" -ForegroundColor Green
Write-Host "  ALL ROOM MAILBOXES" -ForegroundColor Green
Write-Host "======================="  -ForegroundColor Green

# All rooms in EXO
$AllRooms = Get-Mailbox -RecipientTypeDetails RoomMailbox | Sort-Object DisplayName
$AllRooms | Select DisplayName, PrimarySmtpAddress | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================" -ForegroundColor Red
Write-Host "   ROOMS NOT ASSIGNED TO ANY LOCATION" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red

# Flatten list of all rooms that *are* assigned
$AssignedRoomUPNs = @()
foreach ($RL in $RoomLists) {
    $Members = Get-DistributionGroupMember -Identity $RL.PrimarySmtpAddress -ErrorAction SilentlyContinue
    if ($Members) {
        $AssignedRoomUPNs += $Members.PrimarySmtpAddress
    }
}

# Compare to all rooms
$UnassignedRooms = $AllRooms | Where-Object { $_.PrimarySmtpAddress -notin $AssignedRoomUPNs }

if ($UnassignedRooms) {
    $UnassignedRooms | Select DisplayName, PrimarySmtpAddress | Format-Table -AutoSize
} else {
    Write-Host "All rooms are assigned to locations." -ForegroundColor Green
}

Write-Host ""
Write-Host "Done."
Disconnect-ExchangeOnline -Confirm:$false

Pause
