<#
.SYNOPSIS
  Listet Devices via Get-CMDevice.
.EXAMPLE
  .\010-list-devices.ps1
.EXAMPLE
  .\010-list-devices.ps1 -NameFilter PC -Top 50
#>
[CmdletBinding()]
param(
    [string] $NameFilter,
    [int]    $Top = 50
)

. (Join-Path $PSScriptRoot '_common.ps1')

$all = Get-CMDevice -Fast
if ($NameFilter) {
    $all = $all | Where-Object { $_.Name -like "*$NameFilter*" }
}
$all | Sort-Object Name | Select-Object -First $Top |
    Format-Table Name, ResourceID, IsClient, ClientType, DeviceOS, LastLogonUser -AutoSize
