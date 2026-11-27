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
            LabEnv  = $LabEnv
        }
    }
    Enable-AzMock -Fixtures @{
        'ad user create'       = '{"id":"00000000-0000-0000-0000-000000000001","userPrincipalName":"lagb-pat@lab.example"}'
        'ad user update'       = '{}'
        'ad group create'      = '{"id":"00000000-0000-0000-0000-000000000101","displayName":"lagb-lab-users"}'
        'ad group member add'  = '{}'
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
    $script:LabEnv = [pscustomobject]@{
        expectedEntraTenantId = '00000000-0000-0000-0000-0000000000aa'
    }
}
AfterAll { Disable-AzMock }

Describe 'a05-e02-create-user-and-group' {
    It 'calls Assert-LabContext -Scope Entra before any az command' {
        $script:Guard = $null
        Invoke-CreateUserAndGroup -LabEnv $script:LabEnv
        $script:Guard | Should -Not -BeNullOrEmpty
        $script:Guard.Scope | Should -Be 'Entra'
        $script:Guard.AzCount | Should -Be 0
        @(Get-AzMockCalls).Count | Should -BeGreaterThan 0
    }

    It 'creates a user, updates a property, creates a group, and adds the member' {
        Invoke-CreateUserAndGroup -LabEnv $script:LabEnv
        $calls = @(Get-AzMockCalls)
        @($calls | Where-Object { $_ -match '^ad user create\b' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '^ad user update\b' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '^ad group create\b' }).Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match '^ad group member add\b' }).Count | Should -BeGreaterThan 0
    }
}
