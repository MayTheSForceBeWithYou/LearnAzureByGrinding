BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a04-e02-custom-sku-region-guard' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'the custom definition uses deny or audit, not modify or deployIfNotExists' {
        $def = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyDefinitions')
        $def.Count | Should -Be 1
        $effect = Get-PropertyValue -Object $def[0].Resource -Path 'properties.policyRule.then.effect'
        $effect.Found | Should -BeTrue
        "$($effect.Value)" | Should -Match 'deny|audit|parameters\('
        "$($effect.Value)" | Should -Not -Match 'modify|deployIfNotExists'
        "$($def[0].Name)" | Should -Be 'lagb-sku-region-guard'
    }

    It 'uses mode Indexed and excludes global so the A02 action group and budget are not denied' {
        $def = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyDefinitions')
        $def.Count | Should -Be 1
        $mode = Get-PropertyValue -Object $def[0].Resource -Path 'properties.mode'
        $mode.Found | Should -BeTrue
        "$($mode.Value)" | Should -Be 'Indexed'
        $rule = Get-PropertyValue -Object $def[0].Resource -Path 'properties.policyRule'
        $rule.Found | Should -BeTrue
        $text = ConvertTo-Json $rule.Value -Depth 30 -Compress
        $text | Should -Match 'location'
        $text | Should -Match 'global'
        $text | Should -Match 'notEquals|notIn'
    }

    It 'the assignment references the custom definition by id, and does not copy policyRule' {
        $as = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyAssignments')
        $as.Count | Should -Be 1
        $defId = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyDefinitionId'
        $defId.Found | Should -BeTrue
        "$($as[0].Name)" | Should -Be 'lagb-sku-region-guard'
        "$($defId.Value)" | Should -Match 'policyDefinitions'
        $copied = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyRule'
        $copied.Found | Should -BeFalse
    }
}

Describe 'a04-e02 down.ps1 (mocked LabGuard and az)' {
    BeforeAll {
        $root = $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
        Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
        Import-Module (Join-Path $root 'scripts/lab/LabGuard.psm1') -Force
        $script:Down = Join-Path $PSScriptRoot 'down.ps1'
        $script:LabEnv = [pscustomobject]@{
            prefix   = 'lagb'
            location = 'eastus'
            owner    = 'n8'
        }
    }

    It 'deletes the policy assignment before the policy definition' {
        Enable-AzMock -Fixtures @{
            'policy assignment delete' = '{}'
            'policy definition delete' = '{}'
        }
        try {
            & $script:Down -LabEnv $script:LabEnv
            $calls = @(Get-AzMockCalls)
            $assignI = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match 'policy assignment delete' } | Select-Object -First 1
            $defI = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match 'policy definition delete' } | Select-Object -First 1
            $assignI | Should -Not -BeNullOrEmpty
            $defI | Should -Not -BeNullOrEmpty
            $assignI | Should -BeLessThan $defI
        } finally {
            Disable-AzMock
        }
    }

    It 'does not delete when -WhatIf is set' {
        Enable-AzMock -Fixtures @{
            'policy assignment delete' = '{}'
            'policy definition delete' = '{}'
        }
        try {
            & $script:Down -LabEnv $script:LabEnv -WhatIf
            @(Get-AzMockCalls) | Should -HaveCount 0
        } finally {
            Disable-AzMock
        }
    }
}
