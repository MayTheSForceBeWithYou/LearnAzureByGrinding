#Requires -Version 7.4
# Look up a user and a group by display name, then add the membership idempotently.
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Add-NamedGroupMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$LabEnv,
        [Parameter(Mandatory)][string]$UserDisplayName,
        [Parameter(Mandatory)][string]$GroupDisplayName
    )

    # ---- Your resources go below this line. ----
    Assert-LabContext -Scope Entra -LabEnv $LabEnv
    $userFilter = "displayName eq '$($UserDisplayName.Replace("'", "''"))'"
    $groupFilter = "displayName eq '$($GroupDisplayName.Replace("'", "''"))'"
    $users = @(az ad user list --filter $userFilter --output json | ConvertFrom-Json)
    if ($users.Count -ne 1) {
        throw "expected exactly 1 user matching $userFilter, found $($users.Count)"
    }
    $groups = @(az ad group list --filter $groupFilter --output json | ConvertFrom-Json)
    if ($groups.Count -ne 1) {
        throw "expected exactly 1 group matching $groupFilter, found $($groups.Count)"
    }
    $user = $users[0]
    $group = $groups[0]
    $check = az ad group member check --group $group.id --member-id $user.id --output json | ConvertFrom-Json
    if (-not $check.value) {
        az ad group member add --group $group.id --member-id $user.id | Out-Null
    }
}
