if (!$credentials) {
    $credentials = Get-Credential
}

Connect-AzureAD -Credential $credentials

$domain = Read-Host -Prompt "Aktuelle Domain"

Write-Host "Setze Passwörter zurück"

$users = Get-AzureADUser -All $true | Where-Object {$_.UserPrincipalName -like "*@$domain"}

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

$users | ForEach-Object{
    $_
    $password = Generate-Password
    Set-AzureADUserPassword -ObjectId $_.ObjectId -Password (ConvertTo-SecureString -AsPlainText -Force $password)
} | ft