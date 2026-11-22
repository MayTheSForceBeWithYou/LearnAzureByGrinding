@{
    Tags            = @('BUG')
    Entry           = 'main.bicep'
    StudentRegion   = 'whole-file'
    ExpectDiagnostics = @('no-hardcoded-location')
    AnswerHeadings  = @('## What was wrong', '## Mechanism', '## Which tool showed it')
}
