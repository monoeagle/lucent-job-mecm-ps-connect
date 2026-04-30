<#
.SYNOPSIS
  Welche Collections enthalten ein Device.
.DESCRIPTION
  Resolve ueber WMI-Klasse SMS_FullCollectionMembership (deutlich
  schneller als Get-CMCollection | ForEach Get-CMCollectionMember).
.EXAMPLE
  .\040-device-collections.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName
)

. (Join-Path $PSScriptRoot '_common.ps1')

$rid = (Get-CMDevice -Name $ComputerName -Fast).ResourceID
if (-not $rid) { throw "Device nicht gefunden." }

$memberships = Invoke-CMWmiQuery -ClassName 'SMS_FullCollectionMembership' `
    -Filter "ResourceID=$rid"

$rows = foreach ($m in $memberships) {
    $col = Get-CMCollection -CollectionId $m.CollectionID
    [pscustomobject]@{
        CollectionID = $col.CollectionID
        Name         = $col.Name
        MemberCount  = $col.MemberCount
        Comment      = $col.Comment
    }
}
$rows | Sort-Object Name | Format-Table -AutoSize
