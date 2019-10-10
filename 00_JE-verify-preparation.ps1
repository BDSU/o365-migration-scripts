$csv = Import-Csv -Path P:\private-mails.csv 

if ($csv[0].psobject.properties.name.Length -eq 2 -and $csv[0].psobject.properties.name[0].Trim() -eq "Username" -and $csv[0].psobject.properties.name[1].Trim() -eq "Email") {

    Write-Host "CSV structure OK" -ForegroundColor DarkGreen

    $incorrect = @()
    $usernameLike = Read-Host "Username domain (any if empty)"
    if ($usernameLike.Length -gt 0) {
        $usernameLike = "*@" + $usernameLike
    } else {
        $usernameLike = "*@*.*"
    }

    $csv | ForEach-Object {
        if(-not ($_.Username.Trim() -like $usernameLike -and $_.Email.Trim() -like "*@*.*")) {
            $incorrect += $_
        }
    }

    if ($incorrect.Length -gt 0) {
        Write-Host "Some records are incorrect" -ForegroundColor Red
        $incorrect | ft
    } else {
        Write-Host "All records OK" -ForegroundColor DarkGreen
    }

} else {
    Write-Host "Unexpected CSV structure, expected: Username, Email" -ForegroundColor Red
}