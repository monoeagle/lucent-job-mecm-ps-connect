<#
.SYNOPSIS
  Listet alle Member einer Collection.

.DESCRIPTION
  Resolve Collection-Name zu CollectionID, dann SMS_FullCollectionMembership
  filtern. Demonstriert Pagination, da grosse Collections viele Member haben.

.EXAMPLE
  ./050-collection-members.ps1 -CollectionName 'All Workstations'
.EXAMPLE
  ./050-collection-members.ps1 -CollectionId 'SMS00001'
#>
[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByName')]   [string] $CollectionName,
    [Parameter(Mandatory, ParameterSetName = 'ById')]     [string] $CollectionId
)

. (Join-Path $PSScriptRoot '_common.ps1')

if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $col = (Invoke-As -Path 'wmi/SMS_Collection' `
        -QueryString "`$filter=Name eq '$CollectionName'&`$select=CollectionID,Name,MemberCount").value |
        Select-Object -First 1
    if (-not $col) { throw "Collection '$CollectionName' nicht gefunden." }
    $CollectionId = $col.CollectionID
    Write-Host "Collection '$($col.Name)' ($CollectionId) — $($col.MemberCount) Member" -ForegroundColor Cyan
}

$qs = "`$filter=CollectionID eq '$CollectionId'&`$select=ResourceID,Name,Domain,SMSID,IsClient,IsActive&`$orderby=Name"
Invoke-AsPaged -Path 'wmi/SMS_FullCollectionMembership' -QueryString $qs |
    Select-Object Name, ResourceID, Domain, IsClient, IsActive |
    Format-Table -AutoSize
