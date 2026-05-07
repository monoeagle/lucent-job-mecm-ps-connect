# Demo-Skripte — Cmdlet-Package

Variante 07 nutzt **dieselben ConfigurationManager-Cmdlets** wie Variante 04,
nur mit anderem Setup (Cmdlet-Package geladen statt voller Console-Install).
Die Demo-Skripte sind deshalb **identisch** und liegen in
[`../04-winrm-jumphost/Demo/`](../../04-winrm-jumphost/Demo).

## Setup vor Demo-Aufruf

Auf dem Windows-Host (einmalig pro Session):

```powershell
# 1. Cmdlet-Package laden
& "$PSScriptRoot\..\windows\Setup-CmdletPackage.ps1" `
    -CmdletPath  'C:\Tools\PSCMDLets' `
    -SiteCode    'P01' `
    -SiteServer  'sccm.corp.local'

# 2. Env-Variablen setzen (gleich wie 03):
$env:CONFIGMGR_SITE_CODE   = 'P01'
$env:CONFIGMGR_SITE_SERVER = 'sccm.corp.local'

# 3. Demos aus 03/Demo/ aufrufen:
& "..\..\04-winrm-jumphost\Demo\010-list-devices.ps1"
& "..\..\04-winrm-jumphost\Demo\020-device-full.ps1" -ComputerName PC123
# ...
```

## Warum keine eigenen Demos?

Die Cmdlet-API ist nach Setup-Schritt 1 voellig identisch — Duplizieren
brachte nur Maintenance-Schmerz. Die einzige Sub-Variante ist der
Initial-Load in Schritt 1: in 04 macht das die installierte Console
implizit, in 07 expliziterweise das `Setup-CmdletPackage.ps1`.

## Wenn lokale Demo-Kopien gewuenscht sind

Optionaler Convenience-Ordner kann angelegt werden:

```powershell
# Einmalig:
mkdir Demo\local
Copy-Item ..\..\04-winrm-jumphost\Demo\*.ps1 Demo\local\
# Danach setzen + sourcen wie oben, aufrufen aus Demo\local\
```

Die Wartung liegt dann bei dir — denke an Sync, wenn 03/Demo/ sich aendert.
