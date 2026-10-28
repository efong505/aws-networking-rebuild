[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Profile,
    [string]$Region = 'us-west-2'
)

$ErrorActionPreference = 'Stop'
$env:AWS_PROFILE = $Profile
$env:AWS_DEFAULT_REGION = $Region
$env:AWS_PAGER = ''
$repository = Split-Path $PSScriptRoot -Parent
$terraformRoot = Join-Path $repository 'terraform/phase2'
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$privateEvidence = Join-Path $repository "evidence/private/phase2-$stamp"
New-Item -ItemType Directory -Path $privateEvidence -Force | Out-Null

function Invoke-AwsJson {
    param([string[]]$Arguments)
    $result = & aws @Arguments --output json
    if ($LASTEXITCODE -ne 0) { throw "AWS operation failed: $($Arguments[0..1] -join ' ')" }
    if ($result) { $result | ConvertFrom-Json }
}

$targetText = & terraform "-chdir=$terraformRoot" output -json validation_targets
if ($LASTEXITCODE -ne 0) { throw 'Phase 2 outputs are unavailable; do not run during a Terraform operation.' }
$targets = $targetText | ConvertFrom-Json
foreach ($key in @('a', 'b')) {
    $target = $targets.$key
    $prefix = if ($key -eq 'a') { '10.52.1.' } else { '10.53.1.' }
    $parsed = $null
    if (!$target -or ![Net.IPAddress]::TryParse($target.private_ip, [ref]$parsed) -or
        !$target.private_ip.StartsWith($prefix) -or
        $target.instance_id -notmatch '^i-[a-f0-9]+$' -or
        $target.test_name.TrimEnd('.') -ne "$key.phase2.internal") {
        throw 'Unexpected Phase 2 target; refusing remote command execution.'
    }
    $description = Invoke-AwsJson @('ec2', 'describe-instances', '--instance-ids', $target.instance_id)
    $hostInfo = @($description.Reservations.Instances)
    if ($hostInfo.Count -ne 1 -or $hostInfo[0].PublicIpAddress -or
        $hostInfo[0].PrivateIpAddress -ne $target.private_ip -or
        !@($hostInfo[0].Tags | Where-Object { $_.Key -eq 'Project' -and $_.Value -eq 'aws-networking-phase2' }).Count) {
        throw 'Instance identity, lab tag or private addressing does not match.'
    }
}

$summary = @()
foreach ($key in @('a', 'b')) {
    $peerKey = if ($key -eq 'a') { 'b' } else { 'a' }
    $peer = $targets.$peerKey
    $commands = @(
        'set -eu',
        ('dig +short {0} A | grep -Fx {1}' -f $peer.test_name, $peer.private_ip),
        ('getent ahostsv4 {0}' -f $peer.test_name),
        ('getent ahostsv4 {0} | awk ''{{print $1}}'' | grep -Fx {1}' -f $peer.test_name, $peer.private_ip),
        ('ping -c 3 -W 2 {0}' -f $peer.private_ip),
        ('ping -c 3 -W 2 {0}' -f $peer.test_name),
        ("getent ahostsv4 ssm.$Region.amazonaws.com"),
        ("getent ahostsv4 ssmmessages.$Region.amazonaws.com")
    )
    # Region is an AWS region identifier, never arbitrary shell text.
    if ($Region -notmatch '^[a-z]{2}(-[a-z]+)+-\d+$') { throw 'Invalid region identifier.' }
    $request = @{
        DocumentName = 'AWS-RunShellScript'
        InstanceIds = @($targets.$key.instance_id)
        TimeoutSeconds = 60
        Parameters = @{ commands = $commands; executionTimeout = @('45') }
    }
    $requestPath = Join-Path $privateEvidence "$key-request.json"
    [IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 8))
    $sent = Invoke-AwsJson @('ssm', 'send-command', '--cli-input-json', "file://$requestPath")
    $deadline = (Get-Date).AddSeconds(90)
    do {
        Start-Sleep -Seconds 3
        $result = Invoke-AwsJson @('ssm', 'list-command-invocations', '--command-id', $sent.Command.CommandId, '--details')
        $invocation = $result.CommandInvocations | Select-Object -First 1
    } while ((!$invocation -or $invocation.Status -in @('Pending', 'InProgress', 'Delayed')) -and (Get-Date) -lt $deadline)
    if (!$invocation) { throw 'SSM invocation did not appear before timeout.' }
    $detail = Invoke-AwsJson @('ssm', 'get-command-invocation', '--command-id', $sent.Command.CommandId, '--instance-id', $targets.$key.instance_id)
    [IO.File]::WriteAllText((Join-Path $privateEvidence "$key-result.json"), ($detail | ConvertTo-Json -Depth 10))
    $summary += [pscustomobject]@{ Host = $key; Status = $detail.Status; ExitCode = $detail.ResponseCode }
}
$summary | Format-Table -AutoSize
Write-Output "Private evidence: $privateEvidence (review and sanitize before publication)"
if (@($summary | Where-Object { $_.ExitCode -ne 0 -or $_.Status -ne 'Success' }).Count) {
    throw 'Phase 2 baseline failed. Inspect private evidence before injecting a fault.'
}
