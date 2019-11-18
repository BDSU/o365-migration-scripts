. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-ExchangeCommands

$domain = $original_domain

$csv = Import-Csv -Path P:\groups.csv

Write-Host "Erstelle Gruppen"
$csv | ForEach-Object {
    $_
    New-DistributionGroup -DisplayName $_.name -Type Security -Name $_.name -PrimarySmtpAddress $_.mail -RequireSenderAuthenticationEnabled $false
} | ft name,mail


Write-Host "Füge E-Mail-Addressen hinzu"
$csv | ForEach-Object {
    $_
    $proxyAddresses = $_.proxyAddresses.Split("|") | Where-Object {$_ -like "*@$domain"}
    Set-DistributionGroup -EmailAddresses $proxyAddresses -Identity $_.mail
} | ft name,mail,proxyAddresses


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}