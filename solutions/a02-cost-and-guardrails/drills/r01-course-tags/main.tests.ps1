BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a02-r01-course-tags' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }
    It 'the storage account refuses plain HTTP' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
        ) | Should -BeNullOrEmpty
    }

    It 'sets the five course tags on the storage account' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.course'; Value = 'LearnAzureByGrinding' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.unit'; Value = 'a02-cost-and-guardrails' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.exercise'; Match = '.' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.owner'; Match = '.' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.expires'; Match = '.' }
        ) | Should -BeNullOrEmpty
    }
}
