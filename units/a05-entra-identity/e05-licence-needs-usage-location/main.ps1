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
}
