# ConfigMgr-Anbindung aus OpenTofu (Linux-Runner) — Übersicht

Ziel: OpenTofu auf einem Linux-Runner soll warten, bis ein Rechner in ConfigMgr
den Status "ausgerollt" erreicht hat, bevor Folge-Resources angelegt werden.

## Entscheidungsbaum

```mermaid
flowchart TD
    Start([Tofu braucht ConfigMgr-Status]) --> Q1{AdminService<br/>REST aktiv?<br/>CB 1810+}
    Q1 -- ja --> Q2{pwsh auf<br/>Runner OK?}
    Q1 -- nein --> Q3{Direkter SQL-<br/>Zugriff erlaubt?}
    Q2 -- ja --> A1[01 — AdminService + pwsh]
    Q2 -- nein --> A2[02 — AdminService + bash/curl]
    Q3 -- ja --> A4[04 — SQL direkt]
    Q3 -- nein --> Q4{Console-Install auf<br/>Windows-Hop möglich?}
    Q4 -- ja --> A3[03 — WinRM-Jumphost<br/>mit Admin-Console]
    Q4 -- nein --> A5[05 — WinRM<br/>+ Cmdlet-Package]

    style A1 fill:#d4edda
    style A2 fill:#d4edda
    style A3 fill:#fff3cd
    style A5 fill:#fff3cd
    style A4 fill:#f8d7da
```

Grün = empfohlen, Gelb = funktioniert mit mehr Moving Parts, Rot = nur wenn
nichts anderes geht (DBA-Approval, brittler bei CM-Upgrades).

---

## Vergleichsmatrix

| Kriterium | 01 pwsh+REST | 02 bash+REST | 03 WinRM + Console | 04 SQL direkt | 05 WinRM + Cmdlet-Pkg |
|---|---|---|---|---|---|
| Linux-Runner als Origin | ✅ (mit pwsh) | ✅ | ✅ (mit pwsh) | ✅ | ✅ (mit pwsh) |
| Windows-Hop nötig | nein | nein | **ja (Console)** | nein | **ja (nur Package)** |
| Microsoft-supported | ✅ | ✅ | ✅ | ⚠️ Views ja, Schema nein | ⚠️ Cmdlets ja, Package-Distribution semi-offiziell |
| Latenz pro Poll | ~1-2s | ~1-2s | ~3-5s (Hop) | <500ms | ~3-5s (Hop) |
| Ports nach außen | 443 | 443 | 5986 | 1433 | 5986 |
| Setup-Aufwand | mittel | mittel | hoch | niedrig | mittel-hoch |
| Berechtigungs-Granularität | RBAC AdminService | RBAC AdminService | volles ConfigMgr-RBAC | DB-Read | volles ConfigMgr-RBAC |
| Cmdlet-Funktionsumfang | begrenzt (REST-Subset) | begrenzt (REST-Subset) | voll (`Get-CM*` etc.) | irrelevant (SQL) | voll (`Get-CM*` etc.) |
| Min. ConfigMgr-Version | 1810 | 1810 | jede | jede (View-Stabilität CB-abhängig) | jede |
| Risiko bei CM-Upgrade | gering | gering | gering | mittel (View-Schema) | mittel (Cmdlet-Compat im Package) |
| Wartung Windows-Komponente | n/a | n/a | MS-Update-Pfad (MSI) | n/a | manuelle Package-Pflege |

---

## Gemeinsamer Tofu-Flow (alle Wege)

```mermaid
sequenceDiagram
    participant Tofu as OpenTofu
    participant NR as null_resource.wait_for_configmgr
    participant Script as wait-script
    participant ConfigMgr as ConfigMgr (Provider/SQL)

    Tofu->>NR: apply
    NR->>Script: local-exec
    loop alle 30s bis Timeout
        Script->>ConfigMgr: query device + TS status
        ConfigMgr-->>Script: state
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
        NR --> PWSH[pwsh<br/>Wait-ConfigMgrDeployed.ps1]
        PWSH --> KRB[Kerberos<br/>Ticket-Cache]
    end
    subgraph ConfigMgr
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
        NR --> SH[bash<br/>wait-configmgr-deployed.sh]
        SH --> CURL[curl --negotiate]
        SH --> JQ[jq]
        CURL --> KRB[krb5 Ticket-Cache]
    end
    subgraph ConfigMgr
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
        NR --> PWSH[pwsh<br/>Wait-ConfigMgrDeployed.ps1]
    end
    subgraph Windows Jumphost
        WSMAN[WinRM<br/>HTTPS 5986]
        REMOTE[Get-ConfigMgrStatus.ps1<br/>importiert<br/>ConfigurationManager.psd1]
        WSMAN --> REMOTE
    end
    subgraph ConfigMgr
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
        NR --> SH[bash<br/>wait-configmgr-deployed.sh]
        SH --> SQLCMD[sqlcmd<br/>mssql-tools]
    end
    subgraph ConfigMgr
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

## Variante 05 — WinRM + exportiertes Cmdlet-Package

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh<br/>Wait-ConfigMgrDeployed.ps1]
    end
    subgraph Windows Worker-Host
        WSMAN[WinRM<br/>HTTPS 5986]
        PKG["Cmdlet-Package<br/>z.B. C:\Tools\PSCMDLets\<br/>(ConfigurationManager.psd1<br/>+ DLLs)"]
        REMOTE[Get-ConfigMgrStatus.ps1<br/>Import-Module per Pfad<br/>SMS_ADMIN_UI_PATH gesetzt]
        WSMAN --> REMOTE
        REMOTE --> PKG
    end
    subgraph ConfigMgr
        SP[SMS Provider<br/>WMI/DCOM]
        SP --> DB[(CM_DB)]
    end
    PWSH -- New-PSSession<br/>Negotiate --> WSMAN
    REMOTE -- New-PSDrive CMSite<br/>Get-CMDevice etc. --> SP
```

**Konzept:** Wie Variante 03, aber der Windows-Host braucht **keine
vollständige Admin-Console-Installation** — nur das exportierte Cmdlet-Package
in einem beliebigen Ordner. Setup einmalig per `Setup-CmdletPackage.ps1`:

```powershell
Import-Module C:\Tools\PSCMDLets\ConfigurationManager.psd1
$env:SMS_ADMIN_UI_PATH = 'C:\Tools\PSCMDLets'
New-PSDrive -Name <SiteCode> -PSProvider CMSite -Root <sms-provider-fqdn>
```

**Package-Beschaffung:** Microsoft liefert das Package nicht direkt. Üblich:
selbst erzeugen via [garytown — CreateCMPowerShellModulePackage.ps1](https://github.com/gwblok/garytown/blob/master/CreateCMPowerShellModulePackage.ps1)
oder Inhalt aus `…\AdminUI\bin\` einer existierenden Installation
extrahieren (siehe [garrettyamada-Artikel](https://garrettyamada.com/posts/connecting-to-sccm-using-powershell)).

**Vorteile:** Voller Cmdlet-Zugriff wie Variante 03; minimaler Footprint
auf dem Windows-Hop; mehrere Worker können dasselbe Package nutzen.
**Nachteile:** Package-Pflege manuell (kein Auto-Update via MSI); rechtlich/
support-technisch eine Grauzone, da Package nicht offiziell distribuiert wird;
Cmdlet-Compatibility nach CM-Upgrades selbst prüfen.

---

## Auth-Flow (Linux → ConfigMgr)

Gleich für Variante 01, 02, 04 (Kerberos) und sinngemäß für 03/05:

```mermaid
sequenceDiagram
    participant Runner as Linux Runner
    participant KDC as AD KDC<br/>(Domain Controller)
    participant Target as ConfigMgr Endpoint<br/>(AdminService / WinRM / SQL)

    Runner->>Runner: kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN
    Runner->>KDC: AS-REQ (mit Keytab)
    KDC-->>Runner: TGT
    Runner->>KDC: TGS-REQ für SPN<br/>(HTTP/sccm... oder MSSQLSvc/...)
    KDC-->>Runner: Service-Ticket
    Runner->>Target: Request mit Negotiate/SPNEGO
    Target-->>Runner: 200 OK
```

**Voraussetzungen im AD/ConfigMgr:**
- Service-Account `svc-tofu` mit ConfigMgr-RBAC-Rolle "Read-only Analyst"
  (oder spezifischer)
- Keytab erzeugt: `ktpass /princ HTTP/runner@DOMAIN /mapuser svc-tofu ...`
- SPNs auf ConfigMgr-Seite korrekt registriert (für AdminService normalerweise
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
