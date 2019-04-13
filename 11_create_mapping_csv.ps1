$srcDir = "P:\PSTs"

$files = Get-ChildItem -Path $srcDir -Filter "*.pst" -name
$domain = Read-Host -Prompt "Domain für Benutzernamen"

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

$csv = $mapping | ConvertTo-Csv -Delimiter "," -NoTypeInformation
$csv = $csv -replace '"',''

$csv | Out-File -Encoding utf8 "$srcDir/mapping.csv"