@{
    Tags            = @('DRILL')
    Entry           = 'azuredeploy.json'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'whole-file'
    ExpectResources = @('Microsoft.Storage/storageAccounts')
    ExpectOutputs     = @('accountName')
    ExpectProperties = @(
        @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'properties.minimumTlsVersion'; Value = 'TLS1_2' }
    )
}
