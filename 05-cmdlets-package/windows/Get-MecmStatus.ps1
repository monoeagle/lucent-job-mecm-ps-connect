param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $SiteCode,
    [Parameter(Mandatory)] [string] $SiteServer,
    [Parameter(Mandatory)] [string] $CmdletPath
)

# Modul aus dem Package-Ordner laden — nicht aus Console-Install-Pfad
$modulePsd1 = Join-Path $CmdletPath 'ConfigurationManager.psd1'
if (-not (Test-Path $modulePsd1)) {
    throw "Cmdlet-Package nicht gefunden unter $modulePsd1"
}
Import-Module $modulePsd1 -ErrorAction Stop

# Manche Cmdlets prüfen diese Env-Var beim Start
$env:SMS_ADMIN_UI_PATH = $CmdletPath

if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer | Out-Null
}

Push-Location "${SiteCode}:"
try {
    $device = Get-CMDevice -Name $ComputerName -Fast
    if (-not $device) {
        return [pscustomobject]@{ Found = $false; ClientReady = $false; TsSucceeded = $false }
    }

    $tsHistory = Get-CMDeploymentStatus -DeviceName $ComputerName -ErrorAction SilentlyContinue |
        Where-Object FeatureType -eq 7 |
        Sort-Object StatusTime -Descending |
        Select-Object -First 1

    [pscustomobject]@{
        Found       = $true
        ClientReady = ($device.IsClient -eq $true)
        TsSucceeded = ($tsHistory.StatusType -eq 5)
        ResourceID  = $device.ResourceID
    }
}
finally {
    Pop-Location
}
