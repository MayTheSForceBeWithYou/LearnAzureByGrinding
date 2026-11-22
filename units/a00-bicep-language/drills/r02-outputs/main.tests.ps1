BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a00-r02-outputs' {
    It 'declares every output in ExpectOutputs' {
        Test-ExpectOutputs -Template $template -Names $manifest.ExpectOutputs | Should -BeNullOrEmpty
    }
}
