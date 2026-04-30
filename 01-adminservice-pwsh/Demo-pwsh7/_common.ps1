# Gemeinsame Auth- und Request-Helfer fuer alle Demo-Skripte.
# Wird per Dot-Sourcing geladen: . (Join-Path $PSScriptRoot '_common.ps1')
#
# Erwartete Env-Variablen:
#   CONFIGMGR_ADMINSERVICE_BASE  - z.B. https://sccm.corp.local/AdminService
#   CONFIGMGR_SKIP_CERT_CHECK    - 'true', um TLS-Validierung zu ueberspringen
#                                  (nur fuer Demos / Test-Umgebungen!)

$script:AsBase = $env:CONFIGMGR_ADMINSERVICE_BASE
if (-not $script:AsBase) {
    throw 'Bitte CONFIGMGR_ADMINSERVICE_BASE setzen, z.B. https://sccm.corp.local/AdminService'
}

$script:Irm = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/json' }
}
if ($env:CONFIGMGR_SKIP_CERT_CHECK -eq 'true') {
    $script:Irm.SkipCertificateCheck = $true
}

function Invoke-As {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string] $QueryString
    )
    $uri = "$script:AsBase/$Path"
    if ($QueryString) { $uri += "?$QueryString" }
    Write-Verbose "GET $uri"
    Invoke-RestMethod @script:Irm -Uri $uri
}

function Invoke-AsPaged {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string] $QueryString
    )
    $uri = "$script:AsBase/$Path"
    if ($QueryString) { $uri += "?$QueryString" }
    while ($uri) {
        Write-Verbose "GET $uri"
        $resp = Invoke-RestMethod @script:Irm -Uri $uri
        $resp.value
        $uri = $resp.'@odata.nextLink'
    }
}

function Resolve-ResourceId {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $ComputerName)
    $qs = "`$filter=Name eq '$ComputerName'&`$select=ResourceID"
    $row = (Invoke-As -Path 'wmi/SMS_R_System' -QueryString $qs).value | Select-Object -First 1
    if (-not $row) { throw "Device '$ComputerName' nicht gefunden." }
    $row.ResourceID
}
