<#
.SYNOPSIS
  Listet alle Cmdlets des ConfigurationManager-Moduls — optional gefiltert.
.DESCRIPTION
  Damit findest du, was an Cmdlets fuer eigene Skripte verfuegbar ist.
.EXAMPLE
  .\090-discover-cmdlets.ps1
.EXAMPLE
  .\090-discover-cmdlets.ps1 -Pattern Deployment
.EXAMPLE
  .\090-discover-cmdlets.ps1 -Verb Get -Pattern Collection
#>
[CmdletBinding()]
param(
    [string] $Pattern,
    [string] $Verb
)

. (Join-Path $PSScriptRoot '_common.ps1')

$cmds = Get-Command -Module ConfigurationManager
if ($Pattern) { $cmds = $cmds | Where-Object { $_.Name -like "*$Pattern*" } }
if ($Verb)    { $cmds = $cmds | Where-Object { $_.Verb -eq $Verb } }

Write-Host "Gefundene Cmdlets: $($cmds.Count)" -ForegroundColor Cyan
$cmds | Sort-Object Name | Format-Table Name, Verb, Noun -AutoSize
