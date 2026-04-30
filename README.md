[![CI](https://github.com/monoeagle/lucent-mecm-ps-connect/actions/workflows/ci.yml/badge.svg)](https://github.com/monoeagle/lucent-mecm-ps-connect/actions/workflows/ci.yml)

# ConfigMgr Deployment-Status für OpenTofu

Fünf Wege, um aus einem Linux-Runner heraus den "Rechner ist ausgerollt"-Status
aus **Microsoft Configuration Manager** (offiziell `ConfigMgr` / informell
weiter `SCCM` oder `MECM`) zu lesen und OpenTofu darauf warten zu lassen.

> **Naming-Hinweis:** Der Repo-Slug enthält aus historischen Gründen noch
> `mecm`. Inhaltlich/dokumentarisch ist alles auf den aktuellen Produktnamen
> **ConfigMgr** umgestellt. Kontext zur Namenshistorie in
> [`docs/configmgr-versions.md`](docs/configmgr-versions.md).

## Dokumentation

- [`OVERVIEW.md`](OVERVIEW.md) — Entscheidungsbaum, Vergleich, Flussdiagramme
  pro Variante
- [`docs/adminservice.md`](docs/adminservice.md) — Architektur, URLs, Auth und
  Nutzung des ConfigMgr AdminService
- [`docs/configmgr-versions.md`](docs/configmgr-versions.md) — Naming-Historie,
  Versions-Schema, Release-Cadence, Stand 2026, Detektion
- [`docs/compatibility-2026.md`](docs/compatibility-2026.md) — Kompatibilitäts-
  Check der 5 Wege gegen aktuelle ConfigMgr-Versionen (2503/2509/2603)
- [`docs/auth-setup.md`](docs/auth-setup.md) — Konkretes Auth-Kochbuch:
  Service-Account, RBAC-Rolle, Keytab, krb5/CA-Trust auf Linux, Smoke-Tests
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — Diagnose-Hinweise
  zu Auth, ConfigMgr, Tofu und Skript-Problemen mit Diagnose-Befehlen
- [`docs/glossary.md`](docs/glossary.md) — Quick-Lookup für
  ConfigMgr-/Auth-/OData-Begriffe (für Tofu-Engineers ohne MECM-Background)
- [`examples/basic-wait`](examples/basic-wait) — minimales Tofu-Beispiel,
  das eine der fünf Varianten als Modul einbindet
- [`examples/full-vm-rollout`](examples/full-vm-rollout) — End-to-End-Pipeline:
  VM-Provisioning → ConfigMgr-Wait → parallele Folge-Tasks (DNS, Monitoring,
  CMDB) → Final-Notification

| Ordner | Stack | Voraussetzungen | Stärke | Schwäche |
|---|---|---|---|---|
| `01-adminservice-pwsh` | PowerShell 7 + AdminService REST (auch [5.1-Compat](01-adminservice-pwsh/windows-pwsh5/) verfügbar) | pwsh auf Runner, AdminService aktiv (CB 1810+), Kerberos-Keytab | Sauber, JSON-nativ, supported | pwsh-Dependency |
| `02-adminservice-bash` | curl + jq + AdminService REST | curl, jq, kinit, AdminService aktiv | Keine pwsh-Dependency, leichtgewichtig | Mehr Bash-Glue für Fehler-Handling |
| `03-winrm-jumphost` | pwsh → WinRM → Windows-Jumphost mit `ConfigurationManager`-Modul | pwsh-remoting, Jumphost mit Console | Voller Cmdlet-Zugriff, AdminService nicht nötig | Zwei-Hop-Auth, mehr Moving Parts |
| `04-sql-direct` | sqlcmd (mssql-tools) gegen CM-DB Views | Read-Account auf `CM_<Site>`, Netzwerkpfad zu SQL | Schnellste Queries, beste für komplexe Joins | Nur Read, DBA-Approval nötig, brittler bei CM-Upgrades |
| `05-cmdlets-package` | pwsh → WinRM → Windows-Host mit exportiertem Cmdlet-Package | pwsh-remoting, Windows-Host (kein Console-Install), Cmdlet-Package | Voller Cmdlet-Zugriff ohne Console-Installation | Package nicht offiziell distribuiert, manuelle Pflege |

## Definition "deployed"

Alle Skripte prüfen per Default zwei Bedingungen:

1. **Task Sequence erfolgreich** — letzte TS-Deployment-Execution für den Rechner endet mit Success-Status (StatusType=5 / MessageID 11171).
2. **Client aktiv** — `SMS_R_System.Client = 1` und letztes Heartbeat innerhalb Toleranz.

Anpassen je nach Rollout-Definition (z.B. zusätzlich Pflicht-Apps compliant).

## Tofu-Integration

Standardpattern in jedem Ordner:

```hcl
resource "null_resource" "wait_for_configmgr" {
  triggers = { computer_name = var.computer_name }

  provisioner "local-exec" {
    command = "./wait-configmgr-deployed.sh ${var.computer_name}"
  }
}

resource "next_thing" "x" {
  depends_on = [null_resource.wait_for_configmgr]
  # ...
}
```

Script blockiert bis Status erreicht oder Timeout — Tofu wartet entsprechend.
