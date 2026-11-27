BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-e01-storage-account-baseline' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'is StorageV2 Standard_LRS with HTTPS, TLS1_2, no public blobs, no shared key, and course tags' {
        $st = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts')
        $st.Count | Should -Be 1
        "$($st[0].Name)" | Should -Match 'lagb'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'kind'; Value = 'StorageV2' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Value = 'Standard_LRS' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowBlobPublicAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowSharedKeyAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.course'; Value = 'LearnAzureByGrinding' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.unit'; Value = 'a06-storage-accounts' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.exercise'; Match = '.' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.owner'; Match = '.' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'tags.expires'; Match = '.' }
        ) | Should -BeNullOrEmpty
    }
}
