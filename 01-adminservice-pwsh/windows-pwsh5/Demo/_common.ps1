# _common.ps1 (Windows PowerShell 5.1 compat)
#
# Wird in jedem Demo-Skript per Dot-Sourcing geladen.
# Aenderungen ggue. pwsh-7-Version:
#   - TLS 1.2 wird explizit eingeschaltet (5.1-Default ist Tls10/11)
#   - Skip-Cert via ServicePointManager-Callback (5.1 kennt kein
#     -SkipCertificateCheck)

$script:AsBase = $env:CONFIGMGR_ADMINSERVICE_BASE
if (-not $script:AsBase) {
    throw 'Bitte CONFIGMGR_ADMINSERVICE_BASE setzen, z.B. https://sccm.corp.local/AdminService'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($env:CONFIGMGR_SKIP_CERT_CHECK -eq 'true') {
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

$script:Irm = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/json' }
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
