if (!$credentials) {
    $credentials = Get-Credential
}

$sessions = Get-PSSession
if ($sessions.ComputerName -notcontains "outlook.office365.com") {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}

$domain = Read-Host -Prompt "Aktuelle Domain"
$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$domain"} | sort DisplayName

do {
    $admin = Read-Host -Prompt "User, der berechtigt werden soll"
    if ($admin) {
        $mailboxes | ForEach-Object {
            Add-MailboxPermission -AccessRights FullAccess -InheritanceType All -AutoMapping $true -Identity $_.UserPrincipalName -User $admin
        }
    }
} while ($admin)


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}