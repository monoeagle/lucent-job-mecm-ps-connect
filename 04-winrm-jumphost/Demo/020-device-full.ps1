<#
.SYNOPSIS
  Komplettsicht auf ein Device: Get-CMDevice + Hardware-Inventory via WMI.
.EXAMPLE
  .\020-device-full.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName
)

. (Join-Path $PSScriptRoot '_common.ps1')

$device = Get-CMDevice -Name $ComputerName -Fast
if (-not $device) { throw "Device '$ComputerName' nicht gefunden." }
$rid = $device.ResourceID

Write-Host "`n=== Stammdaten (Get-CMDevice) ===" -ForegroundColor Cyan
$device | Format-List Name, ResourceID, IsClient, ClientType, DeviceOS,
                       LastLogonUser, LastActiveTime, ADSiteName, Domain

$classes = @(
    'SMS_G_System_COMPUTER_SYSTEM',
    'SMS_G_System_OPERATING_SYSTEM',
    'SMS_G_System_PC_BIOS',
    'SMS_G_System_PROCESSOR',
    'SMS_G_System_LOGICAL_DISK'
)
foreach ($c in $classes) {
    Write-Host "`n=== $c ===" -ForegroundColor Yellow
    try {
        Invoke-CMWmiQuery -ClassName $c -Filter "ResourceID=$rid" | Format-List
    } catch {
        Write-Warning "  $($_.Exception.Message)"
    }
}
