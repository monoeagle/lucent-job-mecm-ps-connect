<#
.SYNOPSIS
  Client-Health-Summary — global, einzelnes Device oder nur unhealthy.
.EXAMPLE
  .\080-client-health.ps1
.EXAMPLE
  .\080-client-health.ps1 -ComputerName PC123
.EXAMPLE
  .\080-client-health.ps1 -OnlyUnhealthy
#>
[CmdletBinding()]
param(
    [string] $ComputerName,
    [switch] $OnlyUnhealthy,
    [int]    $Top = 200
)

. (Join-Path $PSScriptRoot '_common.ps1')

$conditions = @()
if ($ComputerName) {
    $rid = (Get-CMDevice -Name $ComputerName -Fast).ResourceID
    $conditions += "ResourceID=$rid"
}
if ($OnlyUnhealthy) {
    $conditions += 'ClientActiveStatus=0'
}
$filter = $conditions -join ' AND '

$rows = Invoke-CMWmiQuery -ClassName 'SMS_CH_ClientSummary' -Filter $filter

$rows | Sort-Object LastActiveTime -Descending | Select-Object -First $Top |
    Select-Object Name, ClientStateDescription,
        @{n='Active'; e={ if ($_.ClientActiveStatus -eq 1) { 'yes' } else { 'no' } }},
        LastActiveTime, LastHardwareScan, LastPolicyRequest |
    Format-Table -AutoSize
