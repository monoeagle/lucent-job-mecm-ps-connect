<#
.SYNOPSIS
  Zeigt Task-Sequence-Deployment-Status. (5.1-compat)

.DESCRIPTION
  5.1-Variante des gleichnamigen Skripts. Ersetzt den pwsh-7
  Null-Coalescing-Operator (??) durch ein if/else.

  StatusType:
    1 = Compliant      2 = NonCompliant      3 = Failed
    4 = Unknown        5 = Success

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

$filter = $null
if ($ComputerName) {
    $rid = Resolve-ResourceId -ComputerName $ComputerName
    $filter = "ResourceID eq $rid"
}

$qs = "`$select=ResourceID,DeviceName,PackageID,AdvertisementID,StatusType,LastStatusMessageID,StatusTime"
$qs += "&`$orderby=StatusTime desc&`$top=$Top"
if ($filter) { $qs = "`$filter=$filter&" + $qs }

$statusMap = @{ 1='Compliant'; 2='NonCompliant'; 3='Failed'; 4='Unknown'; 5='Success' }

Invoke-AsPaged -Path 'wmi/SMS_TaskSequenceDeploymentStatus' -QueryString $qs |
    Select-Object DeviceName, PackageID, AdvertisementID,
                  @{n='Status';
                    e={
                        $s = [int]$_.StatusType
                        if ($statusMap.ContainsKey($s)) { $statusMap[$s] } else { $s }
                    }},
                  LastStatusMessageID, StatusTime |
    Format-Table -AutoSize
