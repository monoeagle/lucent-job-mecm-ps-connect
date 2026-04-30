# Compat-Check 2026 — funktionieren alle 5 Wege mit aktuellem ConfigMgr?

**Stand der Doku:** Wissensstand Januar 2026, gültig für ConfigMgr Current
Branch ≥ **2503**, mit Blick auf **2509** und das erwartete **2603**.
Vor produktivem Einsatz immer gegen die laufende Site verifizieren.

## Kurzfazit

Alle fünf Wege funktionieren weiterhin mit aktuellen ConfigMgr-Versionen.
Es gibt einige Detail-Änderungen, die die Implementierung nicht brechen,
aber wissen sollte man sie.

## Per-Variante-Check

### 01 — AdminService + PowerShell 7 ✅

| Aspekt | Status 2026 |
|---|---|
| AdminService verfügbar | ✅ Pflichtbestandteil seit 1810, weiter ausgebaut |
| `wmi/`-Namespace | ✅ stabil — `SMS_R_System`, `SMS_TaskSequenceDeploymentStatus` etc. unverändert |
| `v1.0/`-Namespace | ✅ deutlich erweitert seit 2303 (mehr "modeled" Resources, OData-Sauberkeit) |
| `Invoke-RestMethod` mit Negotiate | ✅ unverändert |
| PowerShell 7 Kerberos auf Linux | ✅ stabil über libgssapi |

**Hinweis:** Wer dauerhaft `v1.0/Device(...)` statt `wmi/SMS_R_System` nutzt,
hat sauberere Responses. Für den Polling-Use-Case bleibt `wmi/` weiter
empfohlen, weil Task-Sequence-Status dort vollständig liegt.

### 02 — AdminService + Bash/curl ✅

Identische Backend-API wie 01, anderer Client. Selbst gilt:

| Aspekt | Status 2026 |
|---|---|
| `curl --negotiate` mit modernen `curl`-Builds | ✅ |
| `jq` Parsing der OData-Responses | ✅ |
| Pagination via `@odata.nextLink` | ✅ unverändert |

**Achtung:** Default-Page-Size kann zwischen Releases variieren (typisch
1000). Wenn sich Result-Sets ungewöhnlich verhalten, `nextLink` explizit
folgen statt sich auf "alles in einem Call" zu verlassen.

### 03 — WinRM-Jumphost mit ConfigurationManager-Modul ✅

| Aspekt | Status 2026 |
|---|---|
| `ConfigurationManager.psd1` mit Console-Install | ✅ wird mit jedem Release ausgeliefert |
| **Offizieller PowerShell-7-Support** | ✅ **seit ConfigMgr 2107** — ältere CB hatten teils Probleme; aktuelle Releases sind solide |
| `Get-CMDevice`, `Get-CMDeploymentStatus` | ✅ stabile Cmdlets, gelegentlich neue Parameter, keine Breaking Changes |
| `New-PSDrive -PSProvider CMSite` | ✅ unverändert |
| WinRM HTTPS auf Server 2022/2025 | ✅ Standard |

**Hinweis (wichtig):** Vor 2107 war der einzige supported Pfad Windows
PowerShell 5.1. Auf Hosts mit PS 5.1 funktioniert das Modul natürlich
weiterhin — aber pwsh 7 ist heute der Default-Pfad und unsere Skripte
zielen darauf.

### 04 — SQL direkt gegen CM-DB-Views ⚠️

| Aspekt | Status 2026 |
|---|---|
| `v_R_System` | ✅ vorhanden, `Client0`-Spalte stabil |
| `v_TaskExecutionStatus` | ✅ vorhanden — Spalten können pro Release variieren |
| `v_CH_ClientSummary` | ✅ vorhanden |
| `mssql-tools` mit Kerberos auf Linux | ✅ go-mssqldb / `sqlcmd` stabil |
| **View-Schema-Stabilität** | ⚠️ Microsoft dokumentiert Views, garantiert aber kein versioniertes Schema — nach Major-Upgrades testen |

**Empfehlung:** Bei diesem Weg nach jedem ConfigMgr-Major-Upgrade einmal
die Query manuell ausführen und Ergebnis-Shape prüfen. Pflicht-Spalten
explizit benennen, kein `SELECT *`.

### 05 — WinRM + Cmdlet-Package ⚠️

| Aspekt | Status 2026 |
|---|---|
| Cmdlet-Funktionalität | ✅ identisch zu 03 |
| Package-Distribution durch Microsoft | ❌ weiterhin **nicht offiziell** — selbst bauen oder aus Console-Install extrahieren |
| Garry-Smith-Skript auf GitHub | ✅ wird gepflegt, kompatibel mit aktuellen Builds |
| Versionsbindung Package ↔ Site | ⚠️ Cmdlet-Package sollte aus passender CB-Version stammen — alte Packages gegen neue Sites werfen `Version mismatch`-Fehler |
| pwsh 7 Kompatibilität | ✅ wie 03 ab 2107 OK |

**Empfehlung:** Package nach jedem ConfigMgr-Upgrade neu erzeugen und
gegen die Site testen. Versionsstand des Packages dokumentieren
(z.B. in `PSCMDLets/VERSION.txt`).

## Auth-Layer (alle Varianten)

| Aspekt | Status 2026 |
|---|---|
| Kerberos via Keytab auf Linux | ✅ Standard-Pattern |
| Negotiate/SPNEGO durch `curl`/`Invoke-RestMethod` | ✅ |
| Azure-AD-Token via CMG | ✅ ausgereifter, aber unsere Skripte nutzen Kerberos — für Internet-Runner anpassen |
| gMSA via Vault / Workload Identity | ✅ in Enterprise-Setups verbreitet, orthogonal zu unseren Skripten |

## Was sich nach Wissensstand Januar 2026 noch ändern könnte

Stand-2026-Versionen, die nach dem Wissensstand released wurden (2603+):

- **Modeled-API-Endpoints im `v1.0/`-Namespace** wachsen weiter — wenn
  unser Code rein gegen `wmi/` geht, betrifft uns das nicht.
- **Cmdlet-Renaming/-Deprecation** wäre möglich (selten, aber bei jedem
  Release in den Release Notes prüfen).
- **TLS-Defaults / Cipher-Suites** — IIS-seitig kann sich das verschärfen.
  `curl` und `Invoke-RestMethod` nutzen System-Defaults; bei TLS-Fehlern
  neuere `curl`-Builds und CA-Trust prüfen.

**Empfehlung:** Bei Adoption einer neueren ConfigMgr-Version (jenseits
2509/2603) einmal die Smoke-Tests jeder genutzten Variante laufen lassen,
bevor produktiv umgestellt wird.
