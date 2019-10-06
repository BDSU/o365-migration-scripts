$srcDir = "P:\PSTs"

$files = Get-ChildItem -Path $srcDir -Filter "*.pst" -name
$domain = Read-Host -Prompt "Domain für Benutzernamen"

$csv = Import-Csv -Path P:\import-users.csv
$psts = $csv.'User Name' | ForEach-Object {
    $_ -replace "@.*$",".pst"
}

$mapping = $files | ForEach-Object {
    $uid = $_ -replace ".pst$",""
    $userPrincipalName = "$uid@$domain"
    [psCustomObject]@{
        Workload = "Exchange"
        FilePath = ""
        Name = $_
        Mailbox = "$userPrincipalName"
        IsArchive = "FALSE"
        TargetRootFolder = "/"
        ContentCodePage = ""
        SPFileContainer = ""
        SPManifestContainer = ""
        SPSiteUrl = ""
    }
}

$mapping | ft

$diff = Compare-Object -ReferenceObject $psts -DifferenceObject $files

$extras = $diff | Where-Object {$_.SideIndicator -eq "=>"}
$missing = $diff | Where-Object {$_.SideIndicator -eq "<="}

if ($missing) {
    Write-Warning "Diese Dateien fehlen noch ($($missing.Count) Datei/en)"
    $missing | ft -AutoSize InputObject
} else {
    Write-Host -ForegroundColor Green "Alle Postfächer exportiert"
}

if ($extras) {
    Write-Warning "Diese Dateien gehören zu keinem bekannten Postfach"
    $extras | ft -AutoSize InputObject
}

$csv = $mapping | ConvertTo-Csv -Delimiter "," -NoTypeInformation
$csv = $csv -replace '"',''

$csv | Out-File -Encoding utf8 "$srcDir/mapping.csv"

if ($missing -or $extras) {
    Write-Warning "Bitte überprüfe obenstehende Warnungen und verwende die mappings.csv nur, wenn diese geklärt sind; du kannst die mappings.csv ggf. manuell korrigieren."
}