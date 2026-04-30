# MECM Deployment-Status für OpenTofu

Vier Wege, um aus einem Linux-Runner heraus den "Rechner ist ausgerollt"-Status
aus MECM (ConfigMgr) zu lesen und OpenTofu darauf warten zu lassen.

## Dokumentation

- [`OVERVIEW.md`](OVERVIEW.md) — Entscheidungsbaum, Vergleich, Flussdiagramme
  pro Variante
- [`docs/adminservice.md`](docs/adminservice.md) — Architektur, URLs, Auth und
  Nutzung des MECM AdminService
- [`docs/mecm-versions.md`](docs/mecm-versions.md) — Versions-Schema,
  Release-Cadence, Stand 2026, Detektion

| Ordner | Stack | Voraussetzungen | Stärke | Schwäche |
|---|---|---|---|---|
| `01-adminservice-pwsh` | PowerShell 7 + AdminService REST | pwsh auf Runner, AdminService aktiv (CB 1810+), Kerberos-Keytab | Sauber, JSON-nativ, supported | pwsh-Dependency |
| `02-adminservice-bash` | curl + jq + AdminService REST | curl, jq, kinit, AdminService aktiv | Keine pwsh-Dependency, leichtgewichtig | Mehr Bash-Glue für Fehler-Handling |
| `03-winrm-jumphost` | pwsh → WinRM → Windows-Jumphost mit `ConfigurationManager`-Modul | pwsh-remoting, Jumphost mit Console | Voller Cmdlet-Zugriff, AdminService nicht nötig | Zwei-Hop-Auth, mehr Moving Parts |
| `04-sql-direct` | sqlcmd (mssql-tools) gegen CM-DB Views | Read-Account auf `CM_<Site>`, Netzwerkpfad zu SQL | Schnellste Queries, beste für komplexe Joins | Nur Read, DBA-Approval nötig, brittler bei CM-Upgrades |

## Definition "deployed"

Alle Skripte prüfen per Default zwei Bedingungen:

1. **Task Sequence erfolgreich** — letzte TS-Deployment-Execution für den Rechner endet mit Success-Status (StatusType=5 / MessageID 11171).
2. **Client aktiv** — `SMS_R_System.Client = 1` und letztes Heartbeat innerhalb Toleranz.

Anpassen je nach Rollout-Definition (z.B. zusätzlich Pflicht-Apps compliant).

## Tofu-Integration

Standardpattern in jedem Ordner:

```hcl
resource "null_resource" "wait_for_mecm" {
  triggers = { computer_name = var.computer_name }

  provisioner "local-exec" {
    command = "./wait-mecm-deployed.sh ${var.computer_name}"
  }
}

resource "next_thing" "x" {
  depends_on = [null_resource.wait_for_mecm]
  # ...
}
```

Script blockiert bis Status erreicht oder Timeout — Tofu wartet entsprechend.
