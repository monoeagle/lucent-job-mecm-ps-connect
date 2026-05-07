<#
.SYNOPSIS
  Members einer Collection — per Name oder CollectionID.

.EXAMPLE
  ./050-collection-members.ps1 -CollectionName 'All Workstations'
.EXAMPLE
  ./050-collection-members.ps1 -CollectionId SMS00001
#>
[CmdletBinding(DefaultParameterSetName='ByName')]
param(
    [Parameter(Mandatory, ParameterSetName='ByName')]  [string] $CollectionName,
    [Parameter(Mandatory, ParameterSetName='ById')]    [string] $CollectionId
)

. (Join-Path $PSScriptRoot '_common.ps1')

if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $row = Invoke-Sql "SELECT TOP 1 CollectionID FROM v_Collection WHERE Name = N'$CollectionName'"
    if (-not $row) { throw "Collection '$CollectionName' nicht gefunden." }
    $CollectionId = $row.CollectionID
    Write-Host "Collection '$CollectionName' = $CollectionId" -ForegroundColor Cyan
}

Invoke-Sql "
    SELECT
        s.Name0,
        s.ResourceID,
        s.Full_Domain_Name0,
        s.Client0,
        s.User_Name0
    FROM v_FullCollectionMembership m
    JOIN v_R_System s ON s.ResourceID = m.ResourceID
    WHERE m.CollectionID = '$CollectionId'
    ORDER BY s.Name0;" |
    Select-Object @{n='Name';e={$_.Name0}},
                  ResourceID,
                  @{n='Domain';e={$_.Full_Domain_Name0}},
                  @{n='IsClient';e={$_.Client0}},
                  @{n='LastLogonUser';e={$_.User_Name0}} |
    Format-Table -AutoSize
