# Unit tests for lib/AzGrinding (offline; no Bicep needed except where noted).
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../lib/AzGrinding.psd1') -Force
    $tpl = @{
        resources = @(
            @{ type = 'Microsoft.Storage/storageAccounts'; name = 'st1'; sku = @{ name = 'Standard_LRS' }
                properties = @{ supportsHttpsTrafficOnly = $true; rules = @(@{ access = 'Deny' }) }
                resources = @(@{ type = 'blobServices'; name = 'default' })
            },
            @{ type = 'Microsoft.Resources/deployments'; name = 'mod'
                properties = @{ template = @{ resources = @(@{ type = 'Microsoft.Network/virtualNetworks'; name = 'vnet' }) } }
            }
        )
        outputs = @{ storageAccountName = @{ type = 'string' } }
    }
}

Describe 'Get-TemplateResources' {
    It 'flattens child resources and module deployments' {
        $types = Get-TemplateResources -Template $tpl | ForEach-Object Type
        $types | Should -Contain 'Microsoft.Storage/storageAccounts/blobServices'
        $types | Should -Contain 'Microsoft.Network/virtualNetworks'
    }
    It 'handles languageVersion 2.0 symbolic resources (a dictionary)' {
        $t2 = @{ languageVersion = '2.0'; resources = @{ sa = @{ type = 'Microsoft.Storage/storageAccounts'; name = 'x' } } }
        (Get-TemplateResources -Template $t2 -Type 'microsoft.storage/storageaccounts').Count | Should -Be 1
    }
}

Describe 'Expect* helpers' {
    It 'reports missing types and outputs' {
        Test-ExpectResources -Template $tpl -Types @('Microsoft.Storage/storageAccounts', 'Microsoft.Web/sites') | Should -Be @('Microsoft.Web/sites')
        Test-ExpectOutputs -Template $tpl -Names @('storageAccountName', 'nope') | Should -Be @('nope')
    }
    It 'checks property paths with Value and Match, including array indexes' {
        Test-ExpectProperties -Template $tpl -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true },
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Match = '_LRS$' },
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.rules[0].access'; Value = 'Deny' }
        ) | Should -BeNullOrEmpty
    }
    It 'does not treat the string "true" as the boolean true' {
        $t = @{ resources = @(@{ type = 'A.B/c'; name = 'n'; properties = @{ on = 'true' } }) }
        Test-ExpectProperties -Template $t -Expect @(@{ ResourceType = 'A.B/c'; Path = 'properties.on'; Value = $true }) | Should -Not -BeNullOrEmpty
    }
    It 'Assert-ExpectResources throws with the missing type' {
        { Assert-ExpectResources -Template $tpl -Types @('Microsoft.Web/sites') } | Should -Throw '*Microsoft.Web/sites*'
    }
}

Describe 'Get-ExerciseId' {
    It 'derives ids for exercises, drills, capstones, solutions, and reps' {
        Get-ExerciseId -Path 'x/units/a06-storage-accounts/e01-storage-account' | Should -Be 'a06-e01-storage-account'
        Get-ExerciseId -Path 'x/units/a06-storage-accounts/drills/r01-sku-reps' | Should -Be 'a06-r01-sku-reps'
        Get-ExerciseId -Path 'x/solutions/capstones/c1-landing-zone/e02-policy' | Should -Be 'c1-e02-policy'
        Get-ExerciseId -Path 'x/reps/a06-r01-sku-reps/20261121-080000' | Should -Be 'a06-r01-sku-reps'
    }
}

Describe 'Test-AnswerFile' {
    BeforeEach { $f = Join-Path ([IO.Path]::GetTempPath()) "lagb-answer-$([guid]::NewGuid().ToString('n')).md" }
    AfterEach { Remove-Item -LiteralPath $f -ErrorAction SilentlyContinue }
    It 'requires the file' { Test-AnswerFile -Path $f -Headings @('## A') | Should -Be @('ANSWER.md is missing') }
    It 'requires each heading with text under it' {
        Set-Content -LiteralPath $f -Value "## A`ntext`n## B`n"
        Test-AnswerFile -Path $f -Headings @('## A', '## B', '## C') | Should -Be @("ANSWER.md heading '## B' has no text under it", "ANSWER.md lacks heading '## C'")
    }
}

Describe 'Get-HarnessText' {
    It 'splits at the marker for below-marker and above-marker' {
        $f = Join-Path ([IO.Path]::GetTempPath()) "lagb-h-$([guid]::NewGuid().ToString('n')).bicep"
        [IO.File]::WriteAllText($f, "a`n// ---- Your resources go below this line. ----`nb`n")
        try {
            Get-HarnessText -Path $f -Region 'below-marker' | Should -Be "a`n// ---- Your resources go below this line. ----"
            Get-HarnessText -Path $f -Region 'above-marker' | Should -Be "// ---- Your resources go below this line. ----`nb`n"
            Get-HarnessText -Path $f -Region 'whole-file' | Should -BeNullOrEmpty
        } finally { Remove-Item -LiteralPath $f }
    }
}

Describe 'Enable-AzMock' {
    AfterEach { Disable-AzMock }
    It 'answers from fixtures by longest prefix and records calls' {
        Enable-AzMock -Fixtures @{ 'account' = '"short"'; 'account show' = '{"id":"sub"}' }
        (az account show --output json | ConvertFrom-Json).id | Should -Be 'sub'
        Get-AzMockCalls | Should -Be @('account show --output json')
    }
    It 'throws on an unmatched call so nothing reaches the real CLI' {
        Enable-AzMock -Fixtures @{ 'group list' = '[]' }
        { az group delete --name x --yes } | Should -Throw '*no fixture*'
    }
    It 'removes itself' {
        Enable-AzMock -Fixtures @{}
        Disable-AzMock
        Test-Path function:global:az | Should -BeFalse
    }
}

Describe 'lib/templates Bicep (needs Bicep)' {
    It 'every reference template builds and lints clean: <_>' -ForEach @(Get-ChildItem (Join-Path $PSScriptRoot '../../lib/templates') -Filter *.bicep | ForEach-Object Name) {
        $p = Join-Path $PSScriptRoot "../../lib/templates/$_"
        (Invoke-BicepBuild -Path $p).Errors | Should -BeNullOrEmpty
        @(Get-LintFindings -Path $p | ForEach-Object { "$($_.RuleId): $($_.Message)" }) | Should -BeNullOrEmpty
    }
}
