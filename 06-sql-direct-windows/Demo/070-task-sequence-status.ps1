<#
.SYNOPSIS
  Task-Sequence-Status aus v_TaskExecutionStatus.

  LastStatusType: 1=Compliant 2=NonCompliant 3=Failed 4=Unknown 5=Success

.EXAMPLE
  ./070-task-sequence-status.ps1
.EXAMPLE
  ./070-task-sequence-status.ps1 -ComputerName PC123 -Top 25
#>
[CmdletBinding()]
param(
    [string] $ComputerName,
    [int]    $Top = 100
)

. (Join-Path $PSScriptRoot '_common.ps1')

$where = ''
if ($ComputerName) {
    $rid   = Resolve-ResourceId -ComputerName $ComputerName
    $where = "WHERE t.ResourceID = $rid"
}

Invoke-Sql "
    SELECT TOP $Top
        s.Name0 AS DeviceName,
        t.PackageID,
        t.AdvertisementID,
        CASE t.LastStatusType
            WHEN 1 THEN 'Compliant'
            WHEN 2 THEN 'NonCompliant'
            WHEN 3 THEN 'Failed'
            WHEN 4 THEN 'Unknown'
            WHEN 5 THEN 'Success'
            ELSE CAST(t.LastStatusType AS NVARCHAR(10))
        END AS Status,
        t.LastStatusMessageID,
        t.ExecutionTime
    FROM v_TaskExecutionStatus t
    JOIN v_R_System s ON s.ResourceID = t.ResourceID
    $where
    ORDER BY t.ExecutionTime DESC;" |
    Select-Object DeviceName, PackageID, AdvertisementID, Status, LastStatusMessageID, ExecutionTime |
    Format-Table -AutoSize
