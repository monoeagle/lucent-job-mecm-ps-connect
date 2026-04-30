# 03 — WinRM-Jumphost mit ConfigurationManager-Modul

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

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source        = "../../03-winrm-jumphost"
  computer_name = "PC123"
  jumphost      = "cmjump01.corp.local"
  site_code     = "P01"
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).
