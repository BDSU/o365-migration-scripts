$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

$city = Read-Host -Prompt "Stadt"
$domain = Read-Host -Prompt "JE-Domain"

$groups = @{
    "$city - MIT"                = "bdsu.mit@$domain"
    "$city - Finanzvorstand"     = "bdsu.fr@$domain"
    "$city - IT-Ansprechpartner" = "bdsu.it@$domain"
    "$city - QM-Ansprechpartner" = "bdsu.qm@$domain"
    "$city - Vorstände"          = "bdsu.vorstaende@$domain"
}

$groups.Keys | ForEach-Object {
    New-MailContact -DisplayName $_ -Name $_ -ExternalEmailAddress $groups[$_]
}


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}