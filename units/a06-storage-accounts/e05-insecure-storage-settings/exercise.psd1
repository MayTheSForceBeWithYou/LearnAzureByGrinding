@{
    Tags                = @('BUG')
    Entry               = 'main.bicep'
    Test                = 'main.tests.ps1'
    StudentRegion       = 'whole-file'
    ExpectDiagnostics   = @('Azure.Storage.MinTLS')
    AnswerHeadings      = @('## What was wrong', '## Mechanism', '## Which tool showed it')
}
