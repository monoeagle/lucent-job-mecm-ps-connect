<#
.SYNOPSIS
  Client-Health-Summary aus v_CH_ClientSummary.

.EXAMPLE
  ./080-client-health.ps1
.EXAMPLE
  ./080-client-health.ps1 -ComputerName PC123
.EXAMPLE
  ./080-client-health.ps1 -OnlyUnhealthy -Top 50
#>
[CmdletBinding()]
param(
    [string] $ComputerName,
    [switch] $OnlyUnhealthy,
    [int]    $Top = 200
)

. (Join-Path $PSScriptRoot '_common.ps1')

$conds = @()
if ($ComputerName) {
    $rid    = Resolve-ResourceId -ComputerName $ComputerName
    $conds += "ResourceID = $rid"
}
if ($OnlyUnhealthy) { $conds += 'ClientActiveStatus = 0' }

$where = if ($conds.Count -gt 0) { 'WHERE ' + ($conds -join ' AND ') } else { '' }

Invoke-Sql "
    SELECT TOP $Top
        Name,
        ClientStateDescription,
        CASE ClientActiveStatus WHEN 1 THEN 'yes' ELSE 'no' END AS Active,
        LastActiveTime,
        LastHardwareScan,
        LastPolicyRequest
    FROM v_CH_ClientSummary
    $where
    ORDER BY LastActiveTime DESC;" |
    Select-Object Name, ClientStateDescription, Active, LastActiveTime, LastHardwareScan, LastPolicyRequest |
    Format-Table -AutoSize
