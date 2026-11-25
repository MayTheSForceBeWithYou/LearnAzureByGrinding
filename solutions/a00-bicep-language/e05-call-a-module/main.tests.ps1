BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a00-e05-call-a-module' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }
    It 'declares every output in ExpectOutputs' {
        Test-ExpectOutputs -Template $template -Names $manifest.ExpectOutputs | Should -BeNullOrEmpty
    }
    It 'the storage account refuses plain HTTP' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
        ) | Should -BeNullOrEmpty
    }
}
