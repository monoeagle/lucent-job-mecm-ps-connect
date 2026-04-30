<#
.SYNOPSIS
  Listet die installierte Software fuer ein Device aus dem Software-
  Inventory.

.DESCRIPTION
  Nutzt SMS_G_System_INSTALLED_SOFTWARE. Diese Klasse wird vom Software-
  Inventory-Agent gefuellt (sofern aktiviert). Alternative bei reinem
  Hardware-Inventory: SMS_G_System_ADD_REMOVE_PROGRAMS.

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

$resourceId = Resolve-ResourceId -ComputerName $ComputerName

$filter = "ResourceID eq $resourceId"
if ($Publisher) {
    $filter += " and contains(Publisher,'$Publisher')"
}
$qs = "`$filter=$filter&`$select=ProductName,ProductVersion,Publisher,InstallDate&`$orderby=ProductName"

Invoke-AsPaged -Path 'wmi/SMS_G_System_INSTALLED_SOFTWARE' -QueryString $qs |
    Select-Object ProductName, ProductVersion, Publisher, InstallDate |
    Format-Table -AutoSize
