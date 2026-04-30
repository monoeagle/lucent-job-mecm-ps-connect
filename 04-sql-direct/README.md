# 04 — Direkt gegen die CM-SQL-DB

Schnellster Weg, am wenigsten "ConfigMgr-konform". Nutzt die offiziell dokumentierten
`v_*`-Views in `CM_<SiteCode>`. Read-only, niemals schreiben.

## Voraussetzungen

- `mssql-tools` (`sqlcmd`) auf dem Runner — oder `go-mssqldb` / Python-Alternative
- DB-User mit `db_datareader` auf `CM_<Site>` (oder Windows-Auth via Kerberos)
- Netzwerkzugriff auf SQL (1433) — oft restriktiver als auf den SMS-Provider

## Dateien

- `wait-configmgr-deployed.sh`
- `main.tf`

## Aufruf manuell

```bash
kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL
./wait-configmgr-deployed.sh PC123 sql.corp.local CM_P01
```

## Genutzte Views

- `v_R_System` — Resource-Stammdaten, `Client0`-Spalte
- `v_TaskExecutionStatus` — TS-Run-Historie pro Resource
- `v_CH_ClientSummary` — Client-Health (optional ergänzend)

## Demo-Skripte

10 Skripte unter [`Demo/`](Demo/) zeigen was sich aus den `v_*`-Views der
ConfigMgr-DB abfragen laesst (Devices, HW-/SW-Inventory, Collections,
Deployments, TS-Status, Client-Health, View-Discovery, komplexe
Aggregationen). Siehe [`Demo/Übersicht.md`](Demo/Übersicht.md).

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source        = "../../04-sql-direct"
  computer_name = "PC123"
  sql_host      = "sql.corp.local"
  db_name       = "CM_P01"
  # sql_user/sql_password optional fuer SQL-Auth statt Kerberos
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).
