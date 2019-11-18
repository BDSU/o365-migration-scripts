. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\00_config.ps1"

Ensure-AzureAD
Ensure-ExchangeCommands

$domain = $original_domain

function Create-Account($firstname, $lastname, $display_name, $uid, $mail, $private_mail, $password) {
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.ForceChangePasswordNextLogin = $false
    $PasswordProfile.Password = $password

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

$NUM_OF_ACCOUNTS = 4 
$TIMEOUTS_SECS = 20

$ErrorActionPreference = "Stop" #stop on error

$jeId = $domain -replace ".de","" -replace ".com", ""

<#
[uint16] $bulkSize = Read-Host "Mailboxes per export account (default: 25)"
if ($bulkSize -eq 0) { $bulkSize = 25 }
#>

# data for migration accounts
$firstname = "Migration"
$lastname = "Account"
$displayName = "Migrationsaccount | " + $jeId
$adminMail = $credentials.UserName

$uidPrefix = "migration." + $jeId
$migrationAccounts = @()

$password = Read-Host "Password for all migration accounts"


for($i = 0; $i -lt $NUM_OF_ACCOUNTS; $i++) { # [math]::Ceiling($userNum / $bulkSize)
    $uid = $uidPrefix + ($i + 1)
    $mail = $uid + "@bdsu-connect.de"
    $success = Create-Account $firstname $lastname $displayName $uid $mail $adminMail $password
    if ($success) {
        $migrationAccounts += @{"username" = $mail; "password" = $password}
    } else {
        Write-Host ("Unable to create user: " + $mail) -ForegroundColor Red
    }
}

# time consuming  -> AD and Exchange can sync
$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {$_.EmailAddresses -like "*@$domain"} | sort DisplayName

#loop: waiting for exchange sync
$migrationAccsAvailable =  $false
while (!$migrationAccsAvailable) {
        $migrationAccsAvailable = [bool] (Get-Mailbox -Identity $migrationAccounts[$NUM_OF_ACCOUNTS - 1].username -ErrorAction SilentlyContinue)

        if (!$migrationAccsAvailable) {
                Write-Host "Admin users not available yet, retrying in $TIMEOUTS_SECS seconds"
                Start-Sleep -Seconds $TIMEOUTS_SECS
        }
}


# hide admin accounts from address list
$migrationAccounts | ForEach-Object {
    Set-Mailbox -Identity $_.username -HiddenFromAddressListsEnabled $true
}

$bulkSize = [math]::Floor($mailboxes.Length / $NUM_OF_ACCOUNTS)

$i = 0
$admincount = 0
$admin = $migrationAccounts[0]
$mailboxes | ForEach-Object {
    if ($i % $bulkSize -eq 0 -and $i -lt ($bulkSize * $NUM_OF_ACCOUNTS)) {
        $admin = $migrationAccounts[$admincount]
        $admincount++
    }
    if ($admin) {
        Add-MailboxPermission -AccessRights FullAccess -InheritanceType All -AutoMapping $true -Identity $_.UserPrincipalName -User $admin.username
    }
    $i++
}

$migrationAccounts | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize


