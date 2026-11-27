BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-r02-enable-blob-versioning' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'enables blob versioning and the change feed on blobServices/default' {
        $blob = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts/blobServices')
        $blob.Count | Should -Be 1
        "$($blob[0].Name)" | Should -Match 'default'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts/blobServices'; Path = 'properties.isVersioningEnabled'; Value = $true }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts/blobServices'; Path = 'properties.changeFeed.enabled'; Value = $true }
        ) | Should -BeNullOrEmpty
        $days = Get-PropertyValue -Object $blob[0].Resource -Path 'properties.changeFeed.retentionInDays'
        $days.Found | Should -BeTrue
    }
}
