BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a01-e06-complete-mode' {


    It 'deploys two storage accounts and none are condition:false' {
        $accounts = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts')
        $accounts.Count | Should -Be 2
        foreach ($a in $accounts) {
            $c = Get-PropertyValue -Object $a.Resource -Path 'condition'
            if ($c.Found) { $c.Value | Should -Not -Be $false }
        }
    }
}
