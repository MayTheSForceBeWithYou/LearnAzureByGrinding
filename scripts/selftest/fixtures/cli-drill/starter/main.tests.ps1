# Harness for a CLI drill: `az` is replaced by an offline fake that answers from fixtures/.
BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    Enable-AzMock -Fixtures @{
        'group list' = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/group-list.json'))
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
}
AfterAll { Disable-AzMock }

Describe 'a99-r01-course-groups' {
    It 'returns the course-tagged group names' {
        Get-CourseGroupNames | Should -Be @('lagb-a99-r01-one', 'lagb-a99-r01-two')
    }
    It 'filters by the course tag on the server side' {
        $null = Get-CourseGroupNames
        (Get-AzMockCalls)[-1] | Should -Match '^group list .*--tag course=LearnAzureByGrinding'
    }
}
