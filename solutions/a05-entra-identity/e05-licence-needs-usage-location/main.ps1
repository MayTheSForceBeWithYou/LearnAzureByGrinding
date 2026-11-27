#Requires -Version 7.4
# Set usageLocation, then assign a licence through Microsoft Graph via `az rest`.
# P1 assignment is trial-in-test-tenant only. Tests mock `az` and `Assert-LabContext`.
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Invoke-AssignLicence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$LabEnv,
        [Parameter(Mandatory)][string]$UserId,
        [Parameter(Mandatory)][string]$SkuId,
        [string]$UsageLocation = 'US'
    )

    # ---- Your resources go below this line. ----
    Assert-LabContext -Scope Entra -LabEnv $LabEnv
    # az is a .cmd on Windows; inline JSON on --body loses quotes. Write a temp file and
    # pass --body "@$path". https://learn.microsoft.com/cli/azure/use-azure-cli-successfully-powershell
    $tmp = [IO.Path]::GetTempPath()
    $patchFile = Join-Path $tmp ('lagb-a05-e05-patch-' + [guid]::NewGuid().ToString('n') + '.json')
    $assignFile = Join-Path $tmp ('lagb-a05-e05-assign-' + [guid]::NewGuid().ToString('n') + '.json')
    try {
        @{ usageLocation = $UsageLocation } | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $patchFile -Encoding utf8NoBOM
        az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/users/$UserId" --body "@$patchFile" --headers Content-Type=application/json | Out-Null
        @{
            addLicenses    = @(@{ skuId = $SkuId; disabledPlans = @() })
            removeLicenses = @()
        } | ConvertTo-Json -Compress -Depth 5 |
            Set-Content -LiteralPath $assignFile -Encoding utf8NoBOM
        az rest --method POST --uri "https://graph.microsoft.com/v1.0/users/$UserId/assignLicense" --body "@$assignFile" --headers Content-Type=application/json | Out-Null
    } finally {
        Remove-Item -LiteralPath $patchFile, $assignFile -Force -ErrorAction SilentlyContinue
    }
}
