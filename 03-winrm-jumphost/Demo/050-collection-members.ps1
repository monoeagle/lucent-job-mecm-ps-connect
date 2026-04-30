<#
.SYNOPSIS
  Members einer Collection.
.EXAMPLE
  .\050-collection-members.ps1 -CollectionName 'All Workstations'
.EXAMPLE
  .\050-collection-members.ps1 -CollectionId SMS00001
#>
[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByName')] [string] $CollectionName,
    [Parameter(Mandatory, ParameterSetName = 'ById')]   [string] $CollectionId
)

. (Join-Path $PSScriptRoot '_common.ps1')

$col = if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    Get-CMCollection -Name $CollectionName
} else {
    Get-CMCollection -CollectionId $CollectionId
}
if (-not $col) { throw "Collection nicht gefunden." }

Write-Host "Collection: $($col.Name) ($($col.CollectionID)) — $($col.MemberCount) Member" -ForegroundColor Cyan

Get-CMCollectionMember -CollectionId $col.CollectionID |
    Sort-Object Name |
    Format-Table Name, ResourceID, Domain, IsClient, IsActive -AutoSize
