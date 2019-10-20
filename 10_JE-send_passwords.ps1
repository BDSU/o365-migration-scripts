function Send-WelcomeMail($firstname, $lastname, $private_mail, $mail, $password) {
    $sender = "JE IT <it@je-domain.de>"
    $subject = "Zugangsdaten für deinen neuen Account"
    $body = @"
        Hallo $firstname,<br />
        <br />
        wir haben dir soeben deinen brandneuen Account für <strong>$mail</strong> erstellt!<br />
        Zugriff auf dein neues Postfach bekommst du <a href="https://outlook.office.com/">online unter [1]</a> mit diesen Zugangsdaten:
        <ul>
	        <li>Benutzername: <strong>$mail</strong></li>
	        <li>Passwort: <strong>$password</strong></li>
        </ul>
        Bei Problemen mit deinem neuen Account kannst du dich an die IT wenden.<br />
        <br />
        [1]&nbsp;<a href="https://outlook.office.com/">https://outlook.office.com/</a><br />
        <br />
        Beste Grüße<br />
        Deine IT
"@

    Send-MailMessage `
        -From $sender `
        -To $private_mail `
        -Cc $mail `
        -Subject $subject `
        -Body $body `
        -BodyAsHtml `
        -Encoding UTF8 `
        -SmtpServer "smtp.office365.com" `
        -Port 587 `
        -UseSsl `
        -Credential $sender_credentials

    return $?
}

$sender_credentials = Get-Credential

$csv = Import-Csv -Path P:\passwords.csv | sort Anzeigename
$private_mails = @{}
Import-Csv -Path P:\private-mails.csv | ForEach-Object {
    $private_mails[$_.Username] = $_.email
}

$users = @{}
Import-Csv -Path P:\import-users.csv | ForEach-Object {
    $users[$_.'User Name'] = @{
        GivenName = $_.'First Name';
        Surname = $_.'Last Name';
        UserPrincipalName = $_.'User Name'
    }
}

Write-Host "Sende Passwort-Mails"
$csv | Where-Object {
    $private_mails[$_.Benutzername] -and $users[$_.Benutzername]
} | ForEach-Object {
    $private_mail = $private_mails[$_.Benutzername]
    
    [psCustomObject]@{
        Anzeigename = $_.Anzeigename
        Benutzername = $_.Benutzername
        "private E-Mail" = $private_mail
    }

    $user = $users[$_.Benutzername]
    Send-WelcomeMail $user.GivenName $user.Surname $private_mail $user.UserPrincipalName $_.Kennwort
} | ft
