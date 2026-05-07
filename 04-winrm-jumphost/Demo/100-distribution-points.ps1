<#
.SYNOPSIS
  Distribution-Points + Management-Points + Boundary-Groups - Site-Topology
  auf einen Blick.
.EXAMPLE
  .\100-distribution-points.ps1
#>
[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')

Write-Host "`n=== Distribution Points ===" -ForegroundColor Cyan
Get-CMDistributionPoint |
    Select-Object NetworkOSPath, SiteCode, RoleName |
    Format-Table -AutoSize

Write-Host "`n=== Management Points ===" -ForegroundColor Cyan
Get-CMManagementPoint |
    Select-Object NetworkOSPath, SiteCode, RoleName |
    Format-Table -AutoSize

Write-Host "`n=== Boundary Groups ===" -ForegroundColor Cyan
Get-CMBoundaryGroup |
    Select-Object Name, MemberCount, Description |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host "`n=== Site-Server (uebergeordnet) ===" -ForegroundColor Cyan
Get-CMSite |
    Format-Table SiteCode, SiteName, Version, BuildNumber, Type -AutoSize
