if (!$credentials) {
    $credentials = Get-Credential
}

Connect-AzureAD -Credential $credentials


$csv = Import-Csv -Path P:\groups.csv

Write-Host "Lade Benutzer und Gruppen"

$users = Get-AzureADUser -All $true
$groups = Get-AzureADGroup -All $true | Where-Object {"smtp:$($_.Mail)" -iin $csv.mail}

Write-Host "Füge Mitglieder zu Gruppen hinzu"

$groups | ForEach-Object {
    $group = $_

    $groups | Where-Object {
        $group.subgroups -and $_.Mail -in $group.subgroups.Split("|")
    } | ForEach-Object {
        Write-Host "Adding '$($_.DisplayName)' to $($group.DisplayName)"
        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $_.ObjectId
    }

    $users | Where-Object {
        $group.members -and $_.UserPrincipalName -in $group.members.Split("|")
    } | ForEach-Object {
        Write-Host "Adding '$($_.DisplayName)' to $($group.DisplayName)"
        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $_.ObjectId
    }
}



if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}