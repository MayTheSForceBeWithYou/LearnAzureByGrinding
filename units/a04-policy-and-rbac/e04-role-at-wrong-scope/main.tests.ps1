BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a04-e04-role-at-wrong-scope' {
    It 'assigns built-in Reader' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $rd = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.roleDefinitionId'
        $rd.Found | Should -BeTrue
        $principal = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.principalId'
        $principal.Found | Should -BeTrue
        "$($principal.Value)" | Should -Match 'principalId'
        $pt = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.principalType'
        $pt.Found | Should -BeTrue
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
        $raw | Should -Match 'subscriptionResourceId'
    }

    It 'names the assignment with guid(...), not a hard-coded or newGuid name' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $n = [string]$ra[0].Name
        $n | Should -Match '\[guid\('
        $n | Should -Not -Match 'newGuid\('
        $n | Should -Not -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
        $n | Should -Match 'principalId'
    }

    It 'the assignment is at resource-group scope, not subscription' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $scope = Get-PropertyValue -Object $ra[0].Resource -Path 'scope'
        $scope.Found | Should -BeTrue
        "$($scope.Value)" | Should -Match 'resourceGroups'
        $n = [string]$ra[0].Name
        $n | Should -Match 'resourceGroups|resourceId\('
        $n | Should -Not -Match 'subscription\(\)\.id'
    }
}
