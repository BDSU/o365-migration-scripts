. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-ExchangeCommands

$old_domain = $original_domain
$new_domain = $tmp_domain


$groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object {
    $_.EmailAddresses -like "*@$old_domain"
}
$groups | ForEach-Object {
    $_
    $proxyAddresses = $_.EmailAddresses | ForEach-Object {
        $_ -replace "@$old_domain","@$new_domain"
    }
    Set-DistributionGroup -EmailAddresses $proxyAddresses -HiddenFromAddressListsEnabled $true -Identity $_.PrimarySmtpAddress -BypassSecurityGroupManagerCheck:$true
} | ft


$ogroups = Get-UnifiedGroup -ResultSize Unlimited | Where-Object {
    $_.PrimarySmtpAddress -like "*@$old_domain"
}
$ogroups | ForEach-Object {
    $_
    $proxyAddresses = $_.PrimarySmtpAddress | ForEach-Object {
        $_ -replace "@$old_domain","@$new_domain"
    }
    Set-UnifiedGroup -EmailAddresses $proxyAddresses -HiddenFromAddressListsEnabled $true -Identity $_.PrimarySmtpAddress
} | ft


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}