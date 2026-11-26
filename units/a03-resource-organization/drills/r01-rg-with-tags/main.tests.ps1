BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a03-r01-rg-with-tags' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'the resource group uses the lagb- prefix and the course tag set' {
        $rg = @(Get-TemplateResources -Template $template -Type 'Microsoft.Resources/resourceGroups')
        $rg.Count | Should -Be 1
        "$($rg[0].Name)" | Should -Match 'lagb-'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'location'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.course'; Value = 'LearnAzureByGrinding' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.unit'; Value = 'a03-resource-organization' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.exercise'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.owner'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.expires'; Match = '.' }
        ) | Should -BeNullOrEmpty
    }
}
