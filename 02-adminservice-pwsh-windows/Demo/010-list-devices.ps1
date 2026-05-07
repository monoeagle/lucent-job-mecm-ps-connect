<#
.SYNOPSIS
  Listet Devices aus SMS_R_System mit Filter, Sortierung und Pagination.

.DESCRIPTION
  Demonstriert die OData-Operatoren $filter, $select, $orderby, $top und das
  Folgen von @odata.nextLink fuer Pagination.

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

$select  = '$select=ResourceID,Name,Client,Domain,LastLogonUserName,LastLogonTimestamp,OperatingSystemNameandVersion'
$orderby = '$orderby=Name'
$topQs   = "`$top=$Top"
$filter  = if ($NameFilter) { "`$filter=startswith(Name,'$NameFilter')" } else { $null }

$qs = @($select, $orderby, $topQs, $filter | Where-Object { $_ }) -join '&'

Invoke-AsPaged -Path 'wmi/SMS_R_System' -QueryString $qs |
    Select-Object Name, ResourceID, Client, Domain, LastLogonUserName, OperatingSystemNameandVersion |
    Format-Table -AutoSize
