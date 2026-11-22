BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a01-e07-change-the-scope' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }
    It 'has the change listed in ExpectProperties' {
        Test-ExpectProperties -Template $template -Expect $manifest.ExpectProperties | Should -BeNullOrEmpty
    }

    It 'compiles to the subscription deployment schema' {
        $template['$schema'] | Should -Match 'subscriptionDeploymentTemplate.json'
    }
}
