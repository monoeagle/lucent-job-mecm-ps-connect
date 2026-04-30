<#
.SYNOPSIS
  Zeigt, in welchen Collections ein Device Mitglied ist.

.DESCRIPTION
  Zwei-Stufen-Resolve:
    1. ComputerName -> ResourceID via SMS_R_System
    2. SMS_FullCollectionMembership liefert CollectionIDs
    3. SMS_Collection enthaelt Name, Comment, MemberCount usw.
  Die letzten beiden Stufen werden hier zusammengefuehrt.

.EXAMPLE
  ./040-device-collections.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName
)

. (Join-Path $PSScriptRoot '_common.ps1')

$resourceId = Resolve-ResourceId -ComputerName $ComputerName

# Schritt 1: alle CollectionIDs in denen das Device Mitglied ist
$memberships = Invoke-AsPaged -Path 'wmi/SMS_FullCollectionMembership' `
    -QueryString "`$filter=ResourceID eq $resourceId&`$select=CollectionID"

$collectionIds = $memberships | Select-Object -ExpandProperty CollectionID -Unique
if (-not $collectionIds) {
    Write-Host "Device $ComputerName ist in keiner Collection." -ForegroundColor Yellow
    return
}

# Schritt 2: Collection-Stammdaten holen (in Batches via 'or')
$details = foreach ($id in $collectionIds) {
    (Invoke-As -Path 'wmi/SMS_Collection' `
        -QueryString "`$filter=CollectionID eq '$id'&`$select=CollectionID,Name,Comment,MemberCount,CollectionType").value
}

$details | Sort-Object Name |
    Select-Object CollectionID, Name, MemberCount, Comment |
    Format-Table -AutoSize
