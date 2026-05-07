# 04 — WinRM-Jumphost mit ConfigurationManager-Modul

Wenn AdminService nicht aktiviert ist oder das CM-Modul mit den vollen Cmdlets
benötigt wird (z.B. `Get-CMDeviceCollectionMembership`-Logik), nutzt der
Linux-Runner pwsh-Remoting, um auf einem Windows-Jumphost ein Skript
auszuführen, das die CM-Console-DLLs lädt.

## Voraussetzungen

- pwsh 7 auf dem Linux-Runner
- Windows-Jumphost mit installierter ConfigMgr-Admin-Console
- WinRM HTTPS auf Jumphost konfiguriert, Port 5986 erreichbar
- Service-Account mit Read-Rechten in ConfigMgr, vorab via Kerberos angemeldet
  (Linux: `kinit -kt …`)

## Dateien

- `Wait-ConfigMgrDeployed.ps1` — läuft auf dem Runner, baut die WinRM-Session auf
- `jumphost/Get-ConfigMgrStatus.ps1` — wird auf den Jumphost übertragen und ausgeführt
- `main.tf`

## Aufruf manuell

```bash
pwsh ./Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -Jumphost cmjump01.corp.local -SiteCode P01
```

## Demo-Skripte

10 Skripte unter [`Demo/`](Demo/) zeigen was sich ueber die
ConfigurationManager-Cmdlets abfragen laesst (Devices, Hardware-/Software-
Inventory, Collections, Deployments, Task-Sequence-Status, Client-Health,
Cmdlet-Discovery, DPs/MPs/Boundaries). Siehe [`Demo/Übersicht.md`](Demo/Übersicht.md).

Die Skripte sind 5.1-kompatibel und laufen direkt auf dem Jumphost.

## Windows PowerShell 5.1

5.1-kompatible Variante des Wait-Skripts unter
[`windows-pwsh5/`](windows-pwsh5/README.md). Die Jumphost-Skripte
selbst sind ohnehin 5.1-kompatibel.

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source        = "../../04-winrm-jumphost"
  computer_name = "PC123"
  jumphost      = "cmjump01.corp.local"
  site_code     = "P01"
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).
