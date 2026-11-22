# Harness for a Pester-only [BUG]: the starter compiles and is lint-clean; this test fails until ready is true.
BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $template = Get-CompiledTemplate -Directory $PSScriptRoot
}

Describe 'a99-e07-pester-bug' {
    It 'output ready is true (the starter ships false)' {
        $template.outputs.ready.value | Should -Be $true
    }
}
