<#
.SYNOPSIS
  Kombiniert Stammdaten und Hardware-Inventory eines Device.

.EXAMPLE
  ./020-device-full.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param([Parameter(Mandatory)] [string] $ComputerName)

. (Join-Path $PSScriptRoot '_common.ps1')

$rid = Resolve-ResourceId -ComputerName $ComputerName
Write-Host "ResourceID = $rid" -ForegroundColor Cyan

function Show-View {
    param([string]$Label, [string]$View, [string]$Cols = '*')
    Write-Host "`n=== $Label ($View) ===" -ForegroundColor Yellow
    try {
        $rows = Invoke-Sql "SELECT $Cols FROM $View WHERE ResourceID = $rid"
        if ($rows) { $rows | Format-List } else { Write-Host '(keine Daten)' -ForegroundColor DarkGray }
    } catch {
        Write-Warning "Klasse nicht abrufbar: $($_.Exception.Message)"
    }
}

Show-View 'Stammdaten'       'v_R_System'             'Name0, ResourceID, Client0, Full_Domain_Name0, User_Name0, AD_Site_Name0, Operating_System_Name_and0'
Show-View 'Computer System'  'v_GS_COMPUTER_SYSTEM'   'Manufacturer0, Model0, SystemType0, NumberOfProcessors0, TotalPhysicalMemory0'
Show-View 'Operating System' 'v_GS_OPERATING_SYSTEM'  'Caption0, Version0, BuildNumber0, InstallDate0, LastBootUpTime0'
Show-View 'BIOS'             'v_GS_PC_BIOS'           'Manufacturer0, SMBIOSBIOSVersion0, ReleaseDate0, SerialNumber0'
Show-View 'Processor'        'v_GS_PROCESSOR'         'Name0, NumberOfCores0, NumberOfLogicalProcessors0, MaxClockSpeed0'
Show-View 'Logical Disks'    'v_GS_LOGICAL_DISK'      'DeviceID0, FileSystem0, Size0, FreeSpace0'
