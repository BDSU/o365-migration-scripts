. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-ExchangeCommands

$city = $je_city_name
$domain = $original_domain


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