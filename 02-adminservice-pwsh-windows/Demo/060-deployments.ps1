<#
.SYNOPSIS
  Listet Deployments — laufend und/oder zukuenftig geplant. (5.1-compat)

.DESCRIPTION
  5.1-Variante des gleichnamigen Skripts. Ersetzt den pwsh-7
  Null-Coalescing-Operator (??) durch ein if/else.

.EXAMPLE
  .\060-deployments.ps1 -Mode All
.EXAMPLE
  .\060-deployments.ps1 -Mode Future
#>
[CmdletBinding()]
param(
    [ValidateSet('Active', 'Future', 'All')] [string] $Mode = 'All',
    [int] $Top = 100
)

. (Join-Path $PSScriptRoot '_common.ps1')

$nowUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$filter = switch ($Mode) {
    'Active' { "StartTime le $nowUtc" }
    'Future' { "StartTime gt $nowUtc" }
    'All'    { $null }
}

$qs = "`$select=DeploymentID,DeploymentName,FeatureType,CollectionName,StartTime,DeploymentIntent&`$orderby=StartTime desc&`$top=$Top"
if ($filter) { $qs = "`$filter=$filter&" + $qs }

$rows = Invoke-AsPaged -Path 'wmi/SMS_DeploymentInfo' -QueryString $qs

$ftMap = @{ 1='App'; 2='Program'; 5='Update'; 6='Baseline'; 7='TaskSeq'; 8='Setting' }

$rows |
    Select-Object @{n='Type';
                    e={
                        $ft = [int]$_.FeatureType
                        if ($ftMap.ContainsKey($ft)) { $ftMap[$ft] } else { $ft }
                    }},
                  DeploymentName, CollectionName, StartTime, DeploymentIntent |
    Format-Table -AutoSize
