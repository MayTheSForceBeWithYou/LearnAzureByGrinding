BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    Enable-AzMock -Fixtures @{
        'account management-group list' = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/management-groups.json'))
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
}
AfterAll { Disable-AzMock }

Describe 'a03-e06-list-management-groups' {
    It 'returns the course-example management group from the fixture' {
        $names = @(Get-CourseManagementGroups | ForEach-Object name)
        $names | Should -Contain 'mg-course-example'
    }

    It 'calls az account management-group list' {
        $null = Get-CourseManagementGroups
        (Get-AzMockCalls)[-1] | Should -Match '^account management-group list'
    }
}
