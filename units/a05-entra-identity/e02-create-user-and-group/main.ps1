#Requires -Version 7.4
# Create a cloud user and a security group in the A05 test tenant.
# Tests mock `az` and `Assert-LabContext`. Live az against the test tenant is optional and
# still needs Assert-LabContext -Scope Entra first (SPEC 3.2).
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Invoke-CreateUserAndGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$LabEnv,
        [string]$DisplayName = 'lagb-pat',
        [string]$UserPrincipalName = 'lagb-pat@lab.example',
        [string]$Password = 'NotARealPassword_0',
        [string]$UpdatedDisplayName = 'lagb-pat-updated',
        [string]$GroupDisplayName = 'lagb-lab-users',
        [string]$GroupMailNickname = 'lagblabusers'
    )

    # ---- Your resources go below this line. ----
}
