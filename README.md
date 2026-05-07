[![CI](https://github.com/monoeagle/lucent-mecm-ps-connect/actions/workflows/ci.yml/badge.svg)](https://github.com/monoeagle/lucent-mecm-ps-connect/actions/workflows/ci.yml)

# ConfigMgr Deployment-Status für OpenTofu

Sieben Wege, um aus einem Linux- oder Windows-Runner heraus den
"Rechner ist ausgerollt"-Status aus **Microsoft Configuration Manager**
(offiziell `ConfigMgr` / informell weiter `SCCM` oder `MECM`) zu lesen
und OpenTofu darauf warten zu lassen.

> **Naming-Hinweis:** Der Repo-Slug enthält aus historischen Gründen noch
> `mecm`. Inhaltlich/dokumentarisch ist alles auf den aktuellen Produktnamen
> **ConfigMgr** umgestellt. Kontext zur Namenshistorie in
> [`docs/configmgr-versions.md`](docs/configmgr-versions.md).

## Dokumentation

- [`OVERVIEW.md`](OVERVIEW.md) — Entscheidungsbaum, Vergleichsmatrix, Flussdiagramme
  pro Variante
- [`docs/adminservice.md`](docs/adminservice.md) — Architektur, URLs, Auth und
  Nutzung des ConfigMgr AdminService
- [`docs/configmgr-versions.md`](docs/configmgr-versions.md) — Naming-Historie,
  Versions-Schema, Release-Cadence, Stand 2026, Detektion
- [`docs/compatibility-2026.md`](docs/compatibility-2026.md) — Kompatibilitäts-
  Check der Wege gegen aktuelle ConfigMgr-Versionen (2503/2509/2603)
- [`docs/auth-setup.md`](docs/auth-setup.md) — Konkretes Auth-Kochbuch:
  Service-Account, RBAC-Rolle, Keytab, krb5/CA-Trust auf Linux, Smoke-Tests
- [`docs/troubleshooting.md`](docs/troubleshooting.md) — Diagnose-Hinweise
  zu Auth, ConfigMgr, Tofu und Skript-Problemen mit Diagnose-Befehlen
- [`docs/glossary.md`](docs/glossary.md) — Quick-Lookup für
  ConfigMgr-/Auth-/OData-Begriffe (für Tofu-Engineers ohne MECM-Background)
- [`examples/basic-wait`](examples/basic-wait) — minimales Tofu-Beispiel,
  das eine der Varianten als Modul einbindet
- [`examples/full-vm-rollout`](examples/full-vm-rollout) — End-to-End-Pipeline:
  VM-Provisioning → ConfigMgr-Wait → parallele Folge-Tasks (DNS, Monitoring,
  CMDB) → Final-Notification

## Übersicht der sieben Varianten

| # | Ordner | Origin | Stack | PS 5.1<br/>ausführbar | Stärke | Schwäche |
|---|---|---|---|---|---|---|
| 01 | `01-adminservice-pwsh-linux` | Linux | pwsh 7 + AdminService REST | n/a | Sauber, JSON-nativ, supported | pwsh-Dependency, Kerberos-Setup |
| 02 | `02-adminservice-pwsh-windows` | **Windows** | **PS 5.1** + AdminService REST | **ja** | Kein Kerberos-Setup, PS 5.1 built-in | Origin muss Windows sein |
| 03 | `03-adminservice-bash-linux` | Linux | curl + jq + AdminService REST | n/a | Keine pwsh-Dependency, minimaler Footprint | Mehr Bash-Glue, Linux-only |
| 04 | `04-winrm-jumphost` | Linux | pwsh 7 → WinRM → Windows + Console | nein (Hop: ja) | Voller Cmdlet-Zugriff, kein AdminService nötig | Zwei-Hop, mehr Moving Parts |
| 05 | `05-sql-direct-linux` | Linux | sqlcmd gegen CM-DB Views | n/a | Schnellste Queries, beste Joins | DBA-Approval, brittler bei Upgrades |
| 06 | `06-sql-direct-windows` | **Windows** | **PS 5.1** + `Invoke-Sqlcmd` | **ja** | Kein Kerberos-Setup, schnelle Queries | DBA-Approval, Origin muss Windows sein |
| 07 | `07-cmdlets-package` | Linux | pwsh 7 → WinRM → Windows + Cmdlet-Package | nein (Win: ja) | Voller Cmdlet-Zugriff, kein Console-Install | Package-Pflege manuell, semi-offiziell |

**PS 5.1 ausführbar:** `n/a` = läuft auf Linux (PS 5.1 gibt es nur auf Windows).

## Definition "deployed"

Alle Skripte prüfen per Default zwei Bedingungen:

1. **Task Sequence erfolgreich** — letzte TS-Deployment-Execution für den
   Rechner endet mit Success-Status (StatusType=5 / MessageID 11171).
2. **Client aktiv** — `SMS_R_System.Client = 1` und letztes Heartbeat
   innerhalb Toleranz.

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
