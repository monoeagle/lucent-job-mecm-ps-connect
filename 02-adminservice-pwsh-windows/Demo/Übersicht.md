# Demo-Skripte — AdminService (Windows / PS 5.1)

Alle Skripte sind **Windows PowerShell 5.1-kompatibel** und laufen auch unter
pwsh 7 auf Windows. Authentifizierung erfolgt via Windows Integrated
Authentication (SSPI) — kein Kerberos-Setup erforderlich.

## Voraussetzung

```powershell
$env:CONFIGMGR_ADMINSERVICE_BASE = 'https://sccm.corp.local/AdminService'
# Nur in Test-Umgebungen ohne CA-Trust:
# $env:CONFIGMGR_SKIP_CERT_CHECK = 'true'
```

## Skripte

| Skript | Was es zeigt |
|---|---|
| `010-list-devices.ps1` | `$filter`, `$select`, `$orderby`, `$top`, Pagination via `@odata.nextLink` |
| `020-device-full.ps1` | Mehrere WMI-Klassen pro Device: System, OS, BIOS, CPU, Disks |
| `030-device-software.ps1` | Installierte Software via `SMS_G_System_ADD_REMOVE_PROGRAMS` |
| `040-device-collections.ps1` | Collection-Mitgliedschaften eines Devices |
| `050-collection-members.ps1` | Alle Members einer Collection (per Name oder ID) |
| `060-deployments.ps1` | Laufende / geplante Deployments — Filter Active/Future/All |
| `070-task-sequence-status.ps1` | TS-Deployment-Status global oder je Device |
| `080-client-health.ps1` | `v_CH_ClientSummary`-Aequivalent via AdminService |
| `090-discover-classes.ps1` | Alle abfragbaren EntitySets aus `$metadata` |
| `100-modeled-api.ps1` | `/v1.0/`-API: Applications, Packages, Collections (typisiertes Modell) |

## PS 5.1-Besonderheiten gegenüber pwsh 7

| Feature | pwsh 7 | 5.1-Workaround hier |
|---|---|---|
| TLS 1.2 Default | ja | `[Net.ServicePointManager]::SecurityProtocol = Tls12` |
| `-SkipCertificateCheck` | nativ | `ServerCertificateValidationCallback = { $true }` |
| Null-Conditional `?.` | ja | explizites `if ($x) { ... }` |
| Null-Coalescing `??` | ja | `if ($map.ContainsKey($k)) { $map[$k] } else { $default }` |
