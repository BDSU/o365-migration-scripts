. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-ExchangeCommands

$domain = $original_domain


$csv = Import-Csv -Path P:\groups.csv

Write-Host "Füge Mitglieder zu Gruppen hinzu"

$csv | ForEach-Object {
    $group = $_
    Write-Host $group.name

    $group.members.Split("|") | Where-Object {$_ -like "*@$domain"} | ForEach-Object {
        Write-Host "`t$_"
        Add-DistributionGroupMember -Identity $group.mail -Member $_
    }
}



if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}