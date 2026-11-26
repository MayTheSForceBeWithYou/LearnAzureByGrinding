# Course fixture path for az account management-group list. Not a live call.
Set-StrictMode -Version 3.0
$ManagementGroupFixturePath = Join-Path $PSScriptRoot 'fixtures/management-groups.json'

function Get-CourseManagementGroups {
    $json = az account management-group list --output json
    @($json | ConvertFrom-Json)
}
