<#
.SYNOPSIS
  Listet Devices aus v_R_System mit optionalem Filter und Pagination.

.EXAMPLE
  ./010-list-devices.ps1
.EXAMPLE
  ./010-list-devices.ps1 -NameFilter 'PC' -Top 200
#>
[CmdletBinding()]
param(
    [string] $NameFilter,
    [int]    $Top = 50
)

. (Join-Path $PSScriptRoot '_common.ps1')

$where = if ($NameFilter) { "WHERE Name0 LIKE N'%$NameFilter%'" } else { '' }

Invoke-Sql "
    SELECT TOP $Top
        Name0,
        ResourceID,
        Client0,
        Full_Domain_Name0,
        User_Name0,
        Operating_System_Name_and0
    FROM v_R_System
    $where
    ORDER BY Name0;" |
    Select-Object @{n='Name';e={$_.Name0}},
                  ResourceID,
                  @{n='Client';e={$_.Client0}},
                  @{n='Domain';e={$_.Full_Domain_Name0}},
                  @{n='LastLogonUser';e={$_.User_Name0}},
                  @{n='OS';e={$_.Operating_System_Name_and0}} |
    Format-Table -AutoSize
