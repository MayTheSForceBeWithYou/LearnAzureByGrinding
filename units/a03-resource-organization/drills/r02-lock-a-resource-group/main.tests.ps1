BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a03-r02-lock-a-resource-group' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'the resource group uses the lagb- prefix and the course tag' {
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

    It 'the lock is CanNotDelete on the resource group' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Authorization/locks'; Path = 'properties.level'; Value = 'CanNotDelete' }
        ) | Should -BeNullOrEmpty
        $lock = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/locks')
        $lock.Count | Should -Be 1
        $scope = Get-PropertyValue -Object $lock[0].Resource -Path 'scope'
        $scope.Found | Should -BeTrue
        "$($scope.Value)" | Should -Match 'resourceGroups'
    }
}
