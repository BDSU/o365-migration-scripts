. "$PSScriptRoot\utils.ps1"

$drive = Get-PSDrive P
if (!$? -or !$drive -or $drive.DisplayRoot -like "\\data\data") {
    error-exit "Für bessere Performance sollte dieses Skript auf der anderen VM (3392) ausgeführt werden"
}

$srcDir = "P:\PSTs"
$logfile = "P:\azure_copy.log"
$sasUrl = Read-Host -Prompt "SAS-URL"
& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Y /source:$srcDir /V:$logfile /Dest:"$sasUrl" /Pattern:'*.pst'


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
