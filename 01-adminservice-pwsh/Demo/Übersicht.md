# Demo-Skripte — AdminService via PowerShell 7

Sammlung von Skripten, die zeigen, **was sich ueber den ConfigMgr-AdminService
abfragen laesst**. Jedes Skript ist standalone, nutzt `_common.ps1` fuer
Auth-Setup und liefert ein konkretes Ergebnis.

## Setup

```bash
export CONFIGMGR_ADMINSERVICE_BASE='https://sccm.corp.local/AdminService'
# Optional fuer Demo-Umgebungen ohne CA-Trust:
# export CONFIGMGR_SKIP_CERT_CHECK=true
kinit -kt /etc/krb5.keytab svc-tofu@DOMAIN.LOCAL    # falls noch nicht passiert
```

Alle Skripte sind PowerShell 7 — Linux/macOS/Windows ueber `pwsh` aufrufbar.

## Uebersicht

| # | Skript | Was es zeigt | Genutzte Endpoints |
|---|---|---|---|
| 010 | `010-list-devices.ps1` | Device-Listing, Filter, Pagination | `wmi/SMS_R_System` |
| 020 | `020-device-full.ps1` | Stammdaten + Hardware-Inventory eines Device | `SMS_R_System`, `SMS_G_System_COMPUTER_SYSTEM`, `_OPERATING_SYSTEM`, `_PC_BIOS`, `_PROCESSOR`, `_LOGICAL_DISK` |
| 030 | `030-device-software.ps1` | Installierte Software pro Device | `wmi/SMS_G_System_INSTALLED_SOFTWARE` |
| 040 | `040-device-collections.ps1` | Welche Collections enthalten ein Device? | `SMS_FullCollectionMembership`, `SMS_Collection` |
| 050 | `050-collection-members.ps1` | Members einer Collection | `SMS_Collection`, `SMS_FullCollectionMembership` |
| 060 | `060-deployments.ps1` | Aktive **und/oder** zukuenftig geplante Deployments | `wmi/SMS_DeploymentInfo` |
| 070 | `070-task-sequence-status.ps1` | Task-Sequence-Status-Historie | `wmi/SMS_TaskSequenceDeploymentStatus` |
| 080 | `080-client-health.ps1` | Client-Health-Summary (auch "nur unhealthy") | `wmi/SMS_CH_ClientSummary` |
| 090 | `090-discover-classes.ps1` | **Meta:** alle queryable Klassen via `$metadata` | `wmi/$metadata` |
| 100 | `100-modeled-api.ps1` | Tour durch `/v1.0/`-Namespace | `v1.0/`, `v1.0/Device`, `v1.0/Collection` |

## Was sich noch alles abfragen laesst

Ueber `090-discover-classes.ps1` siehst du EntitySets fuer:

- **Discovery / Stammdaten:** `SMS_R_System`, `SMS_R_User`, `SMS_R_UserGroup`, `SMS_R_IPSubnet`, `SMS_R_ADGroup`
- **Hardware-Inventory** (rund 100 Klassen, je nach Inventory-Settings): `SMS_G_System_*` — Computer, OS, BIOS, CPU, RAM, Disks, Network, Battery, Monitor, USB, Drivers, Services, Processes, Installed Programs/Software, Updates, …
- **Custom Hardware Inventory:** alles, was per MOF erweitert wurde — taucht ebenfalls als `SMS_G_System_*` auf
- **Software-Updates:** `SMS_SoftwareUpdate`, `SMS_UpdateGroupAssignment`, `SMS_UpdateContentInfo`
- **Apps & Pakete:** `SMS_Application`, `SMS_DeploymentType`, `SMS_Package`, `SMS_Program`
- **Compliance:** `SMS_ConfigurationItem`, `SMS_Baseline`, `SMS_G_System_CI_ComplianceState`
- **Status / Health:** `SMS_StatusMessage`, `SMS_CH_ClientSummary`, `SMS_CombinedDeviceResources`
- **Site / Infra:** `SMS_Site`, `SMS_DistributionPoint`, `SMS_ManagementPoint`, `SMS_BoundaryGroup`, `SMS_Boundary`
- **Deployments:** `SMS_DeploymentInfo`, `SMS_DeploymentSummary`, `SMS_AppDeploymentAssetDetails`, `SMS_TaskSequenceDeploymentStatus`
- **Task Sequences:** `SMS_TaskSequencePackage`, `SMS_TaskSequenceStep`
- **Collections:** `SMS_Collection`, `SMS_CollectionRule`, `SMS_FullCollectionMembership`

Im **`v1.0/`-Namespace** sind die jeweils kuratierten/saubereren Pendants
(z.B. `v1.0/Device`, `v1.0/Collection`, `v1.0/Application`,
`v1.0/SoftwareUpdate`, `v1.0/Deployment`).

## Wiederkehrende Ablaeufe

### Pagination via `@odata.nextLink`

```mermaid
sequenceDiagram
    participant Caller as pwsh / Skript
    participant AS as AdminService

    Caller->>AS: GET /wmi/SMS_R_System?$top=1000
    AS-->>Caller: { value: [...], "@odata.nextLink": "..." }
    Note over Caller: alle 1000 ausgeben

    Caller->>AS: GET <@odata.nextLink>
    AS-->>Caller: { value: [...], "@odata.nextLink": "..." }
    Note over Caller: weitere ausgeben

    Caller->>AS: GET <letzter Link>
    AS-->>Caller: { value: [...] }
    Note over Caller: keine nextLink → fertig
```

Implementiert in `Invoke-AsPaged` in `_common.ps1`.

### Resolve-by-Name (Computer-Name → ResourceID → Detaildaten)

```mermaid
flowchart LR
    A[ComputerName z.B. PC123] --> B["GET wmi/SMS_R_System<br/>$filter=Name eq 'PC123'<br/>$select=ResourceID"]
    B --> C[ResourceID z.B. 16777345]
    C --> D["GET wmi/SMS_G_System_*<br/>$filter=ResourceID eq 16777345"]
    C --> E["GET wmi/SMS_FullCollectionMembership<br/>$filter=ResourceID eq 16777345"]
    C --> F["GET v1.0/Device(16777345)"]
```

`Resolve-ResourceId` in `_common.ps1` kapselt Schritt 1+2.

### Class-Discovery via `$metadata`

```mermaid
flowchart LR
    A["GET wmi/$metadata<br/>(XML/CSDL)"] --> B[Parse EDMX]
    B --> C[EntitySets = queryable Klassen]
    B --> D[EntityTypes = Property-Schemas]
    C --> E[Klassennamen filtern]
    D --> F[Properties pro Klasse listen]
```

Implementiert in `090-discover-classes.ps1`.

## Tipps fuer eigene Erweiterungen

- **Erst klein, dann breit:** mit `$top=1` testen, ob die Query syntaktisch
  passt, dann erst Pagination einsetzen.
- **Immer `$select` benutzen:** AdminService liefert sonst alle Felder —
  bei Hardware-Inventory-Klassen sind das schnell 50+ Spalten.
- **`$filter` mit `and`/`or`:** Operatoren `eq`, `ne`, `gt`, `lt`, `ge`, `le`,
  Funktionen `startswith`, `endswith`, `contains`, `year(x)`, `month(x)`.
- **Datetime in OData:** ISO-8601 mit `Z`, also
  `StartTime gt 2026-04-30T00:00:00Z`.
- **Property-Casing ist nicht konsistent:** ConfigMgr mischt
  `ResourceID`/`ResourceId`, `OperatingSystemNameandVersion` etc. Im Zweifel
  via `090-discover-classes.ps1 -ShowProperties` nachsehen.
- **Pagination-Hint:** Default-Page-Size variiert (typisch 1000). Wer auf
  alle Items angewiesen ist, MUSS `@odata.nextLink` folgen.
