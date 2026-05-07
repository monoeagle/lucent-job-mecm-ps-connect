# Windows PowerShell 5.1 — Compat-Zweig

Parallele Skripte zur pwsh-7-Variante im Parent-Folder, lauffaehig in
**Windows PowerShell 5.1** (das auf jedem aktuellen Windows-System ohne
Zusatzinstallation vorhanden ist).

## Wann den 5.1-Zweig nutzen?

- Auf einem Windows-Admin-Workstation, auf dem kein PowerShell 7 installiert
  ist und nicht installiert werden soll
- Fuer schnelle Tests/Exploration der AdminService-API ohne pwsh-Setup
- Wenn euer Standard-Image nur 5.1 mitbringt und Software-Verteilung von
  pwsh 7 noch nicht durch ist

**Production-Hinweis:** Der eigentliche Tofu-Use-Case (Linux-Runner)
braucht weiterhin pwsh 7 — 5.1 laeuft nicht auf Linux. Dieser Zweig ist
fuer Windows-seitige Nutzung gedacht.

## Was ist anders gegenueber dem pwsh-7-Original?

| Feature | pwsh 7 | 5.1-Workaround |
|---|---|---|
| TLS 1.2 default | ja | `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` |
| `-SkipCertificateCheck` | nativ | `[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }` |
| Null-Conditional `?.` | nativ | explizites `if ($x) { $x.Y } else { $null }` |
| Null-Coalescing `??` | nativ | explizites `if ($map.ContainsKey($k)) { $map[$k] } else { $default }` |

Funktional **identisch** zur Pwsh-7-Variante.

## Geaenderte Skripte

| Skript | Aenderung |
|---|---|
| `Wait-ConfigMgrDeployed.ps1` | Skip-Cert-Callback, `?.`-Removal, TLS-1.2 |
| `Demo/_common.ps1` | Skip-Cert-Callback, TLS-1.2 |
| `Demo/060-deployments.ps1` | `??`-Removal |
| `Demo/070-task-sequence-status.ps1` | `??`-Removal |
| `Demo/090-discover-classes.ps1` | Skip-Cert-Callback, TLS-1.2 |

Die uebrigen Demos (`010`, `020`, `030`, `040`, `050`, `080`, `100`) sind
1:1-Kopien — sie nutzen keine pwsh-7-spezifischen Features. Liegen hier
nur, damit das Sourcing auf das lokale `_common.ps1` zeigt.

## Aufruf

```powershell
# Wait-Skript
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SmsProvider sccm.corp.local -SiteCode P01

# Demo
$env:CONFIGMGR_ADMINSERVICE_BASE = 'https://sccm.corp.local/AdminService'
.\Demo\010-list-devices.ps1 -Top 25
```

## Pflege-Hinweis

Wenn du am pwsh-7-Original Aenderungen machst, denke an die 5.1-Mirror-Datei.
Die Demos `010`, `020`, `030`, `040`, `050`, `080`, `100` koennen einfach
neu kopiert werden:

```powershell
Copy-Item ..\Demo\010-list-devices.ps1 .\Demo\010-list-devices.ps1 -Force
# usw.
```
