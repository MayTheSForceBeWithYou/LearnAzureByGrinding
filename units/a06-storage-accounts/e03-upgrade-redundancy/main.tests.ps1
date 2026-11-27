BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-e03-upgrade-redundancy' {
    It 'still declares the storage account' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'has the change listed in ExpectProperties' {
        Test-ExpectProperties -Template $template -Expect $manifest.ExpectProperties | Should -BeNullOrEmpty
    }

    It 'keeps HTTPS, TLS 1.2, no public blobs, and no shared key' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowBlobPublicAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowSharedKeyAccess'; Value = $false }
        ) | Should -BeNullOrEmpty
    }
}
