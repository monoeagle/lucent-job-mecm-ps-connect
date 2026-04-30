# Wait-ConfigMgrDeployed.ps1 (Windows PowerShell 5.1 compat)
#
# Funktional identisch zur pwsh-7-Version. Da diese Variante keine
# pwsh-7-only-Features nutzt (kein ??/?., kein -SkipCertificateCheck),
# ist die Datei bis auf den fehlenden Shebang gleich.
#
# Aufruf: .\Wait-ConfigMgrDeployed.ps1 -ComputerName PC123 -Jumphost ... -SiteCode P01

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $Jumphost,
    [Parameter(Mandatory)] [string] $SiteCode,
    [int] $TimeoutSeconds = 3600,
    [int] $PollIntervalSeconds = 30
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$remoteScript = Join-Path $PSScriptRoot '..\jumphost\Get-ConfigMgrStatus.ps1'

$session = New-PSSession -ComputerName $Jumphost -Authentication Negotiate -UseSSL
try {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = Invoke-Command -Session $session -FilePath $remoteScript -ArgumentList $ComputerName, $SiteCode
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
