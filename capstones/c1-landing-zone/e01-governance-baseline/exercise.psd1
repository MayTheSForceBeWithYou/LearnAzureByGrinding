@{
    Tags            = @('WRITE', 'LAB')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @(
        'Microsoft.Resources/resourceGroups'
        'Microsoft.Authorization/locks'
        'Microsoft.Authorization/policyAssignments'
        'Microsoft.Authorization/roleAssignments'
        'Microsoft.Consumption/budgets'
    )
}
