BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a06-e06-object-replication' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'has two StorageV2 accounts with HTTPS, TLS 1.2, no public blobs, and no shared key' {
        $st = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts')
        $st.Count | Should -Be 2
        foreach ($a in $st) {
            "$($a.Name)" | Should -Match 'lagb'
            (Get-PropertyValue -Object $a.Resource -Path 'kind').Value | Should -Be 'StorageV2'
            (Get-PropertyValue -Object $a.Resource -Path 'properties.supportsHttpsTrafficOnly').Value | Should -BeTrue
            (Get-PropertyValue -Object $a.Resource -Path 'properties.minimumTlsVersion').Value | Should -Be 'TLS1_2'
            (Get-PropertyValue -Object $a.Resource -Path 'properties.allowBlobPublicAccess').Value | Should -BeFalse
            (Get-PropertyValue -Object $a.Resource -Path 'properties.allowSharedKeyAccess').Value | Should -BeFalse
            (Get-PropertyValue -Object $a.Resource -Path 'tags.course').Value | Should -Be 'LearnAzureByGrinding'
        }
    }

    It 'enables blob versioning on both accounts and change feed on the source' {
        $blob = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts/blobServices')
        $blob.Count | Should -BeGreaterThan 1
        $versioned = @($blob | Where-Object {
                $v = Get-PropertyValue -Object $_.Resource -Path 'properties.isVersioningEnabled'
                $v.Found -and $v.Value -eq $true
            })
        $versioned.Count | Should -BeGreaterThan 1
        $feed = @($blob | Where-Object {
                $c = Get-PropertyValue -Object $_.Resource -Path 'properties.changeFeed.enabled'
                $c.Found -and $c.Value -eq $true
            })
        $feed.Count | Should -BeGreaterThan 0
    }

    It 'declares containers and object replication policies: destination policyId default first, source uses that policy id' {
        $c = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts/blobServices/containers')
        $c.Count | Should -BeGreaterThan 1
        $orp = @(Get-TemplateResources -Template $template -Type 'Microsoft.Storage/storageAccounts/objectReplicationPolicies')
        $orp.Count | Should -Be 2
        $names = @($orp | ForEach-Object { [string]$_.Name })
        ($names | Where-Object { $_ -match 'default' }).Count | Should -BeGreaterThan 0
        ($names | Where-Object { $_ -match 'policyId|objectReplicationPolicies' }).Count | Should -BeGreaterThan 0
        $raw = ConvertTo-Json $template -Depth 50 -Compress
        $raw | Should -Match 'ruleId'
    }
}
