if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

Connect-AzureAD -Credential $credentials

$domain = Read-Host -Prompt "Aktuelle Domain"

Write-Host "Exportiere User-Liste"

$aadusers = @{}
Get-AzureADUser -All $true | Where-Object {$_.ProxyAddresses -like "*@$domain"} | ForEach-Object {
    $aadusers[$_.UserPrincipalName] = $_
}

$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$domain"} | sort DisplayName

$import_csv = $mailboxes | Where-Object {
    $_.UserPrincipalName -like "*@$domain" -and $_.RecipientTypeDetails -eq "UserMailbox"
} | ForEach-Object {
    Write-Host $_.DisplayName
    $aaduser = $aadusers[$_.UserPrincipalName]
    [psCustomObject]@{
        "﻿User Name" = $aaduser.userPrincipalName
        "First Name" = $aaduser.givenName
        "Last Name" = $aaduser.surname
        "Display Name" = $aaduser.DisplayName
        "Job Title" = $aaduser.JobTitle
        "Department" = $aaduser.department
        "Office Number" = $aaduser.PhysicalDeliveryOfficeName
        "Office Phone" = $aaduser.TelephoneNumber
        "Mobile Phone" = $aaduser.Mobile
        "Fax" = $aaduser.FacsimileTelephoneNumber
        "Address" = $aaduser.StreetAddress
        "City" = $aaduser.City
        "State or Province" = $aaduser.State
        "ZIP or Postal Code" = $aaduser.PostalCode
        "Country or Region" = $aaduser.Country
    }
}

$import_csv | Export-Csv -Encoding UTF8 -NoTypeInformation -Path P:\import-users.csv

Write-Host "Exportiere erweiterte Postfach-Einstellungen"

$csv = $mailboxes | Where-Object {
    $_.UserPrincipalName -like "*@$domain" -and $_.RecipientTypeDetails -eq "UserMailbox"
} | ForEach-Object {
    Write-Host $_.DisplayName
    $config = Get-MailboxRegionalConfiguration -Identity $_.UserPrincipalName
    $proxyAddresses = $_.EmailAddresses | Where-Object {
        $_ -ilike "smtp:*" -and $_ -notlike "*@bdsu-connect.de" -and $_ -notlike "*@BDSUev.onmicrosoft.com"
    }
    [psCustomObject]@{
        UserPrincipalName = $_.UserPrincipalName
        proxyAddresses = $proxyAddresses -join '|'
        Language = $config.Language
        DateFormat = $config.DateFormat
        TimeFormat = $config.TimeFormat
        TimeZone = $config.TimeZone
    }
}

$csv | Export-Csv -Encoding UTF8 -NoTypeInformation -Path P:\mailbox-settings.csv

$extradomains = $csv | Where-Object {
    $_.proxyAddresses -notlike "*@$domain"
}

if ($extradomains) {
    Write-Warning "Folgende Benutzer haben zusätzliche E-Mail-Adressen mit anderen Domains"
    $csv | ft -AutoSize UserPrincipalName,proxyAddresses
}

$nonprimaries = $mailboxes | Where-Object {
    $_.UserPrincipalName -notlike "*@$domain"
}

if ($nonprimaries) {
    Write-Warning "Folgende Postfächer wurden NICHT exportiert, da der Benutzername nicht die angegebene Domain verwendet"
    $nonprimaries | ft -AutoSize Name,DisplayName,UserPrincipalName,RecipientTypeDetails,EmailAddresses
}

$sharedmailboxes = $mailboxes | Where-Object {
    $_.RecipientTypeDetails -ne "UserMailbox"
}

if ($sharedmailboxes) {
    Write-Warning "Folgende freigegebenen Postfächer wurden NICHT exportiert"
    $sharedmailboxes | ft -AutoSize Name,DisplayName,UserPrincipalName,RecipientTypeDetails,EmailAddresses
}


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}