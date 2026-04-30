# Einmaliges Setup-Skript für den Windows-Host
# Prüft Package, registriert PSDrive testweise, validiert Cmdlet-Verfügbarkeit
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $CmdletPath,
    [Parameter(Mandatory)] [string] $SiteCode,
    [Parameter(Mandatory)] [string] $SiteServer
)

$ErrorActionPreference = 'Stop'

$modulePsd1 = Join-Path $CmdletPath 'ConfigurationManager.psd1'
if (-not (Test-Path $modulePsd1)) {
    throw "ConfigurationManager.psd1 nicht gefunden unter $CmdletPath"
}

Import-Module $modulePsd1
$env:SMS_ADMIN_UI_PATH = $CmdletPath

if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer | Out-Null
    Write-Host "PSDrive $SiteCode: registriert (Root=$SiteServer)"
}

Push-Location "${SiteCode}:"
try {
    $modules = Get-Module -All | Where-Object Name -like '*ConfigurationManager*'
    Write-Host 'Geladene Module:'
    $modules | Format-Table ModuleType, Version, Name -AutoSize

    Write-Host "`nTest-Query:"
    Get-CMSite | Format-Table SiteCode, SiteName, Version, BuildNumber -AutoSize
}
finally {
    Pop-Location
}

Write-Host "`nSetup ok — Get-ConfigMgrStatus.ps1 kann jetzt remote aufgerufen werden."
