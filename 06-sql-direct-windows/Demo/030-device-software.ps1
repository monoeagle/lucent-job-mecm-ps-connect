<#
.SYNOPSIS
  Installierte Software eines Device aus v_GS_INSTALLED_SOFTWARE.

.EXAMPLE
  ./030-device-software.ps1 -ComputerName PC123
.EXAMPLE
  ./030-device-software.ps1 -ComputerName PC123 -Publisher Microsoft
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [string] $Publisher
)

. (Join-Path $PSScriptRoot '_common.ps1')

$rid   = Resolve-ResourceId -ComputerName $ComputerName
$where = "ResourceID = $rid"
if ($Publisher) { $where += " AND Publisher0 LIKE N'%$Publisher%'" }

Invoke-Sql "
    SELECT
        ProductName0,
        ProductVersion0,
        Publisher0,
        InstallDate0
    FROM v_GS_INSTALLED_SOFTWARE
    WHERE $where
    ORDER BY ProductName0;" |
    Select-Object @{n='ProductName';e={$_.ProductName0}},
                  @{n='Version';e={$_.ProductVersion0}},
                  @{n='Publisher';e={$_.Publisher0}},
                  @{n='InstallDate';e={$_.InstallDate0}} |
    Format-Table -AutoSize
