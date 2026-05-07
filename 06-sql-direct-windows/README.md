# 06 — SQL direkt (Windows / PS 5.1)

Windows-Workstation oder Windows-Runner fragt die ConfigMgr-SQL-Datenbank
direkt via `Invoke-Sqlcmd` ab. **Windows PowerShell 5.1 ist die primäre
Zielversion.** Authentifizierung via Windows Integrated Authentication (SSPI)
— kein Kerberos-Setup erforderlich.

## Unterschied zu 05-sql-direct-linux

| Aspekt | 05 (Linux) | 06 (Windows) |
|---|---|---|
| Tool | `sqlcmd` (mssql-tools, bash) | **`Invoke-Sqlcmd`** (PS 5.1/7) |
| Auth | Kerberos (kinit/keytab) | **SSPI (Windows Auth)** — automatisch |
| SQL-Auth fallback | `-U`/`-P` Flags | `-Username`/`-Password` Parameter |
| Shell | bash | **Windows PowerShell 5.1** |

Die SQL-Queries gegen die CM-DB sind in beiden Varianten **identisch**.

## Voraussetzungen

- Domain-joined Windows-Maschine mit Lesezugriff auf `CM_<SiteCode>`
- `Invoke-Sqlcmd` verfügbar — enthalten in:
  - SSMS (SQL Server Management Studio)
  - PowerShell-Modul `SqlServer` (`Install-Module SqlServer`)
  - RSAT (Remote Server Administration Tools)
- Netzwerkzugriff auf SQL-Port 1433 — oft restriktiver als AdminService 443
- DB-User mit `db_datareader` auf `CM_<SiteCode>` (Windows-Auth-Account genügt)

## Dateien

- `Wait-ConfigMgrDeployed.ps1` — Polling-Script, blockiert bis "deployed" oder Timeout
- `main.tf` — Tofu-Beispiel (Windows-Runner)
- `Demo/` — 10 Demo-Skripte für SQL-Exploration

## Aufruf manuell

```powershell
# Windows-Auth (SSPI) — kein Passwort nötig
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SqlHost sql.corp.local -DbName CM_P01

# SQL-Auth (optional)
.\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -SqlHost sql.corp.local -DbName CM_P01 `
    -SqlUser svc-readonly -SqlPassword 'secret'
```

Exit-Code 0 = deployed, 1 = Timeout.

## Demo-Skripte

```powershell
$env:CONFIGMGR_SQL_HOST = 'sql.corp.local'
$env:CONFIGMGR_DB_NAME  = 'CM_P01'

.\Demo\010-list-devices.ps1 -Top 25
.\Demo\020-device-full.ps1  -ComputerName PC123
.\Demo\100-complex-aggregation.ps1   # Multi-View-JOIN — nicht trivial via AdminService
```

Vollständige Liste: [`Demo/Übersicht.md`](Demo/Übersicht.md).

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source                = "../../06-sql-direct-windows"
  computer_name         = "PC123"
  sql_host              = "sql.corp.local"
  db_name               = "CM_P01"
  timeout_seconds       = 7200   # optional, Default 3600
  poll_interval_seconds = 60     # optional, Default 30
  # sql_user/sql_password optional fuer SQL-Auth statt Windows-Auth
}
```

## Genutzte Views (offiziell dokumentiert)

- `v_R_System` — Resource-Stammdaten, `Client0`-Spalte
- `v_TaskExecutionStatus` — TS-Run-Historie pro Resource
- `v_CH_ClientSummary` — Client-Health (optional ergänzend)
- `v_FullCollectionMembership`, `v_Collection`, `v_GS_*` — in Demo-Skripten

## Hinweis: DBA-Approval

SQL-Direktzugriff auf `CM_<SiteCode>` erfordert in den meisten Umgebungen
explizite DBA-Freigabe. Nur lesend (`db_datareader`) — niemals schreibend.
View-Schema kann bei ConfigMgr-Major-Upgrades ändern.
