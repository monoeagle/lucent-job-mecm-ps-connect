# 03 — WinRM-Jumphost mit ConfigurationManager-Modul

Wenn AdminService nicht aktiviert ist oder das CM-Modul mit den vollen Cmdlets
benötigt wird (z.B. `Get-CMDeviceCollectionMembership`-Logik), nutzt der
Linux-Runner pwsh-Remoting, um auf einem Windows-Jumphost ein Skript
auszuführen, das die CM-Console-DLLs lädt.

## Voraussetzungen

- pwsh 7 auf dem Linux-Runner
- Windows-Jumphost mit installierter MECM-Admin-Console
- WinRM HTTPS auf Jumphost konfiguriert, Port 5986 erreichbar
- Service-Account mit Read-Rechten in MECM, vorab via Kerberos angemeldet
  (Linux: `kinit -kt …`)

## Dateien

- `Wait-MecmDeployed.ps1` — läuft auf dem Runner, baut die WinRM-Session auf
- `jumphost/Get-MecmStatus.ps1` — wird auf den Jumphost übertragen und ausgeführt
- `main.tf`

## Aufruf manuell

```bash
pwsh ./Wait-MecmDeployed.ps1 -ComputerName PC123 -Jumphost cmjump01.corp.local -SiteCode P01
```
