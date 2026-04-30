<#
.SYNOPSIS
  Task-Sequence-Deployment-Status — global oder fuer ein Device.
.EXAMPLE
  .\070-task-sequence-status.ps1
.EXAMPLE
  .\070-task-sequence-status.ps1 -ComputerName PC123
#>
[CmdletBinding()]
param(
    [string] $ComputerName,
    [int]    $Top = 100
)

. (Join-Path $PSScriptRoot '_common.ps1')

# FeatureType 7 = Task Sequence
$params = @{
    FeatureType = 'TaskSequence'
}
if ($ComputerName) {
    $params.DeviceName = $ComputerName
}

$status = Get-CMDeploymentStatus @params -ErrorAction SilentlyContinue |
    Sort-Object StatusTime -Descending |
    Select-Object -First $Top

# StatusType 1=Compliant, 2=NonCompliant, 3=Failed, 4=Unknown, 5=Success
$statusMap = @{ 1='Compliant'; 2='NonCompliant'; 3='Failed'; 4='Unknown'; 5='Success' }

$status | Select-Object DeviceName, PackageID, AdvertisementID,
    @{n='Status'; e={
        $s = [int]$_.StatusType
        if ($statusMap.ContainsKey($s)) { $statusMap[$s] } else { $s }
    }},
    LastStatusMessageID, StatusTime |
    Format-Table -AutoSize
