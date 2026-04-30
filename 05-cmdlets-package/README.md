# 05 — Cmdlet-Package via WinRM

Wie Variante 03 (Linux → WinRM → Windows-Host mit `ConfigurationManager`-
Modul), **aber ohne vollständige ConfigMgr-Admin-Console-Installation auf dem
Windows-Host**. Stattdessen wird ein vorab exportiertes Cmdlet-Package
bereitgestellt und via Pfad-/Env-Variable geladen.

## Wann sinnvoll

- Wenn der Windows-Hop ein schlanker Server / eine VM ist, auf dem keine
  Console-Installation gewünscht ist (Lifecycle, Patching, Footprint)
- Wenn mehrere Worker den Cmdlet-Zugriff brauchen — Package einmal
  bereitstellen statt n× Console installieren
- Wenn die Console-MSI nicht beschafft/verteilt werden kann, das Package
  aber existiert

## Voraussetzungen

- pwsh 7 auf dem Linux-Runner
- Windows-Host (Server oder Worker-VM) mit:
  - WinRM HTTPS auf 5986 erreichbar
  - PowerShell 5.1 oder 7
  - Cmdlet-Package entpackt unter z.B. `C:\Tools\PSCMDLets\`
- Service-Account mit ConfigMgr-RBAC (mind. Read-only Analyst)

## Cmdlet-Package herstellen

Microsoft liefert das Package nicht offiziell als Standalone-Download.
Zwei etablierte Wege:

1. **Selbst erzeugen** vom Site-Server / einem Host mit installierter Console:
   - Skript von Garry Smith (garytown):
     [`CreateCMPowerShellModulePackage.ps1`](https://github.com/gwblok/garytown/blob/master/CreateCMPowerShellModulePackage.ps1)
   - Hintergrund-Artikel:
     [garytown.com/configmgr-powershell-module-package](https://garytown.com/configmgr-powershell-module-package)
2. **Manuell aus dem Console-Install-Verzeichnis kopieren**: Inhalt von
   `…\AdminUI\bin\` einsammeln (siehe garrettyamada-Artikel unten).

Resultat: ein Ordner (oder ZIP), in unserem Beispiel `C:\Tools\PSCMDLets\`,
der u.a. enthält:
- `ConfigurationManager.psd1`
- `ConfigurationManager.psm1`
- DLLs (`AdminUI.PS.*.dll`, `Microsoft.ConfigurationManagement.*`)

## Setup auf dem Windows-Host (einmalig)

Siehe [`windows/Setup-CmdletPackage.ps1`](windows/Setup-CmdletPackage.ps1) —
prüft Package, registriert PSDrive, validiert Verbindung.

## Dateien

- `Wait-ConfigMgrDeployed.ps1` — läuft auf Linux-Runner, baut WinRM-Session
- `windows/Get-ConfigMgrStatus.ps1` — auf Windows-Host ausgeführt; lädt Modul
  per Pfad statt aus Console-Install
- `windows/Setup-CmdletPackage.ps1` — One-time-Prep auf dem Windows-Host
- `main.tf` — Tofu-Beispiel

## Aufruf manuell

```bash
pwsh ./Wait-ConfigMgrDeployed.ps1 \
    -ComputerName <PC> \
    -WindowsHost <fqdn-des-windows-worker> \
    -SiteCode <SiteCode> \
    -SiteServer <sms-provider-fqdn> \
    -CmdletPath 'C:\Tools\PSCMDLets'
```

## Referenzen

- [Microsoft ConfigurationManager Cmdlet Reference](https://learn.microsoft.com/en-us/powershell/module/configurationmanager/?view=sccm-ps)
- [garytown — ConfigMgr PowerShell Module Package](https://garytown.com/configmgr-powershell-module-package)
- [garrettyamada — Connecting to SCCM using PowerShell](https://garrettyamada.com/posts/connecting-to-sccm-using-powershell)

## Windows PowerShell 5.1

5.1-kompatible Variante des Wait-Skripts unter
[`windows-pwsh5/`](windows-pwsh5/README.md). Die Windows-Host-Skripte
in `windows/` sind ohnehin 5.1-kompatibel.

## Als Tofu-Modul verwenden

```hcl
module "wait_for_pc" {
  source        = "../../05-cmdlets-package"
  computer_name = "PC123"
  windows_host  = "cmworker01.corp.local"
  site_code     = "P01"
  site_server   = "sccm.corp.local"
  cmdlet_path   = "C:\\Tools\\PSCMDLets"   # default
}
```

Komplettes Beispiel: [`examples/basic-wait`](../examples/basic-wait).

## Unterschied zu Variante 03

| Aspekt | 03 (Console-Install) | 05 (Cmdlet-Package) |
|---|---|---|
| Windows-Host-Setup | MSI-Install der Console | Ordner kopieren |
| Software-Lifecycle | MS-Update-Pfad | manuell aktualisiertes Package |
| Footprint | volles Console-UI + Module | nur PowerShell-Module + DLLs |
| Microsoft-Support | offiziell | semi-offiziell (Package nicht offiziell distribuiert) |
| Cmdlet-Funktionalität | identisch | identisch |
