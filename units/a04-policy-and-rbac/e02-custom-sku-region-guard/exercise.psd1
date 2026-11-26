@{
    Tags            = @('WRITE', 'LAB')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @('Microsoft.Authorization/policyDefinitions', 'Microsoft.Authorization/policyAssignments')
}
