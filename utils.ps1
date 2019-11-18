function error-exit($msg) {
    Write-Warning $msg

    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "Press any key to exit..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }

    exit $false
}

function Ensure-AdminCredentials() {
    if ($Global:bdsu_admin_credentials) {
        return
    }

    while(!$Global:bdsu_admin_credentials) {
        $credentials = Get-Credential

        if (!$? -or !$credentials -or !$credentials.UserName) {
            error-exit "Keine Zugangsdaten angegeben, abbrechen..."
        }

        Connect-AzureAD -Credential $credentials
        if (!$?) {
            Write-Warning "Verbindung zu Azure AD mit eingegebenen Zugangsdaten fehlgeschlagen."
            continue
        }

        $Global:bdsu_admin_credentials = $credentials
    }
}

function Ensure-AzureAD() {
    Ensure-AdminCredentials
    Connect-AzureAD -Credential $Global:bdsu_admin_credentials
}

function Ensure-ExchangeCommands() {
    $sessions = Get-PSSession
    if ($sessions.ComputerName -contains "outlook.office365.com") {
        return
    }

    Ensure-AdminCredentials

    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Global:bdsu_admin_credentials -Authentication Basic -AllowRedirection
    if (!$? -or !$session) {
        error-exit "Konnte Exchange-Session nicht erstellen"
    }

    Import-PSSession $session
    if (!$?) {
        error-exit "Konnte Exchange-Session nicht importieren"
    }
}