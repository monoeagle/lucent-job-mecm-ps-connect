<#
.SYNOPSIS
  Collections, in denen ein Device Mitglied ist.

.EXAMPLE
  ./040-device-collections.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param([Parameter(Mandatory)] [string] $ComputerName)

. (Join-Path $PSScriptRoot '_common.ps1')

$rid = Resolve-ResourceId -ComputerName $ComputerName

Invoke-Sql "
    SELECT
        c.CollectionID,
        c.Name,
        c.MemberCount,
        LEFT(ISNULL(c.Comment, ''), 60) AS Comment
    FROM v_FullCollectionMembership m
    JOIN v_Collection c ON c.CollectionID = m.CollectionID
    WHERE m.ResourceID = $rid
    ORDER BY c.Name;" |
    Select-Object CollectionID, Name, MemberCount, Comment |
    Format-Table -AutoSize
