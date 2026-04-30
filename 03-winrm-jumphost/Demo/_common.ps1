# Gemeinsame Initialisierung fuer Demo-Skripte (laufend auf dem Jumphost).
# In 5.1-compat-Stil (laeuft sowohl in Windows PowerShell 5.1 als auch in pwsh 7).
#
# Erwartete Env-Variablen:
#   CONFIGMGR_SITE_CODE   - z.B. P01
#   CONFIGMGR_SITE_SERVER - FQDN, Default: $(hostname)
#
# Voraussetzung: ConfigurationManager-Console oder Cmdlet-Package installiert.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:SiteCode = $env:CONFIGMGR_SITE_CODE
if (-not $script:SiteCode) {
    throw 'Bitte CONFIGMGR_SITE_CODE setzen, z.B. P01'
}

$script:SiteServer = if ($env:CONFIGMGR_SITE_SERVER) { $env:CONFIGMGR_SITE_SERVER } else { (hostname) }

if (-not (Get-Module -Name ConfigurationManager)) {
    $modulePath = if ($env:SMS_ADMIN_UI_PATH) {
        Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) 'ConfigurationManager.psd1'
    } else {
        # Fallback auf Standard-Console-Install
        'C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\ConfigurationManager.psd1'
    }
    if (-not (Test-Path $modulePath)) {
        throw "ConfigurationManager.psd1 nicht gefunden ($modulePath). Console installieren oder SMS_ADMIN_UI_PATH setzen."
    }
    Import-Module $modulePath
}

if (-not (Get-PSDrive -Name $script:SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $script:SiteCode -PSProvider CMSite -Root $script:SiteServer | Out-Null
}

# Demos arbeiten im CMSite-PSDrive
Set-Location "$($script:SiteCode):"

function Get-CMSiteWmiNamespace {
    "root\SMS\site_$($script:SiteCode)"
}

# Convenience: WMI/CIM-Query gegen den Site-Provider
function Invoke-CMWmiQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ClassName,
        [string] $Filter
    )
    $params = @{
        ComputerName = $script:SiteServer
        Namespace    = Get-CMSiteWmiNamespace
        ClassName    = $ClassName
    }
    if ($Filter) { $params.Filter = $Filter }
    Get-CimInstance @params
}
