if (!$credentials) {
    $credentials = Get-Credential
}

Connect-AzureAD -Credential $credentials


$domain = Read-Host -Prompt "Aktuelle Domain (je-domain.de)"

$groups = Get-AzureADGroup -All $true | Where-Object {$_.ProxyAddresses -like "*@$domain"} | sort DisplayName

$csv = $groups | Where-Object {
    $_.Mail -like "*@$domain"
} | ForEach-Object {
    Write-Host $_.DisplayName
    $members = Get-AzureADGroupMember -ObjectId $_.ObjectId
    $groups = $members | Where-Object {$_.ObjectType -eq "Group"}
    [psCustomObject]@{
        name = $_.DisplayName
        mail = $_.Mail
        proxyAddresses = $_.proxyAddresses -join "|"
        members = $members.userPrincipalName -join "|"
        subgroups = $groups.mail -join "|"
    }
}

$csv | Export-Csv -Encoding UTF8 -NoTypeInformation -Path P:\groups.csv


$nonprimaries = $groups | Where-Object {
    $_.Mail -notlike "*@$domain"
}

if ($nonprimaries) {
    Write-Warning "Folgende Gruppen wurden NICHT exportiert, da sie eine primäre E-Mail von einer anderen Domain haben"
    $nonprimaries | ft -AutoSize ObjectId,DisplayName,Mail,ProxyAddresses
}

$extramembers = $groups | Where-Object {
    $members = Get-AzureADGroupMember -ObjectId $_.ObjectId
    $extras = $members | Where-Object {$_.Mail -notlike "*@$domain"}
}

if ($extramembers) {
    Write-Warning "Folgende Gruppen haben Mitglieder, deren Haupt-E-Mail eine andere Domain verwendet"
    $extramembers | ft -AutoSize
}


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}