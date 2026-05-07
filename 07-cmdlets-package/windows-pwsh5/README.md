# Windows PowerShell 5.1 — Compat-Zweig (Variante 05)

`Wait-ConfigMgrDeployed.ps1` lauffaehig in Windows PowerShell 5.1 — primaer
fuer Tests von einer Windows-Admin-Workstation aus, ohne pwsh-7-Install.

## Was ist anders?

Praktisch nichts — pwsh-7-Original nutzt keine pwsh-7-only-Features. Die
5.1-Datei hat:

- keinen Shebang
- explizites TLS 1.2 (Hygiene)
- Pfad zum Remote-Skript via `..\windows\Get-ConfigMgrStatus.ps1`

Die Windows-Host-Skripte in `..\windows\` (`Get-ConfigMgrStatus.ps1`,
`Setup-CmdletPackage.ps1`) laufen ohnehin auf 5.1 und brauchen keine
separate Compat-Version.

## Aufruf

```powershell
.\Wait-ConfigMgrDeployed.ps1 `
    -ComputerName PC123 `
    -WindowsHost cmworker01.corp.local `
    -SiteCode P01 `
    -SiteServer sccm.corp.local
```
