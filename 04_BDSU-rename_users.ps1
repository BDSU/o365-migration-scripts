. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-AzureAD
Ensure-ExchangeCommands

$old_domain = $original_domain
$new_domain = $tmp_domain

Write-Host "Ändere Benutzernamen"

$accounts = Get-AzureADUser -All $true | Where-Object {$_.UserPrincipalName -like "*@$old_domain"} | sort DisplayName
$accounts | ForEach-Object {
    $_
    $upn = $_.UserPrincipalName -replace "@$old_domain","@$new_domain"
    Set-AzureADUser -ObjectId $_.ObjectId -UserPrincipalName $upn
} | ft

Write-Host "Ändere E-Mail-Adressen"

$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$old_domain"} | sort DisplayName
$mailboxes | ForEach-Object {
    $_
    $proxyAddresses = $_.EmailAddresses | ForEach-Object {
        $_ -replace "@$old_domain","@$new_domain"
    } | sort -Unique
    Set-Mailbox -EmailAddresses $proxyAddresses -HiddenFromAddressListsEnabled $true -Identity $_.DistinguishedName
} | ft


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}