# Wait-ConfigMgrDeployed.ps1 (Windows PowerShell 5.1 compat)
#
# Funktional identisch zur pwsh-7-Version im Parent-Folder, ersetzt aber
# pwsh-7-only-Features:
#   - kein Shebang (wuerde 5.1 nicht stoeren, ist aber irrelevant)
#   - Invoke-RestMethod -SkipCertificateCheck (pwsh 6+) wird durch
#     ServicePointManager-Callback ersetzt
#   - Null-Conditional ?. wird durch if/else ersetzt
#   - TLS 1.2 muss in 5.1 explizit eingeschaltet werden

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $SmsProvider,
    [Parameter(Mandatory)] [string] $SiteCode,
    [int]    $TimeoutSeconds = 3600,
    [int]    $PollIntervalSeconds = 30,
    [switch] $SkipCertificateCheck
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 nutzt per Default TLS 1.0 — explizit Tls12 erzwingen
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($SkipCertificateCheck) {
    # 5.1 hat kein -SkipCertificateCheck-Flag — Callback global ueberschreiben
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}

$base = "https://$SmsProvider/AdminService/wmi"
$irmCommon = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/json' }
}

function Get-DeviceState {
    param([string]$Name)

    $deviceUrl = "$base/SMS_R_System?`$filter=Name eq '$Name'&`$select=ResourceID,Client,LastLogonTimestamp"
    $device = (Invoke-RestMethod @irmCommon -Uri $deviceUrl).value | Select-Object -First 1
    if (-not $device) { return @{ Found = $false } }

    $tsUrl = "$base/SMS_TaskSequenceDeploymentStatus?`$filter=ResourceID eq $($device.ResourceID)&`$orderby=StatusTime desc"
    $tsRows = (Invoke-RestMethod @irmCommon -Uri $tsUrl).value
    $latestTs = $tsRows | Select-Object -First 1

    # 5.1: kein ?. — explizit if/else
    $tsStatus = if ($latestTs) { $latestTs.StatusType } else { $null }
    $tsMsgId  = if ($latestTs) { $latestTs.LastStatusMessageID } else { $null }

    return @{
        Found       = $true
        ClientReady = ($device.Client -eq 1)
        TsStatus    = $tsStatus
        TsMessageId = $tsMsgId
    }
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    try {
        $state = Get-DeviceState -Name $ComputerName
        Write-Host "[$(Get-Date -Format o)] $ComputerName -> $($state | ConvertTo-Json -Compress)"

        if ($state.Found -and $state.ClientReady -and $state.TsStatus -eq 5) {
            Write-Host 'DEPLOYED'
            exit 0
        }
    }
    catch {
        Write-Warning "Poll fehlgeschlagen: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds $PollIntervalSeconds
}

Write-Error "Timeout nach $TimeoutSeconds s erreicht — Rechner $ComputerName nicht deployed."
exit 1
