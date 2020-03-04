# Über
Die hier enthaltenen PowerShell-Skripte wurden verwendet bei der Migration von
JEs aus dem Office365-Tenant des BDSU in einen eigenen Office365-Tenant. Dabei
wurden die Benutzer-Accounts und Gruppen der JE aus dem BDSU-Tenant per CSV
exportiert und darüber im neuen Tenant wieder importiert.

## Ablauf

### Migration der Benutzer und Gruppen
Im ersten Schritt werden per CSV-Dateien alle Benutzer und Gruppen der JE
exportiert, indem alle Objekte, die eine E-Mail-Adresse mit der Domain der JE
haben, exportiert werden.

Um die Domain der JE im neuen Tenant einrichten und damit E-Mail-Adressen
erstellen zu können, muss diese in dem Tenant eingerichtet werden. Das geht aber
nicht solange die Domain parallel in einem anderen Office365-Tenant registriert
ist (i.e. im BDSU-Tenant).

Daher muss zuerst die Domain im alten Tenant entfernt werden, indem sie zuerst
von allen Benutzern und Gruppen aus der E-Mail-Adresse und dem Benutzernamen
entfernt wird. Damit die Benutzer und Gruppen nicht gleich gelöscht werden
müssen, wird die Domain bei ihnen durch eine temporäre Domain des alten Tenants
ersetzt. Nachdem die Domain komplett aus dem alten Tenant entfernt wurde, kann
sie im neuen Tenant eingerichtet und verwendet werden.

Im neuen Tenant können dann die Benutzer per CSV-Import erstellt werden. Da
dabei nicht alle Daten übernommen werden - insbesondere E-Mail-Aliase und
Spracheinstellungen der Postfächer, die für den richtigen Import später benötigt
werden - werden diese danach per separatem Skript nachgepflegt.
Ebenfalls werden die exportierten Gruppen und deren Mitglieder per PowerShell im
neuen Tenant erstellt.

### Migration der Postfächer
Um alle alten E-Mails und Termine aus den Postfächern beizubehalten, werden
diese per PST-Export über Outlook Desktop als Datei exportiert und können dann
später per Massenimport im neuen Tenant eingespielt werden. Leider konnten wir
keinen besseren Weg hierfür finden, als jedes Postfach manuell zu exportieren...

Damit man sich aber nicht in jedes Postfach manuell einloggen muss, werden je JE
mehrere dedizierte Benutzer erstellt, die jeweils auf einen Teil aller
Postfächer der JE mit Vollzugriff berechtigt werden. Durch aktiviertes
AutoMapping der Berechtigung werden diese Postfächer bei dem Benutzer dann
automatisch in Outlook eingebunden und können von ihm exportiert werden.

Sobald alle Postfächer als PST-Datei exportiert wurden, können sie per `AzCopy`
in den neuen Tenant hochgeladen und anschließend mit einer CSV für das Mapping
Datei->Postfach per Massenimport in die neuen Postfächer importiert werden.

## Skripte:
Die Nummerierung im Dateinamen gibt die Reihenfolge an, in der die Skripte
während der Migration ausgeführt werden müssen. Der zweite Teil ('BDSU'/'JE')
gibt an, von wem/in welchem Tenant die Skripte ausgeführt werden müssen.

- [utils.ps1](utils.ps1): Enthält einige Hilfsfunktionen, die von den anderen Skripten verwendet werden:
  - `error-exit`: gibt die übergebene Fehlermeldung aus und beendet das Skript
  - `Ensure-AdminCredentials`: fragt interaktiv nach den Zugangsdaten und überprüft sie mit `Connect-AzureAD`; bei Erfolg werden sie in einer globalen Variablen gespeichert, damit sie in der selben Session nicht nochmal eingegeben werden müssen
  - `Ensure-AzureAD`: stellt sicher, dass `Connect-AzureAD` erfolgreich ausgeführt wurde und die AzureAD Cmdlets zur Verfügung stehen
  - `Ensure-ExchangeCommands`: stellt sicher, dass eine Remote PowerShell-Session zum Exchange-Server besteht und die Exchange Cmdlets zur Verfügung stehen
  - `Get-MailboxSizes`: berechnet und listet die Größe aller Postfächer einer Domain auf
- [00_config.ps1](00_config.ps1): enthält die aktuelle Konfiguration für die jeweilige JE
- [00_JE-verify-preparation.ps1](00_JE-verify-preparation.ps1): überprüft das korrekte Format für die CSV mit den privaten E-Mail-Adressen zum Zusenden der Zugangsdaten
- [01_BDSU-set_mailbox_permissions.ps1](01_BDSU-set_mailbox_permissions.ps1): erstellt und berechtigt die Benutzer für den Vollzugriff auf die Postfächer
- [02_BDSU-export_users.ps1](02_BDSU-export_users.ps1): exportiert alle Benutzer der JE und deren Postfacheinstellungen in eine CSV
- [03_BDSU-export_groups.ps1](03_BDSU-export_groups.ps1): exportiert alle Gruppen und deren Mitglieder der JE in eine CSV
- [04_BDSU-rename_users.ps1](04_BDSU-rename_users.ps1): ersetzt die JE-Domain in allen E-Mail-Adressen und Benutzernamen der JE-Benutzer
- [05_BDSU-rename_groups.ps1](05_BDSU-rename_groups.ps1): ersetzt die JE-Domain in allen E-Mail-Adressen und Benutzernamen der JE-Gruppen
- [06_JE-update_mailbox_configurations.ps1](06_JE-update_mailbox_configurations.ps1): importiert E-Mail-Aliase und Postfacheinstellungen aus der CSV im neuen Tenant
- [07_JE-import_groups.ps1](07_JE-import_groups.ps1): erstellt alle Gruppen aus der CSV im neuen Tenant
- [08_JE-import_group_members.ps1](08_JE-import_group_members.ps1): fügt alle Mitglieder und Untergruppen zu den Gruppen/Verteilern hinzu
- [09_BDSU-reset_passwords.ps1](09_BDSU-reset_passwords.ps1): setzt das Passwort aller JE-Benutzer im alten Tenant zurück, damit sie sich dort nicht mehr einloggen
- [10_JE-send_passwords.ps1](10_JE-send_passwords.ps1): kann verwendet werden, um die neuen Zugangsdaten an die privaten E-Mail-Adressen der Benutzer zu senden
- [11_BDSU-create_distribution_contacts.ps1](11_BDSU-create_distribution_contacts.ps1): erstellt die E-Mail-Adressen der JE für die BDSU-Verteiler als Kontakte im BDSU-Tenant, damit sie zu den Verteilern hinzugefügt werden können
- [12_JE-list_psts.ps1](12_JE-list_psts.ps1): vergleicht die gefundenen PST-Dateien mit den laut CSV erwarteten und listet fehlende und unerwartete Dateien auf, um den Fortschritt des Exports anzuzeigen
- [13_JE-upload_psts.ps1](13_JE-upload_psts.ps1): ruft `AzCopy` zum Hochladen der PSTs auf
- [14_JE-create_mapping_csv.ps1](14_JE-create_mapping_csv.ps1): erstellt dis Mapping-CSV für den Import der PSTs in die richtigen Postfächer
- [99_BDSU_delete-migration-accounts.ps1](99_BDSU_delete-migration-accounts.ps1): löscht die Admin-Benutzer der JE für den Export wieder nach abgeschlossener Migration
