$ErrorActionPreference = "Stop" #stop on error
if (!$credentials) {
    $credentials = Get-Credential
}

Connect-AzureAD -Credential $credentials

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

$domain = Read-Host -Prompt "JE-Domain"

if ($domain -gt 0) {

    $jeId = $domain -replace ".de","" -replace ".com", ""

    for ($i = 0; $i -lt 4; $i++) {
        Remove-AzureADUser -ObjectId ("migration." + $jeId + $i + "@bdsu-connect.de")
    }

} else {
    Write-Host "No domain provided. Please restart." -ForegroundColor Red
} 

