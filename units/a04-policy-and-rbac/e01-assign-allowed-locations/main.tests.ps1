BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a04-e01-assign-allowed-locations' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'references the built-in Allowed locations definition by resource id, and does not copy it' {
        $as = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyAssignments')
        $as.Count | Should -Be 1
        $defId = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyDefinitionId'
        $defId.Found | Should -BeTrue
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
        $raw | Should -Match 'tenantResourceId|/providers/Microsoft\.Authorization/policyDefinitions/'
        $raw | Should -Not -Match "subscriptionResourceId\('Microsoft\.Authorization/policyDefinitions'"
        $copied = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyRule'
        $copied.Found | Should -BeFalse
    }

    It 'passes listOfAllowedLocations including eastus' {
        $as = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyAssignments')
        $as.Count | Should -Be 1
        $p = Get-PropertyValue -Object $as[0].Resource -Path 'properties.parameters.listOfAllowedLocations'
        $p.Found | Should -BeTrue
        "$(ConvertTo-Json $p.Value -Compress)" | Should -Match 'eastus|allowedLocations'
    }
}
