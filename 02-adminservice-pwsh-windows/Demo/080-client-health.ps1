<#
.SYNOPSIS
  Client-Health-Summary aller oder eines Devices.

.DESCRIPTION
  SMS_CH_ClientSummary aggregiert Heartbeat-, Hardware-Inventory-, Software-
  Inventory-, Status-Message- und Policy-Health auf Device-Ebene.
  Spalten wie LastActiveTime, LastOnline, ClientStateDescription geben
  einen schnellen Ueberblick ueber problematische Clients.

.EXAMPLE
  ./080-client-health.ps1
.EXAMPLE
  ./080-client-health.ps1 -ComputerName PC123
.EXAMPLE
  ./080-client-health.ps1 -OnlyUnhealthy
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
    $rid = Resolve-ResourceId -ComputerName $ComputerName
    $conditions += "ResourceID eq $rid"
}
if ($OnlyUnhealthy) {
    # ClientActiveStatus=0 -> Inactive
    $conditions += 'ClientActiveStatus eq 0'
}

$qs = "`$select=ResourceID,Name,ClientActiveStatus,ClientStateDescription,LastActiveTime,LastOnline,LastHardwareScan,LastPolicyRequest"
$qs += "&`$orderby=LastActiveTime desc&`$top=$Top"
if ($conditions) { $qs = "`$filter=" + ($conditions -join ' and ') + "&" + $qs }

Invoke-AsPaged -Path 'wmi/SMS_CH_ClientSummary' -QueryString $qs |
    Select-Object Name, ClientStateDescription,
                  @{n='Active'; e={if ($_.ClientActiveStatus -eq 1) {'yes'} else {'no'}}},
                  LastActiveTime, LastHardwareScan, LastPolicyRequest |
    Format-Table -AutoSize
