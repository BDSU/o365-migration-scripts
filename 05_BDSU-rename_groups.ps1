if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

Connect-AzureAD -Credential $credentials

$old_domain = Read-Host -Prompt "Aktuelle Domain (je-domain.de)"
$new_domain = Read-Host -Prompt "Neue Domain (je-domain.bdsu-connect.de)"


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