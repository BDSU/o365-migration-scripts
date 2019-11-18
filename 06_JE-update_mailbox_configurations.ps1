. "$PSScriptRoot\utils.ps1"

Ensure-ExchangeCommands


$csv = Import-Csv -Path P:\mailbox-settings.csv
$csv | ForEach-Object {
    $_
    $proxyAddresses = $_.proxyAddresses.Split('|')
    Set-Mailbox -EmailAddresses $proxyAddresses -Identity $_.UserPrincipalName
    Set-MailboxRegionalConfiguration -Identity $_.UserPrincipalName -DateFormat $_.DateFormat -Language $_.Language -TimeFormat $_.TimeFormat -LocalizeDefaultFolderName -TimeZone $_.TimeZone
} | ft


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}