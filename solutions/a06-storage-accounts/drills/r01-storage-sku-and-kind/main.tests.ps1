BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-r01-storage-sku-and-kind' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'uses the sku, kind, and access tier parameters, with HTTPS and no shared key' {
        $st = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts')
        $st.Count | Should -Be 1
        "$($st[0].Name)" | Should -Match 'lagb'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Match = 'skuName' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'kind'; Match = 'kind' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.accessTier'; Match = 'accessTier' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowBlobPublicAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowSharedKeyAccess'; Value = $false }
        ) | Should -BeNullOrEmpty
    }
}
