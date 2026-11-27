BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-e05-insecure-storage-settings' {
    It 'still declares a storage account' {
        @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts').Count | Should -Be 1
    }

    It 'disallows anonymous blob public access' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.allowBlobPublicAccess'; Value = $false }
        ) | Should -BeNullOrEmpty
    }

    It 'requires TLS 1.2' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
        ) | Should -BeNullOrEmpty
    }
}
