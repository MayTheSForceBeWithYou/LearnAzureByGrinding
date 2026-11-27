@{
    Tags            = @('WRITE')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @(
        'Microsoft.KeyVault/vaults'
        'Microsoft.KeyVault/vaults/keys'
        'Microsoft.ManagedIdentity/userAssignedIdentities'
        'Microsoft.Authorization/roleAssignments'
        'Microsoft.Storage/storageAccounts'
    )
}
