<#
.SYNOPSIS
  Aggregation: Devices pro Collection mit Active-Client- und OS-Zaehlung.

  Zeigt was SQL direkt kann, was der AdminService nicht trivial liefert:
  Multi-View-JOIN mit GROUP BY ueber Collections, Client-Health und OS.

.EXAMPLE
  ./100-complex-aggregation.ps1
.EXAMPLE
  ./100-complex-aggregation.ps1 -OsPattern 'Windows 10'
#>
[CmdletBinding()]
param([string] $OsPattern = 'Windows 11')

. (Join-Path $PSScriptRoot '_common.ps1')

Invoke-Sql "
    SELECT
        c.Name AS CollectionName,
        COUNT(DISTINCT s.ResourceID)                                                AS Devices,
        SUM(CASE WHEN ch.ClientActiveStatus = 1 THEN 1 ELSE 0 END)                 AS ActiveClients,
        SUM(CASE WHEN os.Caption0 LIKE N'%$OsPattern%' THEN 1 ELSE 0 END)          AS MatchOS
    FROM v_FullCollectionMembership m
    JOIN v_Collection               c   ON c.CollectionID  = m.CollectionID
    JOIN v_R_System                 s   ON s.ResourceID    = m.ResourceID
    LEFT JOIN v_CH_ClientSummary    ch  ON ch.ResourceID   = s.ResourceID
    LEFT JOIN v_GS_OPERATING_SYSTEM os  ON os.ResourceID   = s.ResourceID
    WHERE c.CollectionType = 2
    GROUP BY c.Name
    HAVING COUNT(DISTINCT s.ResourceID) > 0
    ORDER BY Devices DESC;" |
    Select-Object CollectionName, Devices, ActiveClients,
                  @{n="with_$($OsPattern -replace ' ','_')"; e={$_.MatchOS}} |
    Format-Table -AutoSize
