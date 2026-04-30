<#
.SYNOPSIS
  Tour durch den /AdminService/v1.0/-Namespace (modeled REST-API).

.DESCRIPTION
  Der v1.0-Namespace stellt kuratierte, "modellierte" Resources bereit —
  weniger Felder, sauberere Struktur als das rohe `wmi/`-Mapping. Microsoft
  baut diesen Namespace mit jedem Release weiter aus.

  Das Service-Root-Dokument unter /v1.0/ listet die verfuegbaren
  EntitySets. Beispiel-Calls:
    /v1.0/Device                  - alle Devices (paginated)
    /v1.0/Device(<ResourceId>)    - einzelnes Device
    /v1.0/Collection              - alle Collections
    /v1.0/Application             - alle Apps

.EXAMPLE
  ./100-modeled-api.ps1
.EXAMPLE
  ./100-modeled-api.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [string] $ComputerName
)

. (Join-Path $PSScriptRoot '_common.ps1')

Write-Host '=== Service Root /v1.0/ ===' -ForegroundColor Cyan
$root = Invoke-As -Path 'v1.0/'
$root.value | Sort-Object name | Format-Table -AutoSize name, kind, url

Write-Host "`n=== Erste 5 Devices via /v1.0/Device ===" -ForegroundColor Cyan
$devs = (Invoke-As -Path 'v1.0/Device' -QueryString '$top=5').value
$devs | Format-Table -AutoSize MachineId, Name, ClientVersion, Domain, ADSiteName

if ($ComputerName) {
    Write-Host "`n=== Vollbild fuer $ComputerName ===" -ForegroundColor Cyan
    $rid = Resolve-ResourceId -ComputerName $ComputerName
    $dev = Invoke-As -Path "v1.0/Device($rid)"
    $dev | Format-List
}

Write-Host "`n=== Erste 3 Collections via /v1.0/Collection ===" -ForegroundColor Cyan
$cols = (Invoke-As -Path 'v1.0/Collection' -QueryString '$top=3').value
$cols | Format-Table -AutoSize CollectionId, Name, MemberCount, CollectionType
