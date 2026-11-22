@{
    Tags            = @('MODIFY')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'whole-file'
    ExpectResources = @('Microsoft.Storage/storageAccounts')
    ExpectProperties = @(
        @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Value = 'Standard_LRS' }
    )
}
