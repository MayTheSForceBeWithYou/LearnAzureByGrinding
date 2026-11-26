@{
    Tags            = @('DRILL')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @('Microsoft.Authorization/policyAssignments')
}
