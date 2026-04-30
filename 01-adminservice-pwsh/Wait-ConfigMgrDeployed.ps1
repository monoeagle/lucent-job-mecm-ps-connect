#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ComputerName,
    [Parameter(Mandatory)] [string] $SmsProvider,
    [Parameter(Mandatory)] [string] $SiteCode,
    [int] $TimeoutSeconds = 3600,
    [int] $PollIntervalSeconds = 30,
    [switch] $SkipCertificateCheck
)

$ErrorActionPreference = 'Stop'
$base = "https://$SmsProvider/AdminService/wmi"

$irmCommon = @{
    UseDefaultCredentials = $true
    Headers               = @{ Accept = 'application/json' }
}
if ($SkipCertificateCheck) { $irmCommon['SkipCertificateCheck'] = $true }

function Get-DeviceState {
    param([string]$Name)

    $deviceUrl = "$base/SMS_R_System?`$filter=Name eq '$Name'&`$select=ResourceID,Client,LastLogonTimestamp"
    $device = (Invoke-RestMethod @irmCommon -Uri $deviceUrl).value | Select-Object -First 1
    if (-not $device) { return @{ Found = $false } }

    $tsUrl = "$base/SMS_TaskSequenceDeploymentStatus?`$filter=ResourceID eq $($device.ResourceID)&`$orderby=StatusTime desc"
    $tsRows = (Invoke-RestMethod @irmCommon -Uri $tsUrl).value
    $latestTs = $tsRows | Select-Object -First 1

    return @{
        Found       = $true
        ClientReady = ($device.Client -eq 1)
        TsStatus    = $latestTs?.StatusType    # 5 = Success
        TsMessageId = $latestTs?.LastStatusMessageID
    }
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    try {
        $state = Get-DeviceState -Name $ComputerName
        Write-Host "[$(Get-Date -Format o)] $ComputerName → $($state | ConvertTo-Json -Compress)"

        if ($state.Found -and $state.ClientReady -and $state.TsStatus -eq 5) {
            Write-Host "DEPLOYED"
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
