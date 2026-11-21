# Harness for a WRITE exercise: compile the entry, then assert structure over the compiled JSON.
BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a99-e01-storage' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }
    It 'declares every output in ExpectOutputs' {
        Test-ExpectOutputs -Template $template -Names $manifest.ExpectOutputs | Should -BeNullOrEmpty
    }
    It 'the storage account refuses plain HTTP (a dummy resource does not pass)' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
        ) | Should -BeNullOrEmpty
    }
}
