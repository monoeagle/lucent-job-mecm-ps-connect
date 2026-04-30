<#
.SYNOPSIS
  Holt fuer ein Device die Stammdaten und ausgewaehlte Hardware-Inventory-
  Klassen aus dem AdminService.

.DESCRIPTION
  Zeigt, dass ein "Device" in ConfigMgr aus mehreren WMI-Klassen besteht:
    - SMS_R_System                       (Stammdaten/Discovery)
    - SMS_G_System_COMPUTER_SYSTEM       (Hersteller, Modell)
    - SMS_G_System_OPERATING_SYSTEM      (OS, Build, Boot-Time)
    - SMS_G_System_PC_BIOS               (BIOS, Serial)
    - SMS_G_System_PROCESSOR             (CPUs)
    - SMS_G_System_LOGICAL_DISK          (Disks/Volumes)
  Custom-Inventory in eurer Umgebung kann zusaetzliche SMS_G_System_*-Klassen
  liefern (siehe 090-discover-classes.ps1).

.EXAMPLE
  ./020-device-full.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName
)

. (Join-Path $PSScriptRoot '_common.ps1')

$resourceId = Resolve-ResourceId -ComputerName $ComputerName
Write-Host "ResourceID = $resourceId" -ForegroundColor Cyan

$classes = @(
    @{ Name = 'Stammdaten (SMS_R_System)';      Path = 'wmi/SMS_R_System';                Filter = "ResourceId eq $resourceId" }
    @{ Name = 'Computer System';                Path = 'wmi/SMS_G_System_COMPUTER_SYSTEM'; Filter = "ResourceID eq $resourceId" }
    @{ Name = 'Operating System';               Path = 'wmi/SMS_G_System_OPERATING_SYSTEM'; Filter = "ResourceID eq $resourceId" }
    @{ Name = 'BIOS';                           Path = 'wmi/SMS_G_System_PC_BIOS';         Filter = "ResourceID eq $resourceId" }
    @{ Name = 'Processor';                      Path = 'wmi/SMS_G_System_PROCESSOR';       Filter = "ResourceID eq $resourceId" }
    @{ Name = 'Logical Disks';                  Path = 'wmi/SMS_G_System_LOGICAL_DISK';    Filter = "ResourceID eq $resourceId" }
)

foreach ($c in $classes) {
    Write-Host "`n=== $($c.Name) ===" -ForegroundColor Yellow
    $qs = "`$filter=$($c.Filter)"
    try {
        $rows = (Invoke-As -Path $c.Path -QueryString $qs).value
        if ($rows) {
            $rows | Format-List
        } else {
            Write-Host '(keine Daten)' -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "  Klasse nicht abrufbar: $($_.Exception.Message)"
    }
}
