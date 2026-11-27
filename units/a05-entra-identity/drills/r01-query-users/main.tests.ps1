BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $script:Guard = $null
    function global:Assert-LabContext {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][ValidateSet('Resource', 'Entra')][string]$Scope,
            $LabEnv
        )
        $script:Guard = [pscustomobject]@{
            Scope   = $Scope
            AzCount = @(Get-AzMockCalls).Count
        }
    }
    Enable-AzMock -Fixtures @{
        'ad user list' = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/users.json'))
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
    $script:LabEnv = [pscustomobject]@{ expectedEntraTenantId = '00000000-0000-0000-0000-0000000000aa' }
}
AfterAll { Disable-AzMock }

Describe 'a05-r01-query-users' {
    It 'calls Assert-LabContext -Scope Entra before any az command' {
        $script:Guard = $null
        $null = Get-DepartmentUserUpns -LabEnv $script:LabEnv -Department 'Engineering'
        $script:Guard | Should -Not -BeNullOrEmpty
        $script:Guard.Scope | Should -Be 'Entra'
        $script:Guard.AzCount | Should -Be 0
    }

    It 'lists Engineering UPNs from the fixture filter' {
        $upns = @(Get-DepartmentUserUpns -LabEnv $script:LabEnv -Department 'Engineering')
        $upns | Should -Contain 'lagb-alex@lab.example'
        $upns | Should -Contain 'lagb-chris@lab.example'
        $upns | Should -Not -Contain 'lagb-blair@lab.example'
        (Get-AzMockCalls)[-1] | Should -Match '^ad user list'
        (Get-AzMockCalls)[-1] | Should -Match 'Engineering'
    }
}
