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
        rest = '{"id":"00000000-0000-0000-0000-000000000001","usageLocation":"US","assignedLicenses":[{"skuId":"00000000-0000-0000-0000-0000000000b1","disabledPlans":[]}]}'
    }
    . (Join-Path $PSScriptRoot 'main.ps1')
    $script:LabEnv = [pscustomobject]@{
        expectedEntraTenantId = '00000000-0000-0000-0000-0000000000aa'
    }
    $script:UserId = '00000000-0000-0000-0000-000000000001'
    $script:SkuId = '00000000-0000-0000-0000-0000000000b1'
}
AfterAll { Disable-AzMock }

Describe 'a05-e05-licence-needs-usage-location' {
    It 'calls Assert-LabContext -Scope Entra before any az command' {
        $script:Guard = $null
        Invoke-AssignLicence -LabEnv $script:LabEnv -UserId $script:UserId -SkuId $script:SkuId
        $script:Guard | Should -Not -BeNullOrEmpty
        $script:Guard.Scope | Should -Be 'Entra'
        $script:Guard.AzCount | Should -Be 0
        @(Get-AzMockCalls).Count | Should -BeGreaterThan 0
    }

    It 'sets usageLocation then POSTs assignLicense through az rest' {
        Invoke-AssignLicence -LabEnv $script:LabEnv -UserId $script:UserId -SkuId $script:SkuId -UsageLocation 'US'
        $calls = @(Get-AzMockCalls)
        $patch = @($calls | Where-Object { $_ -match '^rest\b' -and $_ -match 'usageLocation|PATCH|patch' })
        $assign = @($calls | Where-Object { $_ -match '^rest\b' -and $_ -match 'assignLicense' })
        $patch.Count | Should -BeGreaterThan 0
        $assign.Count | Should -BeGreaterThan 0
        @($calls | Where-Object { $_ -match 'graph\.microsoft\.com' }).Count | Should -BeGreaterThan 0
        $firstRest = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match '^rest\b' } | Select-Object -First 1
        $assignI = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match 'assignLicense' } | Select-Object -First 1
        $firstRest | Should -BeLessThan $assignI
    }
}
