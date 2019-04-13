if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

$csv = Import-Csv -Path P:\groups.csv

Write-Host "Füge Mitglieder zu Gruppen hinzu"

$csv | ForEach-Object {
    $group = $_
    Write-Host $group.name

    $group.subgroups.Split("|") | Where-Object {$_} | ForEach-Object {
        Write-Host "`t$_"
        Add-DistributionGroupMember -Identity $group.mail -Member $_
    }

    $group.members.Split("|") | Where-Object {$_} | ForEach-Object {
        Write-Host "`t$_"
        Add-DistributionGroupMember -Identity $group.mail -Member $_
    }
}



if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}