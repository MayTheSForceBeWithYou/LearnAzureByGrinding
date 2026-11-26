BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a03-e04-lock-wrong-scope' {
    It 'the lock is CanNotDelete' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Authorization/locks'; Path = 'properties.level'; Value = 'CanNotDelete' }
        ) | Should -BeNullOrEmpty
    }

    It 'the lock is scoped to the resource group, not the subscription' {
        $lock = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/locks')
        $lock.Count | Should -Be 1
        $scope = Get-PropertyValue -Object $lock[0].Resource -Path 'scope'
        $scope.Found | Should -BeTrue
        "$($scope.Value)" | Should -Match 'resourceGroups'
    }
}
