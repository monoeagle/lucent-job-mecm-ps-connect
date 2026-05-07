<#
.SYNOPSIS
  Listet alle v_*-Views in der CM-DB. Optional mit Spalten-Schema.

.EXAMPLE
  ./090-discover-views.ps1
.EXAMPLE
  ./090-discover-views.ps1 -Pattern 'v_GS_'
.EXAMPLE
  ./090-discover-views.ps1 -Pattern 'v_GS_' -ShowSchema
#>
[CmdletBinding()]
param(
    [string] $Pattern = 'v_',
    [switch] $ShowSchema
)

. (Join-Path $PSScriptRoot '_common.ps1')

$views = Invoke-Sql "
    SELECT TOP 500 TABLE_NAME
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_NAME LIKE N'${Pattern}%'
    ORDER BY TABLE_NAME;"

Write-Host "Views mit Pattern '${Pattern}*': $($views.Count)" -ForegroundColor Cyan
$views | Select-Object -ExpandProperty TABLE_NAME | Format-Wide -Column 4

if ($ShowSchema) {
    Write-Host "`n--- Spalten pro View ---" -ForegroundColor Yellow
    foreach ($view in $views.TABLE_NAME) {
        Write-Host "`n-- $view --"
        Invoke-Sql "
            SELECT COLUMN_NAME, DATA_TYPE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = N'$view'
            ORDER BY ORDINAL_POSITION;" |
            Select-Object COLUMN_NAME, DATA_TYPE |
            Format-Table -AutoSize
    }
}
