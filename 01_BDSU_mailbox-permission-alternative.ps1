function Generate-Password {
	$caps = [char[]] "ABCDEFGHJKMNPQRSTUVWXY";
	$lows = [char[]] "abcdefghjkmnpqrstuvwxy";
	$nums = [char[]] "012346789";
	$spl  = [char[]] "/&?$%";

	$first  = $nums | Get-Random -count 4;
	$second = $caps | Get-Random -count 3;
	$third  = $lows | Get-Random -count 4;
	$fourth = $spl  | Get-Random -count 2;

	$pwd = (@($first) + @($second) + @($third) + @($fourth) | Get-Random -Count 12) -join "";
	return $pwd;
}

function Get-CurrentLine {
    return $MyInvocation.ScriptLineNumber
}

<######
 # Generiert eine UID im Muster "$firstname.$lastname" in Kleinbuchstaben,
 # wobei alle Sonderzeichen gemäß $map ersetzt werden.
 #>
function Generate-UID ($firstname, $lastname) {
	$map = @{
		"ä" = "ae";
		"š" = "s";
		"í" = "i";
		"ö" = "oe";
		"ü" = "ue";
		"ß" = "ss";
		"é" = "e";
		"è" = "e";
		"ó" = "o";
		"ø" = "o";
		"ò" = "o";
		"á" = "a";
        "à" = "a";
        "Č" = "c";
        "'" = "-";
        "c" = "c";
        "ć" = "c";
        "ý" = "y";
		"Ž" = "z";
		"ń" = "n";
		"ś" = "s";
		"ı" = "i";
		"ô" = "o";
        "đ" = "d";
        "ą" = "a";
        "Ř" = "r";
        "ł" = "l";
        "ź" = "z";
        "ż" = "z";
        "ï" = "i";
        "ë" = "e";
	};
    $line = $(Get-CurrentLine) - 2

	$uid = "$firstname.$lastname" -replace " ","-";
	$uid = $uid.ToLower();
	foreach ($search in $map.Keys) {
		$uid = $uid -replace $search, $map[$search];
	}

    $regex = "[^a-z0-9.-]"
    if ($uid -match $regex) {
        Write-Warning "Die generierte UID enthält ungültige Zeichen!"
        Write-Warning "Bitt füge folgende Zeile im Skript in Zeile $line hinzu, um das/die ungültigen Zeichen durch ein gültiges zu ersetzen (`"?`")"
        Select-String $regex -Input $uid -AllMatches | ForEach-Object {$_.matches} | sort -Unique | ForEach-Object {
            Write-Host "`t`t`"$_`" = `"?`";"
        }
        Write-Host
        return ""
    }

	return $uid;
}

function Create-Account($firstname, $lastname, $display_name, $uid, $mail, $private_mail) {
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.ForceChangePasswordNextLogin = $true
    $PasswordProfile.Password = Generate-Password

    $user = New-AzureADUser -AccountEnabled $true -UserPrincipalName $mail -DisplayName $display_name -GivenName $firstname -Surname $lastname -UsageLocation DE -OtherMails $private_mail -PasswordProfile $PasswordProfile -MailNickName $uid
    if (!$? -or !$user) {
        Write-Warning "failed to create user"
        return $false
    }

    $skuId = Get-AzureADSubscribedSku | Where-Object {$_.SkuPartNumber -eq "STANDARDWOFFPACK_STUDENT"} | Select-Object -ExpandProperty skuId
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $license.SkuId = $skuId
    $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $licenses.AddLicenses = $license
    Set-AzureADUserLicense -ObjectId $user.ObjectId -AssignedLicenses $licenses
    if (!$?) {
        Write-Warning "failed to assign license"
    }

    return $true
}

################################### 

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

$domain = Read-Host -Prompt "Aktuelle Domain"

if ($domain -gt 0) {

    $jeId = $domain -replace ".de","" -replace ".com", ""

    [uint16] $bulkSize = Read-Host "Mailboxes per export account (default: 25)"
    if ($bulkSize -eq 0) { $bulkSize = 25 }

    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$domain"} | sort DisplayName

    # data for migration accounts
    $firstname = "Migration"
    $lastname = "Account"
    $displayName = "Migrationsaccount"
    $adminMail = $credentials.UserName
    
    $uidPrefix = Generate-UID "migration" $jeId
    $migrationAccounts = @()


    for($i = 0; $i -lt [math]::Ceiling($userNum / $bulkSize); $i++) {
        $uid = $uidPrefix + $i
        $mail = $uid + "@bdsu-connect.de"
        $success = Create-Account $firstname $lastname $display_name $uid $mail $private_mail
        if ($success) {
            $user = Get-AzureADUser -ObjectId $mail
            $password = Generate-Password
            Set-AzureADUserPassword -ObjectId $user.ObjectId -Password (ConvertTo-SecureString -AsPlainText -Force $password) -ForceChangePasswordNextLogin $false

            $migrationAccounts += @{"username" = $mail; "password" = $password}
        } else {
            Write-Host ("Unable to create user: " + $mail) -ForegroundColor Red
        }
    }

    $testarray = @()
    $i = 0
    $admincount = 0
    $mailboxes | ForEach-Object {
        if ($i % $bulkSize -eq 0) {
            $admin = $migrationAccounts[$admincount]
            $admincount++
        }
        if ($admin) {
            Add-MailboxPermission -AccessRights FullAccess -InheritanceType All -AutoMapping $true -Identity $_.UserPrincipalName -User $admin
        }
        $i++
    }

    $migrationAccounts | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize

    

} else {
    Write-Host "No domain provided. Please restart." -ForegroundColor Red
} 

