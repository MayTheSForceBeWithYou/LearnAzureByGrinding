@{
    Tags            = @('WRITE', 'LAB')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @(
        'Microsoft.Storage/storageAccounts'
        'Microsoft.Storage/storageAccounts/blobServices'
        'Microsoft.Storage/storageAccounts/blobServices/containers'
        'Microsoft.Storage/storageAccounts/objectReplicationPolicies'
    )
}
