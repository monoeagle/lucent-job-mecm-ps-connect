<#
.SYNOPSIS
  Installierte Software fuer ein Device aus dem Software-Inventory.
.EXAMPLE
  .\030-device-software.ps1 -ComputerName PC123
.EXAMPLE
  .\030-device-software.ps1 -ComputerName PC123 -Publisher Microsoft
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [string] $Publisher
)

. (Join-Path $PSScriptRoot '_common.ps1')

$rid = (Get-CMDevice -Name $ComputerName -Fast).ResourceID
if (-not $rid) { throw "Device nicht gefunden." }

$filter = "ResourceID=$rid"
if ($Publisher) { $filter += " AND Publisher LIKE '%$Publisher%'" }

Invoke-CMWmiQuery -ClassName 'SMS_G_System_INSTALLED_SOFTWARE' -Filter $filter |
    Sort-Object ProductName |
    Format-Table ProductName, ProductVersion, Publisher, InstallDate -AutoSize
