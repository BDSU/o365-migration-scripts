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

$i = 0
$mailboxes | ForEach-Object {
    if ($i % 20 -eq 0) {
        $admin = Read-Host -Prompt "User, der berechtigt werden soll für User $($i + 1) - $($i + 21)"
    }
    if ($admin) {
        Add-MailboxPermission -AccessRights FullAccess -InheritanceType All -AutoMapping $true -Identity $_.UserPrincipalName -User $admin
    }
    $i++
}


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}