# ConfigMgr-Anbindung aus OpenTofu — Übersicht

Ziel: OpenTofu soll warten, bis ein Rechner in ConfigMgr den Status
"ausgerollt" erreicht hat, bevor Folge-Resources angelegt werden.

Sieben Wege — gruppiert nach Origin (Linux oder Windows) und Ansatz.

---

## Entscheidungsbaum

```mermaid
flowchart TD
    Start([Tofu braucht ConfigMgr-Status]) --> Q0{Origin:<br/>Linux oder Windows?}

    Q0 -- Linux --> Q1L{AdminService<br/>REST aktiv?<br/>CB 1810+}
    Q1L -- ja, pwsh vorhanden --> A01[01 — AdminService + pwsh\nLinux / pwsh 7 / Kerberos]
    Q1L -- ja, kein pwsh --> A03[03 — AdminService + bash\nLinux / curl+jq / Kerberos]
    Q1L -- nein --> Q2L{Direkter SQL-\nZugriff erlaubt?}
    Q2L -- ja --> A05[05 — SQL direkt\nLinux / sqlcmd / Kerberos]
    Q2L -- nein --> Q3L{Console-Install<br/>auf Windows-Hop?}
    Q3L -- ja --> A04[04 — WinRM-Jumphost\nLinux → WinRM → Windows + Console]
    Q3L -- nein --> A07[07 — Cmdlet-Package\nLinux → WinRM → Windows + Package]

    Q0 -- Windows --> Q1W{AdminService<br/>REST aktiv?<br/>CB 1810+}
    Q1W -- ja --> A02[02 — AdminService + pwsh\nWindows / PS 5.1 / SSPI]
    Q1W -- nein --> A06[06 — SQL direkt\nWindows / Invoke-Sqlcmd / SSPI]

    style A01 fill:#d4edda
    style A02 fill:#d4edda
    style A03 fill:#d4edda
    style A05 fill:#fff3cd
    style A06 fill:#fff3cd
    style A04 fill:#ffeeba
    style A07 fill:#ffeeba
```

Grün = empfohlen, Gelb = funktioniert mit mehr Voraussetzungen,
Orange = mehr Moving Parts (Two-Hop, Windows-Infrastruktur nötig).

---

## Vergleichsmatrix

| # | Block | Origin | Tool / Shell | Auth | Port | PS 5.1<br/>ausführbar | AdminService<br/>nötig | Win-Hop | Komplexität |
|---|---|---|---|---|---|---|---|---|---|
| 01 | `adminservice-pwsh-linux` | Linux | `pwsh` 7 | Kerberos (kinit/keytab) | 443 | n/a | ja (CB 1810+) | nein | mittel |
| 02 | `adminservice-pwsh-windows` | **Windows** | **PS 5.1** / pwsh 7 | **SSPI (Windows Auth)** | 443 | **ja** | ja (CB 1810+) | nein | niedrig |
| 03 | `adminservice-bash-linux` | Linux | `bash`/`curl`/`jq` | Kerberos (kinit/keytab) | 443 | n/a | ja (CB 1810+) | nein | mittel |
| 04 | `winrm-jumphost` | Linux | `pwsh` 7 | Kerberos → NTLM/Kerberos | 5986 | nein (Hop-Skripte: **ja**) | nein | **ja** | hoch |
| 05 | `sql-direct-linux` | Linux | `sqlcmd` (bash) | Kerberos / SQL-Auth | 1433 | n/a | nein | nein | niedrig |
| 06 | `sql-direct-windows` | **Windows** | **`Invoke-Sqlcmd`** | **SSPI** / SQL-Auth | 1433 | **ja** | nein | nein | niedrig |
| 07 | `cmdlets-package` | Linux | `pwsh` 7 | Kerberos → NTLM/Kerberos | 5986 | nein (Win-Skripte: **ja**) | nein | **ja** | hoch |

**PS 5.1 ausführbar — Erläuterung:**
- `n/a` = Skript läuft auf Linux (PS 5.1 gibt es nur auf Windows)
- `ja` = Skript ist PS-5.1-kompatibel geschrieben und läuft auf Windows PS 5.1
- `nein (Hop-Skripte: ja)` = das Linux-Runner-Skript nutzt pwsh 7; die Skripte
  die auf dem Windows-Hop ausgeführt werden, sind PS 5.1-kompatibel

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

## Variante 01 — AdminService + PowerShell (Linux)

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh 7\nWait-ConfigMgrDeployed.ps1]
        PWSH --> KRB[Kerberos\nTicket-Cache]
    end
    subgraph ConfigMgr
        AS[AdminService\nIIS auf SMS-Provider\nHTTPS 443]
        AS --> SP[SMS Provider\nWMI]
        SP --> DB[(CM_DB)]
    end
    PWSH -- Negotiate/Kerberos --> AS
```

**Auth:** `kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN` vor dem Tofu-Run.

**Vorteile:** JSON-nativ, supported, gleiche API wie die neue Console nutzt.

**Nachteile:** AdminService muss aktiviert sein (CB 1810+); pwsh-Dependency auf Linux.

---

## Variante 02 — AdminService + PowerShell (Windows)

```mermaid
flowchart LR
    subgraph Windows Workstation / Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PS[powershell.exe 5.1\nWait-ConfigMgrDeployed.ps1]
        PS --> SSPI[SSPI\nWindows Auth]
    end
    subgraph ConfigMgr
        AS[AdminService\nHTTPS 443]
        AS --> SP[SMS Provider\nWMI]
        SP --> DB[(CM_DB)]
    end
    PS -- Negotiate/SSPI --> AS
```

**Auth:** `UseDefaultCredentials = $true` — greift automatisch mit dem
angemeldeten Windows-User; kein kinit, kein Keytab.

**Vorteile:** Kein Kerberos-Setup; PS 5.1 ohne Zusatzinstall; niedrigste Einstiegshürde.

**Nachteile:** AdminService muss aktiviert sein (CB 1810+); Origin muss Windows sein.

---

## Variante 03 — AdminService + Bash/curl (Linux)

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> SH[bash\nwait-configmgr-deployed.sh]
        SH --> CURL[curl --negotiate]
        SH --> JQ[jq]
        CURL --> KRB[krb5 Ticket-Cache]
    end
    subgraph ConfigMgr
        AS[AdminService\nHTTPS 443]
        AS --> SP[SMS Provider]
        SP --> DB[(CM_DB)]
    end
    CURL -- SPNEGO --> AS
```

**Tooling:** `curl`, `jq`, `krb5-user` — alles in jedem Linux-Repo verfügbar.

**Vorteile:** Keine pwsh-Dependency, minimaler Footprint.

**Nachteile:** Mehr Bash-Glue für Fehler-Handling und Pagination; kein Windows-Pendant.

---

## Variante 04 — WinRM-Jumphost mit CM-Console

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh 7\nWait-ConfigMgrDeployed.ps1]
    end
    subgraph Windows Jumphost
        WSMAN[WinRM\nHTTPS 5986]
        REMOTE[Get-ConfigMgrStatus.ps1\nimportiert\nConfigurationManager.psd1]
        WSMAN --> REMOTE
    end
    subgraph ConfigMgr
        SP[SMS Provider\nWMI/DCOM]
        SP --> DB[(CM_DB)]
    end
    PWSH -- New-PSSession\nNegotiate --> WSMAN
    REMOTE -- Get-CMDevice\nGet-CMDeploymentStatus --> SP
```

**Auth:** Zwei-Hop: Linux → WinRM (Jumphost) → SMS-Provider. Kein Credential-
Delegation-Setup nötig, solange der Service-Account lokal auf dem Jumphost arbeitet.

**Vorteile:** Voller Cmdlet-Zugriff; funktioniert auch ohne AdminService.

**Nachteile:** Jumphost als zusätzliche Komponente; langsamer pro Poll; WinRM-HTTPS nötig.

---

## Variante 05 — SQL direkt (Linux)

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> SH[bash\nwait-configmgr-deployed.sh]
        SH --> SQLCMD[sqlcmd\nmssql-tools]
    end
    subgraph ConfigMgr
        SQL[(SQL Server\n1433\nCM_SiteCode)]
        VIEWS[v_R_System\nv_TaskExecutionStatus\nv_CH_ClientSummary]
        SQL --> VIEWS
    end
    SQLCMD -- Kerberos / SQL-Auth --> SQL
```

**Vorteile:** Schnellste Queries; beste Join-Möglichkeiten über mehrere Views.

**Nachteile:** DBA-Approval; View-Schema kann sich bei Major-Upgrades ändern;
separater Netzwerkpfad zu SQL (1433).

---

## Variante 06 — SQL direkt (Windows)

```mermaid
flowchart LR
    subgraph Windows Workstation / Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PS[powershell.exe 5.1\nWait-ConfigMgrDeployed.ps1]
        PS --> ISQL[Invoke-Sqlcmd\nPS 5.1 compat]
        ISQL --> SSPI[SSPI\nWindows Auth]
    end
    subgraph ConfigMgr
        SQL[(SQL Server\n1433\nCM_SiteCode)]
        VIEWS[v_R_System\nv_TaskExecutionStatus\nv_CH_ClientSummary]
        SQL --> VIEWS
    end
    ISQL -- SSPI / SQL-Auth --> SQL
```

**Gleiche SQL-Queries wie Variante 05** — nur der Client ist anders
(`Invoke-Sqlcmd` statt `sqlcmd`, Windows Auth statt Kerberos).

**Vorteile:** Kein Kerberos-Setup; PS 5.1 ohne Zusatzinstall; schnelle Queries.

**Nachteile:** DBA-Approval; View-Schema; Origin muss Windows sein.

---

## Variante 07 — WinRM + exportiertes Cmdlet-Package

```mermaid
flowchart LR
    subgraph Linux Runner
        TF[OpenTofu] --> NR[null_resource]
        NR --> PWSH[pwsh 7\nWait-ConfigMgrDeployed.ps1]
    end
    subgraph Windows Worker-Host
        WSMAN[WinRM\nHTTPS 5986]
        PKG["Cmdlet-Package\nz.B. C:\Tools\PSCMDLets\\\n(ConfigurationManager.psd1\n+ DLLs)"]
        REMOTE[Get-ConfigMgrStatus.ps1\nImport-Module per Pfad\nSMS_ADMIN_UI_PATH gesetzt]
        WSMAN --> REMOTE
        REMOTE --> PKG
    end
    subgraph ConfigMgr
        SP[SMS Provider\nWMI/DCOM]
        SP --> DB[(CM_DB)]
    end
    PWSH -- New-PSSession\nNegotiate --> WSMAN
    REMOTE -- New-PSDrive CMSite\nGet-CMDevice etc. --> SP
```

**Vorteile:** Voller Cmdlet-Zugriff ohne Console-Installation; mehrere Worker
können dasselbe Package nutzen.

**Nachteile:** Package-Pflege manuell (kein Auto-Update via MSI);
rechtlich/support-technisch eine Grauzone; Cmdlet-Compatibility nach
CM-Upgrades selbst prüfen.

---

## Auth-Flow Linux → ConfigMgr (Varianten 01, 03, 05)

```mermaid
sequenceDiagram
    participant Runner as Linux Runner
    participant KDC as AD KDC\n(Domain Controller)
    participant Target as ConfigMgr Endpoint\n(AdminService / WinRM / SQL)

    Runner->>Runner: kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN
    Runner->>KDC: AS-REQ (mit Keytab)
    KDC-->>Runner: TGT
    Runner->>KDC: TGS-REQ für SPN\n(HTTP/sccm... oder MSSQLSvc/...)
    KDC-->>Runner: Service-Ticket
    Runner->>Target: Request mit Negotiate/SPNEGO
    Target-->>Runner: 200 OK
```

**Voraussetzungen:**
- Service-Account `svc-tofu` mit ConfigMgr-RBAC-Rolle "Read-only Analyst"
- Keytab erzeugt: `ktpass /princ HTTP/runner@DOMAIN /mapuser svc-tofu ...`
- SPNs auf ConfigMgr-Seite korrekt registriert

## Auth-Flow Windows → ConfigMgr (Varianten 02, 06)

Keine manuelle Konfiguration nötig. `UseDefaultCredentials = $true` /
`Invoke-Sqlcmd` ohne Credential-Parameter → SSPI verhandelt Kerberos oder
NTLM mit dem angemeldeten Windows-User automatisch.

---

## Was muss vorab geklärt werden?

1. **Origin des Runners:** Linux oder Windows? → schränkt die Optionen sofort ein.
2. **AdminService verfügbar?** → entscheidet 01/02/03 vs. 04/05/06/07.
3. **Service-Account-Strategie:** Keytab im Runner-Image? Vault-injected?
   gMSA via Workload Identity? → entscheidet Auth-Flow auf Linux.
4. **Definition "deployed":** nur TS-Erfolg, oder + Client-Health,
   + Pflicht-Apps compliant, + Compliance-Baseline?
5. **Timeout-Verhalten:** Tofu-Apply hart fehlschlagen lassen oder
   "warning + continue" mit nachgelagertem Check?
6. **Concurrency:** wie viele Rechner parallel? Polling-Intervall ggf.
   anpassen, um SMS-Provider/SQL nicht zu fluten.
