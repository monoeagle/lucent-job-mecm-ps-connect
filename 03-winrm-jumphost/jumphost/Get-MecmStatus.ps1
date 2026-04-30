param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $SiteCode
)

# Console-Modul laden (Pfad wird per Env-Var von der Console gesetzt)
$modulePath = Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) 'ConfigurationManager.psd1'
Import-Module $modulePath -ErrorAction Stop

$drive = "${SiteCode}:"
if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root (hostname) | Out-Null
}
Push-Location $drive
try {
    $device = Get-CMDevice -Name $ComputerName -Fast
    if (-not $device) {
        return [pscustomobject]@{ Found = $false; ClientReady = $false; TsSucceeded = $false }
    }

    $tsHistory = Get-CMDeploymentStatus -DeviceName $ComputerName -ErrorAction SilentlyContinue |
        Where-Object FeatureType -eq 7 |   # 7 = Task Sequence
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
