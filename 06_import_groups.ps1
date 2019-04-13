if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}


$csv = Import-Csv -Path P:\groups.csv

Write-Host "Erstelle Gruppen"
$csv | ForEach-Object {
    $_
    New-DistributionGroup -DisplayName $_.name -Type Security -Name $_.name -PrimarySmtpAddress $_.mail -RequireSenderAuthenticationEnabled $false
} | ft name,mail


Write-Host "Füge E-Mail-Addressen hinzu"
$csv | ForEach-Object {
    $_
    $proxyAddresses = $_.proxyAddresses.Split("|")
    Set-DistributionGroup -EmailAddresses $proxyAddresses -Identity $_.mail
} | ft name,mail,proxyAddresses


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}