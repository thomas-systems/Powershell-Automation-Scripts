################################################
### ADD ROOM TO LOCATION (RoomList)
## Cloud Only.
################################################

$domain = Read-Host "Enter your organisation domain e.g contoso.tld"

# Connect to Exchange Online
Connect-ExchangeOnline -ShowBanner:$false

$RoomName = Read-Host "Enter the Room mailbox Name e.g Test Room"
$LocatieNaam = Read-Host "Enter the Location Name e.g Londen"
$Locatie = "$LocatieNaam@$domain"

$MailboxRuimte = Get-Mailbox -Identity $RoomName

$Ruimte = $MailboxRuimte.ExternalDirectoryObjectId

# Add room to location
try {
    Add-DistributionGroupMember -Identity $Locatie -Member $Ruimte
    Write-Host "Room $RoomUPN successfully added to location $LocationEmail" -ForegroundColor Green
} catch {
    Write-Host "Failed to add room. Error: $_" -ForegroundColor Red
}

# Disconnect
Disconnect-ExchangeOnline

Pause
