$srcDir = "P:\PSTs"

while ($true) {
    $csv = Import-Csv -Path P:\import-users.csv
    $psts = $csv.'User Name' | ForEach-Object {
        $_ -replace "@.*$",".pst"
    }
    $files = Get-ChildItem -Path $srcDir

    $diff = Compare-Object -ReferenceObject $psts -DifferenceObject $files.Name

    $extras = $diff | Where-Object {$_.SideIndicator -eq "=>"}
    $missing = $diff | Where-Object {$_.SideIndicator -eq "<="}

    if ($missing) {
        Write-Host "Diese Dateien fehlen noch"
        $missing | ft -AutoSize InputObject
        Write-Host "Insgesamt noch $($missing.Count) Datei(en)"
    } else {
        Write-Host -ForegroundColor Green "Alle Postfächer exportiert"
    }

    if ($extras) {
        Write-Warning "Diese Dateien gehören zu keinem bekannten Postfach"
        $extras | ft -AutoSize InputObject
    }

    Read-Host -Prompt "Enter drücken, um zu aktualisieren"
}