. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-AzureAD
Ensure-ExchangeCommands

$old_domain = $original_domain
$new_domain = $tmp_domain

$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$old_domain"} | sort DisplayName
$mailboxes | ForEach-Object {
    $_
    $upn = $_.UserPrincipalName -replace "@$old_domain","@$new_domain"
    $proxyAddresses = $_.EmailAddresses | ForEach-Object {
        $_ -replace "@$old_domain","@$new_domain"
    } | sort -Unique
    Set-AzureADUser -ObjectId $_.UserPrincipalName -UserPrincipalName $upn
    Set-Mailbox -EmailAddresses $proxyAddresses -HiddenFromAddressListsEnabled $true -Identity $_.UserPrincipalName
} | ft


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}