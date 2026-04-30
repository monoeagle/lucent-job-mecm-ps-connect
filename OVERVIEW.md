# MECM-Anbindung aus OpenTofu (Linux-Runner) — Übersicht

Ziel: OpenTofu auf einem Linux-Runner soll warten, bis ein Rechner in MECM
den Status "ausgerollt" erreicht hat, bevor Folge-Resources angelegt werden.

## Entscheidungsbaum

```mermaid
flowchart TD
    Start([Tofu braucht MECM-Status]) --> Q1{AdminService<br/>REST aktiv?<br/>CB 1810+}
    Q1 -- ja --> Q2{pwsh auf<br/>Runner OK?}
    Q1 -- nein --> Q3{Direkter SQL-<br/>Zugriff erlaubt?}
    Q2 -- ja --> A1[01 — AdminService + pwsh]
    Q2 -- nein --> A2[02 — AdminService + bash/curl]
    Q3 -- ja --> A4[04 — SQL direkt]
    Q3 -- nein --> A3[03 — WinRM-Jumphost]

    style A1 fill:#d4edda
    style A2 fill:#d4edda
    style A3 fill:#fff3cd
    style A4 fill:#f8d7da
```

Grün = empfohlen, Gelb = funktioniert mit mehr Moving Parts, Rot = nur wenn
nichts anderes geht (DBA-Approval, brittler bei CM-Upgrades).

---

## Vergleichsmatrix

| Kriterium | 01 pwsh+REST | 02 bash+REST | 03 WinRM-Jumphost | 04 SQL direkt |
|---|---|---|---|---|
| Linux-Runner native | ✅ (mit pwsh) | ✅ | ✅ (mit pwsh) | ✅ |
| Microsoft-supported | ✅ | ✅ | ✅ | ⚠️ Views ja, Schema nein |
| Latenz pro Poll | ~1-2s | ~1-2s | ~3-5s (Hop) | <500ms |
| Ports nach außen | 443 | 443 | 5986 | 1433 |
| Setup-Aufwand | mittel | mittel | hoch | niedrig |
| Berechtigungs-Granularität | RBAC AdminService | RBAC AdminService | volles MECM-RBAC | DB-Read |
| Risiko bei CM-Upgrade | gering | gering | gering | mittel (View-Schema) |

---

## Gemeinsamer Tofu-Flow (alle vier Wege)

```mermaid
sequenceDiagram
    participant Tofu as OpenTofu
    participant NR as null_resource.wait_for_mecm
    participant Script as wait-script
    participant MECM as MECM (Provider/SQL)

    Tofu->>NR: apply
    NR->>Script: local-exec
    loop alle 30s bis Timeout
        Script->>MECM: query device + TS status
        MECM-->>Script: state
        alt deployed
            Script-->>NR: exit 0
        else nicht deployed
            Script->>Script: sleep 30s
        end
    end
    NR-->>Tofu: success
    Tofu->>Tofu: nachfolgende Resources
```

---

## Variante 01 — AdminService + PowerShell 7

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh<br/>Wait-MecmDeployed.ps1]
        PWSH --> KRB[Kerberos<br/>Ticket-Cache]
    end
    subgraph MECM
        AS[AdminService<br/>IIS auf SMS-Provider<br/>HTTPS 443]
        AS --> SP[SMS Provider<br/>WMI]
        SP --> DB[(CM_DB)]
    end
    PWSH -- Negotiate/Kerberos --> AS
```

**Cmdlets/Calls:**
- `Invoke-RestMethod -UseDefaultCredentials -Uri https://.../AdminService/wmi/SMS_R_System?$filter=...`
- `Invoke-RestMethod -UseDefaultCredentials -Uri https://.../AdminService/wmi/SMS_TaskSequenceDeploymentStatus?$filter=...`

**Vorteile:** JSON-nativ, supported, gleiche API wie die neue Console nutzt.
**Nachteile:** AdminService muss aktiviert sein (CB 1810+, IIS-Konfig); pwsh-Dependency.

---

## Variante 02 — AdminService + Bash/curl

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> SH[bash<br/>wait-mecm-deployed.sh]
        SH --> CURL[curl --negotiate]
        SH --> JQ[jq]
        CURL --> KRB[krb5 Ticket-Cache]
    end
    subgraph MECM
        AS[AdminService<br/>HTTPS 443]
        AS --> SP[SMS Provider]
        SP --> DB[(CM_DB)]
    end
    CURL -- SPNEGO --> AS
```

**Tooling:** `curl`, `jq`, `krb5-user` — alles in jedem Linux-Repo verfügbar.

**Vorteile:** Keine pwsh-Dependency, minimaler Footprint.
**Nachteile:** Mehr Bash-Glue für Fehler-Handling und Pagination.

---

## Variante 03 — WinRM-Jumphost mit ConfigurationManager-Modul

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh<br/>Wait-MecmDeployed.ps1]
    end
    subgraph Windows Jumphost
        WSMAN[WinRM<br/>HTTPS 5986]
        REMOTE[Get-MecmStatus.ps1<br/>importiert<br/>ConfigurationManager.psd1]
        WSMAN --> REMOTE
    end
    subgraph MECM
        SP[SMS Provider<br/>WMI/DCOM]
        SP --> DB[(CM_DB)]
    end
    PWSH -- New-PSSession<br/>Negotiate --> WSMAN
    REMOTE -- Get-CMDevice<br/>Get-CMDeploymentStatus --> SP
```

**Zwei-Hop-Auth:** Linux → WinRM (Jumphost) → SMS-Provider. Letzteres läuft
mit dem Service-Account der WinRM-Session — kein Delegation-Setup nötig,
solange das Konto auf dem Jumphost lokal arbeitet.

**Vorteile:** Voller Cmdlet-Zugriff (`Get-CMDevice`, `Get-CMCollection`,
`Get-CMDeployment` etc.); funktioniert auch ohne AdminService.
**Nachteile:** Jumphost als zusätzliche Komponente, langsamer pro Poll,
WinRM-HTTPS muss eingerichtet sein.

---

## Variante 04 — SQL direkt gegen CM-Datenbank

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> SH[bash<br/>wait-mecm-deployed.sh]
        SH --> SQLCMD[sqlcmd<br/>mssql-tools]
    end
    subgraph MECM
        SQL[(SQL Server<br/>1433<br/>CM_SiteCode)]
        VIEWS[v_R_System<br/>v_TaskExecutionStatus<br/>v_CH_ClientSummary]
        SQL --> VIEWS
    end
    SQLCMD -- Kerberos / SQL-Auth --> SQL
```

**Genutzte Views (offiziell dokumentiert):**
- `v_R_System` — Resource-Stammdaten, `Client0`
- `v_TaskExecutionStatus` — TS-Run-Historie
- `v_CH_ClientSummary` — Client-Health (optional)

**Vorteile:** Schnellste Queries, beste Join-Möglichkeiten.
**Nachteile:** Nur lesend, DBA-Approval, View-Schema kann sich bei
Major-Upgrades ändern, separater Netzwerkpfad zur SQL.

---

## Auth-Flow (Linux → MECM)

Gleich für Variante 01, 02, 04 (Kerberos) und sinngemäß für 03:

```mermaid
sequenceDiagram
    participant Runner as Linux Runner
    participant KDC as AD KDC<br/>(Domain Controller)
    participant Target as MECM Endpoint<br/>(AdminService / WinRM / SQL)

    Runner->>Runner: kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN
    Runner->>KDC: AS-REQ (mit Keytab)
    KDC-->>Runner: TGT
    Runner->>KDC: TGS-REQ für SPN<br/>(HTTP/sccm... oder MSSQLSvc/...)
    KDC-->>Runner: Service-Ticket
    Runner->>Target: Request mit Negotiate/SPNEGO
    Target-->>Runner: 200 OK
```

**Voraussetzungen im AD/MECM:**
- Service-Account `svc-tofu` mit MECM-RBAC-Rolle "Read-only Analyst"
  (oder spezifischer)
- Keytab erzeugt: `ktpass /princ HTTP/runner@DOMAIN /mapuser svc-tofu ...`
- SPNs auf MECM-Seite korrekt registriert (für AdminService normalerweise
  automatisch via IIS-Computerkonto)

---

## Was muss vorab geklärt werden?

1. **AdminService verfügbar?** → entscheidet 01/02 vs 03/04
2. **Service-Account-Strategie:** Keytab im Runner-Image? Vault-injected?
   gMSA via [Microsoft AAD Workload Identity]? → entscheidet Auth-Flow
3. **Definition "deployed":** nur TS-Erfolg, oder + Client-Health,
   + Pflicht-Apps compliant, + Compliance-Baseline?
4. **Timeout-Verhalten:** Tofu-Apply hart fehlschlagen lassen oder
   "warning + continue" mit nachgelagertem Check?
5. **Concurrency:** wie viele Rechner parallel? Polling-Intervall ggf.
   anpassen, um SMS-Provider/SQL nicht zu fluten.
