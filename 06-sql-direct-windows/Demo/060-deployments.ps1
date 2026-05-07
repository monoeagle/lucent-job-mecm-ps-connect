<#
.SYNOPSIS
  Listet Deployments aus v_DeploymentSummary.

.EXAMPLE
  ./060-deployments.ps1
.EXAMPLE
  ./060-deployments.ps1 -Mode Active -Top 50
#>
[CmdletBinding()]
param(
    [ValidateSet('Active', 'Future', 'All')] [string] $Mode = 'All',
    [int] $Top = 100
)

. (Join-Path $PSScriptRoot '_common.ps1')

$where = switch ($Mode) {
    'Active' { 'WHERE StartTime <= GETUTCDATE()' }
    'Future' { 'WHERE StartTime > GETUTCDATE()' }
    'All'    { '' }
}

Invoke-Sql "
    SELECT TOP $Top
        CASE FeatureType
            WHEN 1 THEN 'App'
            WHEN 2 THEN 'Program'
            WHEN 5 THEN 'Update'
            WHEN 6 THEN 'Baseline'
            WHEN 7 THEN 'TaskSeq'
            WHEN 8 THEN 'Setting'
            ELSE CAST(FeatureType AS NVARCHAR(10))
        END AS Type,
        DeploymentName,
        CollectionName,
        StartTime,
        DeploymentIntent
    FROM v_DeploymentSummary
    $where
    ORDER BY StartTime DESC;" |
    Select-Object Type, DeploymentName, CollectionName, StartTime, DeploymentIntent |
    Format-Table -AutoSize
