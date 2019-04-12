if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}


$csv = Import-Csv -Path P:\mailbox-settings.csv
$csv | ForEach-Object {
    $_
    $proxyAddress = $_.proxyAddresses.Split('|')
    Set-Mailbox -EmailAddresses $proxyAddresses -Identity $_.UserPrincipalName
    Set-MailboxRegionalConfiguration -Identity $_.UserPrincipalName -DateFormat $_.DateFormat -Language $_.Language -TimeFormat $_.TimeFormat -LocalizeDefaultFolderName -TimeZone $_.TimeZone
} | ft


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}