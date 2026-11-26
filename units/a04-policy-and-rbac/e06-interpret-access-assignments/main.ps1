# Course fixture path for az role assignment list. Not a live call.
Set-StrictMode -Version 3.0
$RoleAssignmentFixturePath = Join-Path $PSScriptRoot 'fixtures/role-assignments.json'

function Get-CourseRoleAssignments {
    $json = az role assignment list --output json
    @($json | ConvertFrom-Json)
}
