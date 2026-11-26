BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    Enable-AzMock -Fixtures @{
        'role assignment list' = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/role-assignments.json'))
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
}
AfterAll { Disable-AzMock }

Describe 'a04-e06-interpret-access-assignments' {
    It 'returns the Reader assignment on the course-example resource group' {
        $rows = @(Get-CourseRoleAssignments)
        $reader = @($rows | Where-Object { $_.roleDefinitionName -eq 'Reader' })
        $reader.Count | Should -Be 1
        $reader[0].scope | Should -Match 'resourceGroups/lagb-course-example'
    }

    It 'calls az role assignment list' {
        $null = Get-CourseRoleAssignments
        (Get-AzMockCalls)[-1] | Should -Match '^role assignment list'
    }
}
