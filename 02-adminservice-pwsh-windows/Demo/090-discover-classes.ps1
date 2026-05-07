<#
.SYNOPSIS
  Listet alle EntitySets (= queryable Klassen) des AdminService aus dem
  $metadata-Dokument. (5.1-compat)

.DESCRIPTION
  5.1-Variante: Skip-Cert via ServicePointManager-Callback statt
  -SkipCertificateCheck. TLS-1.2 wird explizit eingeschaltet.
  Ansonsten identisch zur pwsh-7-Version.

.EXAMPLE
  .\090-discover-classes.ps1
.EXAMPLE
  .\090-discover-classes.ps1 -Pattern 'SMS_G_System_' -ShowProperties
#>
[CmdletBinding()]
param(
    [string] $Pattern,
    [switch] $ShowProperties
)

. (Join-Path $PSScriptRoot '_common.ps1')

# eigener Aufruf mit XML-Accept (sourcing oben hat schon TLS/Skip-Cert gesetzt)
$rawArgs = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/xml' }
}

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
