<#
.SYNOPSIS
  Listet alle verfuegbaren Klassen/Endpoints des AdminService aus dem
  OData-$metadata-Dokument.

.DESCRIPTION
  Der AdminService stellt unter /AdminService/wmi/$metadata ein CSDL/EDMX-
  XML-Dokument bereit, das alle EntitySets (= queryable Klassen) auflistet.
  Damit findest du heraus, welche `SMS_*`- und `SMS_G_System_*`-Klassen in
  EURER Site verfuegbar sind — inklusive eventuell custom-erweiterter
  Hardware-Inventory-Klassen.

.EXAMPLE
  ./090-discover-classes.ps1
.EXAMPLE
  ./090-discover-classes.ps1 -Pattern 'SMS_G_System_' -ShowProperties
#>
[CmdletBinding()]
param(
    [string] $Pattern,
    [switch] $ShowProperties
)

. (Join-Path $PSScriptRoot '_common.ps1')

# $metadata gibt XML zurueck — eigener Aufruf ohne JSON-Header
$rawArgs = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/xml' }
}
if ($env:CONFIGMGR_SKIP_CERT_CHECK -eq 'true') { $rawArgs.SkipCertificateCheck = $true }

$metadataUri = "$script:AsBase/wmi/`$metadata"
[xml]$xml = Invoke-RestMethod @rawArgs -Uri $metadataUri

$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('edmx', 'http://docs.oasis-open.org/odata/ns/edmx')
$ns.AddNamespace('edm',  'http://docs.oasis-open.org/odata/ns/edm')

$entitySets = $xml.SelectNodes('//edm:EntityContainer/edm:EntitySet', $ns)

$rows = foreach ($es in $entitySets) {
    if ($Pattern -and $es.Name -notmatch $Pattern) { continue }
    [pscustomobject]@{
        Name       = $es.Name
        EntityType = ($es.EntityType -replace '^.*\.', '')
    }
}

Write-Host "Gefundene EntitySets: $($rows.Count)" -ForegroundColor Cyan
$rows | Sort-Object Name | Format-Table -AutoSize

if ($ShowProperties) {
    Write-Host "`n--- Properties pro EntityType ---" -ForegroundColor Yellow
    foreach ($r in ($rows | Sort-Object Name)) {
        $type = $xml.SelectSingleNode("//edm:EntityType[@Name='$($r.EntityType)']", $ns)
        if (-not $type) { continue }
        $props = $type.SelectNodes('edm:Property', $ns) | ForEach-Object { $_.Name }
        Write-Host "`n$($r.Name) ($($r.EntityType)):"
        Write-Host ('  ' + ($props -join ', '))
    }
}
