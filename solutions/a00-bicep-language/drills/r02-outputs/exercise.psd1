@{
    Tags            = @('DRILL')
    Entry           = 'main.bicep'
    Test            = 'main.tests.ps1'
    StudentRegion   = 'below-marker'
    ExpectOutputs   = @('accountName', 'accountId')
}
