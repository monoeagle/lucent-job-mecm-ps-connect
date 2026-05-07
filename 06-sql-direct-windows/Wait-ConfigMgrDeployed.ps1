# Wait-ConfigMgrDeployed.ps1 (Windows PowerShell 5.1 compat)
#
# Pollt die ConfigMgr-SQL-DB via Invoke-Sqlcmd, bis ein Rechner den
# "deployed"-Status erreicht hat oder der Timeout ablaeuft.
# Authentifizierung: Windows Integrated Auth (SSPI) per Default.

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $SqlHost,
    [Parameter(Mandatory)] [string] $DbName,
    [int]    $TimeoutSeconds = 3600,
    [int]    $PollIntervalSeconds = 30,
    [string] $SqlUser,
    [string] $SqlPassword
)

$ErrorActionPreference = 'Stop'

$sqlAuth = if ($SqlUser) {
    @{ Username = $SqlUser; Password = $SqlPassword }
} else {
    @{}   # Windows Integrated Auth (SSPI) — kein Credential noetig
}

$query = @"
SET NOCOUNT ON;
DECLARE @name NVARCHAR(64) = N'$ComputerName';
SELECT TOP 1
    r.ResourceID,
    r.Client0                          AS ClientReady,
    ISNULL(t.LastStatusType, 0)        AS TsStatus
FROM v_R_System r
OUTER APPLY (
    SELECT TOP 1 LastStatusType
    FROM v_TaskExecutionStatus
    WHERE ResourceID = r.ResourceID
    ORDER BY ExecutionTime DESC
) t
WHERE r.Name0 = @name;
"@

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

while ((Get-Date) -lt $deadline) {
    try {
        $row = Invoke-Sqlcmd -ServerInstance $SqlHost -Database $DbName @sqlAuth `
                             -Query $query -OutputSqlErrors $true -ErrorAction Stop |
               Select-Object -First 1

        if ($row) {
            Write-Host "[$(Get-Date -Format o)] $ComputerName resource=$($row.ResourceID) client=$($row.ClientReady) ts_status=$($row.TsStatus)"

            if ($row.ClientReady -eq 1 -and $row.TsStatus -eq 5) {
                Write-Host 'DEPLOYED'
                exit 0
            }
        } else {
            Write-Host "[$(Get-Date -Format o)] $ComputerName nicht in DB gefunden"
        }
    }
    catch {
        Write-Warning "Poll fehlgeschlagen: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds $PollIntervalSeconds
}

Write-Error "Timeout nach $TimeoutSeconds s erreicht — Rechner $ComputerName nicht deployed."
exit 1
