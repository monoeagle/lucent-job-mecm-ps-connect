# Windows PowerShell 5.1 — Compat-Zweig (Variante 04)

`Wait-ConfigMgrDeployed.ps1` lauffaehig in Windows PowerShell 5.1 — primaer
fuer Tests von einer Windows-Admin-Workstation aus, ohne pwsh-7-Install.

## Was ist anders?

Praktisch nichts. Die pwsh-7-Originale dieser Variante nutzen keine
pwsh-7-only-Features. Die 5.1-Datei

- hat keinen `#!/usr/bin/env pwsh`-Shebang (irrelevant unter Windows, nur
  zur Klarheit weg)
- aktiviert TLS 1.2 explizit (5.1-Default ist Tls10/11 — irrelevant fuer
  WinRM intern, aber gute Hygiene)
- referenziert das Jumphost-Skript via `..\jumphost\Get-ConfigMgrStatus.ps1`

`jumphost\Get-ConfigMgrStatus.ps1` selbst laeuft auf dem **Jumphost** und
ist bereits 5.1-kompatibel — keine separate 5.1-Version noetig.

## Aufruf

```powershell
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -Jumphost cmjump01.corp.local -SiteCode P01
```
