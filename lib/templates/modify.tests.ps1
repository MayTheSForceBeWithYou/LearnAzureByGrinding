# Harness for a MODIFY exercise: the expected change is listed in exercise.psd1 ExpectProperties.
BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a99-e03-cheaper-sku' {
    It 'still declares the storage account' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }
    It 'has the change listed in ExpectProperties' {
        Test-ExpectProperties -Template $template -Expect $manifest.ExpectProperties | Should -BeNullOrEmpty
    }
}
