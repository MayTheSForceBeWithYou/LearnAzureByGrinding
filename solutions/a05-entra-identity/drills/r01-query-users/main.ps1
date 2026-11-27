#Requires -Version 7.4
# List users in one department and return their UPNs. Tests mock `az` and Assert-LabContext.
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Get-DepartmentUserUpns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$LabEnv,
        [Parameter(Mandatory)][string]$Department
    )

    # ---- Your resources go below this line. ----
    Assert-LabContext -Scope Entra -LabEnv $LabEnv
    $json = az ad user list --filter "department eq '$Department'" --output json
    @($json | ConvertFrom-Json | ForEach-Object userPrincipalName)
}
