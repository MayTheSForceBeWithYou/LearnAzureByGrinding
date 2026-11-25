@{
    Tags            = @('WRITE', 'LAB')
    Entry           = 'up.sub-scope.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectResources = @('Microsoft.Consumption/budgets', 'Microsoft.Insights/actionGroups')
}
