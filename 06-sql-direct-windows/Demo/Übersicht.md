# Demo-Skripte — SQL direkt (Windows / PS 5.1)

Alle Skripte sind **Windows PowerShell 5.1-kompatibel** und laufen auch unter
pwsh 7 auf Windows. Authentifizierung erfolgt per Windows Integrated
Authentication (SSPI) — kein Kerberos-Setup erforderlich. Optional SQL-Auth
via Umgebungsvariablen.

## Voraussetzung

```powershell
$env:CONFIGMGR_SQL_HOST = 'sql.corp.local'
$env:CONFIGMGR_DB_NAME  = 'CM_P01'

# Optional — SQL-Auth statt Windows-Auth:
# $env:SQL_USER = 'svc-readonly'
# $env:SQL_PASS = 'secret'
```

`Invoke-Sqlcmd` muss verfügbar sein — kommt mit SSMS, RSAT oder dem
[`SqlServer`-PowerShell-Modul](https://www.powershellgallery.com/packages/SqlServer)
(`Install-Module SqlServer`).

## Skripte

| Skript | Was es zeigt |
|---|---|
| `010-list-devices.ps1` | `v_R_System` mit Filter, Top, Sortierung |
| `020-device-full.ps1` | Stammdaten + HW-Inventory aus mehreren `v_GS_*`-Views |
| `030-device-software.ps1` | Installierte Software via `v_GS_INSTALLED_SOFTWARE` |
| `040-device-collections.ps1` | Collections eines Device via `v_FullCollectionMembership` |
| `050-collection-members.ps1` | Members einer Collection per Name oder ID |
| `060-deployments.ps1` | `v_DeploymentSummary` — Active/Future/All |
| `070-task-sequence-status.ps1` | `v_TaskExecutionStatus` — TS-Deployment-Historie |
| `080-client-health.ps1` | `v_CH_ClientSummary` — Health-Status |
| `090-discover-views.ps1` | Alle `v_*`-Views aus `INFORMATION_SCHEMA.VIEWS` |
| `100-complex-aggregation.ps1` | Multi-View-JOIN mit GROUP BY — nicht trivial via AdminService |
