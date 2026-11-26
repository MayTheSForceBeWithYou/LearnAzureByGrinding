@{
    Tags            = @('WRITE')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @('Microsoft.Resources/resourceGroups')
}
