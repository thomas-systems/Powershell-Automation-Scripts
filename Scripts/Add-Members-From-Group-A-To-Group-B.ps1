$source = read-host "Which group do you want to get the members from?"
do{
try{
$members = $null
$members = (Get-ADGroup -Properties members $source).members
write-host "Found the following members:"
$members | foreach {(get-aduser $_).name}
}
catch{$source = read-host "Source group not found, please retry"}
}while(!$members)




$target = read-host "Which group do you want to add the members to?"
do{
try{
$targetconfirmed = $null
$targetconfirmed = (get-adgroup $target).name
write-host "Found target group $targetconfirmed"}
catch{
$target = read-host "Target group not found, please retry"}}
while(!$targetconfirmed)

$continue = read-host "Are you sure you want to add the users to targetgroup? Type Y/N"
do{
    switch($continue){
        default {write-host "Are you sure you want to add the users to targetgroup? Type Y/N"}
        y {$continue = $null; Add-ADGroupMember -Members $members -Identity $target; write-host "Users added."}
        n {$continue = $null; write-host "Users won't be added."}
    }
   }
while($continue)
