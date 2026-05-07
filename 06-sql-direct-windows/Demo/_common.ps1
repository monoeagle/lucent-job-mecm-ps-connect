# _common.ps1 (Windows PowerShell 5.1 compat)
#
# Invoke-Sqlcmd-Wrapper fuer alle Demo-Skripte. Wird per Dot-Sourcing geladen.
#
# Erwartete Env-Variablen:
#   CONFIGMGR_SQL_HOST  - FQDN des ConfigMgr-SQL-Servers, z.B. sql.corp.local
#   CONFIGMGR_DB_NAME   - z.B. CM_P01
# Optional fuer SQL-Auth statt Windows-Auth:
#   SQL_USER            - SQL-Benutzername
#   SQL_PASS            - SQL-Passwort

$script:SqlHost = $env:CONFIGMGR_SQL_HOST
if (-not $script:SqlHost) {
    throw 'Bitte CONFIGMGR_SQL_HOST setzen, z.B. sql.corp.local'
}

$script:DbName = $env:CONFIGMGR_DB_NAME
if (-not $script:DbName) {
    throw 'Bitte CONFIGMGR_DB_NAME setzen, z.B. CM_P01'
}

# SQL-Auth: SQL_USER gesetzt => Username+Password; sonst Windows-Auth (SSPI)
if ($env:SQL_USER) {
    $script:SqlAuth = @{
        Username = $env:SQL_USER
        Password = $env:SQL_PASS
    }
} else {
    $script:SqlAuth = @{}   # Windows Integrated Auth — kein Credential noetig
}

function Invoke-Sql {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Query)
    Invoke-Sqlcmd -ServerInstance $script:SqlHost -Database $script:DbName `
                  @script:SqlAuth -Query $Query -OutputSqlErrors $true -ErrorAction Stop
}

function Resolve-ResourceId {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $ComputerName)
    $row = Invoke-Sql "SELECT TOP 1 ResourceID FROM v_R_System WHERE Name0 = N'$ComputerName'"
    if (-not $row) { throw "Device '$ComputerName' nicht gefunden." }
    $row.ResourceID
}
