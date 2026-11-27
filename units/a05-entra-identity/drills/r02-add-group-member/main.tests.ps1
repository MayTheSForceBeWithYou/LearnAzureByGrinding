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
        'ad user list'        = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/user.json'))
        'ad group list'       = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/group.json'))
        'ad group member check' = '{"value": false}'
        'ad group member add' = '{}'
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
    $script:LabEnv = [pscustomobject]@{ expectedEntraTenantId = '00000000-0000-0000-0000-0000000000aa' }
}
AfterAll { Disable-AzMock }

Describe 'a05-r02-add-group-member' {
    It 'calls Assert-LabContext -Scope Entra before any az command' {
        $script:Guard = $null
        Add-NamedGroupMember -LabEnv $script:LabEnv -UserDisplayName 'lagb-alex' -GroupDisplayName 'lagb-lab-users'
        $script:Guard | Should -Not -BeNullOrEmpty
        $script:Guard.Scope | Should -Be 'Entra'
        $script:Guard.AzCount | Should -Be 0
    }

    It 'looks up the user and group by name and adds the membership' {
        Add-NamedGroupMember -LabEnv $script:LabEnv -UserDisplayName 'lagb-alex' -GroupDisplayName 'lagb-lab-users'
        $calls = @(Get-AzMockCalls)
        @($calls | Where-Object { $_ -match '^ad user list\b' -and $_ -match 'lagb-alex' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '^ad group list\b' -and $_ -match 'lagb-lab-users' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '^ad group member add\b' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '00000000-0000-0000-0000-000000000001' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '00000000-0000-0000-0000-000000000101' }).Count | Should -BeGreaterThan 0
    }

    It 'is idempotent when the user is already a member' {
        Disable-AzMock
        Enable-AzMock -Fixtures @{
            'ad user list'          = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/user.json'))
            'ad group list'         = (Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/group.json'))
            'ad group member check' = '{"value": true}'
            'ad group member add'   = '{}'
        }
        $script:Guard = $null
        Add-NamedGroupMember -LabEnv $script:LabEnv -UserDisplayName 'lagb-alex' -GroupDisplayName 'lagb-lab-users'
        $calls = @(Get-AzMockCalls)
        @($calls | Where-Object { $_ -match '^ad group member add\b' }).Count | Should -Be 0
    }
}
