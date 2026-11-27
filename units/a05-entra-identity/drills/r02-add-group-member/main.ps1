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
}
