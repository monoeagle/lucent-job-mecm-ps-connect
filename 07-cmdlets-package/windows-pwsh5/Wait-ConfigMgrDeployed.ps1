# Wait-ConfigMgrDeployed.ps1 (Windows PowerShell 5.1 compat)
#
# Funktional identisch zur pwsh-7-Version, nutzt keine pwsh-7-only-Features.

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $WindowsHost,
    [Parameter(Mandatory)] [string] $SiteCode,
    [Parameter(Mandatory)] [string] $SiteServer,
    [string] $CmdletPath = 'C:\Tools\PSCMDLets',
    [int]    $TimeoutSeconds = 3600,
    [int]    $PollIntervalSeconds = 30
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$remoteScript = Join-Path $PSScriptRoot '..\windows\Get-ConfigMgrStatus.ps1'

$session = New-PSSession -ComputerName $WindowsHost -Authentication Negotiate -UseSSL
try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = Invoke-Command -Session $session -FilePath $remoteScript `
            -ArgumentList $ComputerName, $SiteCode, $SiteServer, $CmdletPath
        Write-Host "[$(Get-Date -Format o)] $ComputerName -> $($state | ConvertTo-Json -Compress)"

        if ($state.ClientReady -and $state.TsSucceeded) {
            Write-Host 'DEPLOYED'
            exit 0
        }
        Start-Sleep -Seconds $PollIntervalSeconds
    }
    Write-Error "Timeout nach $TimeoutSeconds s."
    exit 1
}
finally {
    Remove-PSSession $session
}
