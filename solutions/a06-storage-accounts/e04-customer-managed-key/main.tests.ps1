BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-e04-customer-managed-key' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'the Key Vault uses RBAC, soft delete, and purge protection' {
        $kv = @(Get-TemplateResources -Template $template -Type 'Microsoft.KeyVault/vaults')
        $kv.Count | Should -Be 1
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.KeyVault/vaults'; Path = 'properties.enableRbacAuthorization'; Value = $true }
            @{ ResourceType = 'Microsoft.KeyVault/vaults'; Path = 'properties.enablePurgeProtection'; Value = $true }
        ) | Should -BeNullOrEmpty
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'enableSoftDelete|softDeleteRetentionInDays'
    }

    It 'assigns Key Vault Crypto Service Encryption User to the user-assigned identity' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -BeGreaterThan 0
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
        $raw | Should -Match 'tenantResourceId|/providers/Microsoft\.Authorization/roleDefinitions/'
        $raw | Should -Not -Match "subscriptionResourceId\('Microsoft\.Authorization/roleDefinitions'"
        $n = [string]$ra[0].Name
        $n | Should -Match '\[guid\('
        $n | Should -Not -Match 'newGuid\('
        $pt = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.principalType'
        $pt.Found | Should -BeTrue
        "$($pt.Value)" | Should -Match 'ServicePrincipal'
    }

    It 'encrypts the storage account with the Key Vault key, the user-assigned identity, and infrastructure encryption' {
        $st = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts')
        $st.Count | Should -Be 1
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowSharedKeyAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.supportsHttpsTrafficOnly'; Value = $true }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowBlobPublicAccess'; Value = $false }
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.encryption.requireInfrastructureEncryption'; Value = $true }
        ) | Should -BeNullOrEmpty
        $src = Get-PropertyValue -Object $st[0].Resource -Path 'properties.encryption.keySource'
        $src.Found | Should -BeTrue
        "$($src.Value)" | Should -Match 'Keyvault|KeyVault'
        $raw = ConvertTo-Json $st[0].Resource -Depth 40 -Compress
        $raw | Should -Match 'userAssignedIdentity|userAssignedIdentities'
    }
}
