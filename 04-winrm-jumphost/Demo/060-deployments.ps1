<#
.SYNOPSIS
  Listet Deployments — laufend und/oder zukuenftig geplant.
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

$now = Get-Date

$deployments = Get-CMDeployment | Sort-Object DeploymentTime -Descending

$filtered = switch ($Mode) {
    'Active' { $deployments | Where-Object { $_.DeploymentTime -le $now } }
    'Future' { $deployments | Where-Object { $_.DeploymentTime -gt $now } }
    'All'    { $deployments }
}

$filtered | Select-Object -First $Top |
    Format-Table FeatureType, ApplicationName, SoftwareName, CollectionName,
                 DeploymentTime, DeploymentIntent -AutoSize
