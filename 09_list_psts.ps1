$srcDir = "P:\PSTs"

while ($true) {
    $csv = Import-Csv -Path P:\import-mailboxes.csv
    $psts = $csv | ForEach-Object {
        $_.Mailbox -replace "@.*$",".pst"
    }
    $files = Get-ChildItem -Path $srcDir

    $diff = Compare-Object -ReferenceObject $psts -DifferenceObject $files.Name

    $missing = $diff | Where-Object {$_.SideIndicator -eq "=>"}
    $extras = $diff | Where-Object {$_.SideIndicator -eq "<="}

    if ($missing) {
        Write-Host "Diese Dateien fehlen noch"
        $missing | ft -AutoSize InputObject
    } else {
        Write-Host -ForegroundColor Green "Alle Postfächer exportiert"
    }

    if ($extras) {
        Write-Warning "Diese Dateien gehören zu keinem bekannten Postfach"
        $extras | ft -AutoSize InputObject
    }

    Read-Host -Prompt "Enter drücken, um zu aktualisieren"
}