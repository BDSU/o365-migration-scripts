$srcDir = "P:\PSTs"
$logfile = "P:\azure_copy.log"
$sasUrl = Read-Host -Prompt "SAS-URL"
& 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Y /source:$srcDir /V:$logfile /Dest:"$sasUrl"


if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to exit..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}