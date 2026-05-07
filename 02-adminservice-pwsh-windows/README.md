# 02 — AdminService via PowerShell (Windows)

Windows-Workstation oder Windows-Runner ruft die AdminService REST API von
ConfigMgr direkt mit `Invoke-RestMethod` auf. **Windows PowerShell 5.1 ist
die primäre Zielversion** — kein separater Install nötig. PowerShell 7 auf
Windows funktioniert identisch (kein Kerberos-Setup erforderlich, da Windows
Integrated Authentication via SSPI automatisch greift).

## Unterschied zu 01-adminservice-pwsh-linux

| Aspekt | 01 (Linux) | 02 (Windows) |
|---|---|---|
| Shell | `pwsh` (PS 7) | **Windows PowerShell 5.1** (oder pwsh 7) |
| Auth | Kerberos — `kinit -kt keytab` vor dem Run | **SSPI** — greift automatisch mit dem angemeldeten Windows-User |
| TLS 1.2 | Default in pwsh 7 | Explizit via `[Net.ServicePointManager]::SecurityProtocol` |
| Cert-Skip | `-SkipCertificateCheck` Parameter | `[Net.ServicePointManager]::ServerCertificateValidationCallback` |
| Kerberos-Setup | Keytab + krb5.conf nötig | **nicht nötig** |

## Voraussetzungen

- Domain-joined Windows-Maschine (oder Service-Account mit ConfigMgr-RBAC)
- AdminService Endpoint erreichbar: `https://<smsprovider>/AdminService/`
- ConfigMgr CB 1810 oder neuer
- CA-Zertifikat des SMS-Providers im Windows-Zertifikatsstore (sonst
  `-SkipCertificateCheck` setzen — nur für Test-Umgebungen)

## Dateien

- `Wait-ConfigMgrDeployed.ps1` — Polling-Script, blockiert bis "deployed" oder Timeout
- `main.tf` — Tofu-Beispiel (Windows-Runner)
- `Demo/` — 10 Demo-Skripte für AdminService-Exploration

## Aufruf manuell

```powershell
# PS 5.1 oder pwsh 7 — beide funktionieren
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SmsProvider sccm.corp.local -SiteCode P01

# Nur für Test-Umgebungen ohne CA-Trust:
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SmsProvider sccm.corp.local -SiteCode P01 -SkipCertificateCheck
```

Exit-Code 0 = deployed, 1 = Timeout, 2 = Fehler.

## Demo-Skripte

Im Unterordner [`Demo/`](Demo/) liegen 10 Skripte, die zeigen was sich noch
alles ueber den AdminService abfragen laesst. Alle PS-5.1-kompatibel.

```powershell
$env:CONFIGMGR_ADMINSERVICE_BASE = 'https://sccm.corp.local/AdminService'
# optional nur in Test-Umgebungen:
# $env:CONFIGMGR_SKIP_CERT_CHECK = 'true'

.\Demo\010-list-devices.ps1 -Top 25
.\Demo\020-device-full.ps1  -ComputerName PC123
```

## Als Tofu-Modul verwenden

Dieser Ordner ist ein vollständiges Tofu-Modul (`variables.tf`, `main.tf`,
`outputs.tf`). Voraussetzung: Tofu läuft auf einem Windows-Runner.

```hcl
module "wait_for_pc" {
  source                = "../../02-adminservice-pwsh-windows"
  computer_name         = "PC123"
  sms_provider          = "sccm.corp.local"
  site_code             = "P01"
  timeout_seconds       = 7200    # optional, Default 3600
  poll_interval_seconds = 60      # optional, Default 30
}
```

## PowerShell 7 auf Windows

Wenn pwsh 7 auf der Windows-Maschine installiert ist, funktionieren auch die
Skripte aus `01-adminservice-pwsh-linux` ohne Anpassung — mit einer Ausnahme:
kein `kinit` nötig, stattdessen `UseDefaultCredentials = $true` reicht, weil
SSPI auf Windows automatisch das Kerberos-Ticket des angemeldeten Users nutzt.
Die Skripte hier sind bewusst auf PS 5.1 ausgelegt.
