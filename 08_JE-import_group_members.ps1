. "$PSScriptRoot\utils.ps1"

Ensure-ExchangeCommands



$csv = Import-Csv -Path P:\groups.csv

Write-Host "Füge Mitglieder zu Gruppen hinzu"

$csv | ForEach-Object {
    $group = $_
    Write-Host $group.name

    $group.members.Split("|") | Where-Object {$_} | ForEach-Object {
        Write-Host "`t$_"
        Add-DistributionGroupMember -Identity $group.mail -Member $_
    }
}



if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}