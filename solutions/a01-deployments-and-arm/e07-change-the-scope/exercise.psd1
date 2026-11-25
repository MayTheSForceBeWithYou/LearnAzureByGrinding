@{
    Tags            = @('MODIFY')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'whole-file'
    ExpectResources = @('Microsoft.Resources/resourceGroups')
    ExpectProperties = @(
        @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'location'; Match = '.+' }
    )
}
