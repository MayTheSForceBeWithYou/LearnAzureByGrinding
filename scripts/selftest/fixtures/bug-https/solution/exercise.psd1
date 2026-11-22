@{
    Tags              = @('BUG')
    Entry             = 'main.bicep'
    StudentRegion     = 'whole-file'
    ExpectDiagnostics = @('Azure.Storage.SecureTransfer')
    AnswerHeadings    = @('## What was wrong', '## Mechanism', '## Which tool showed it')
}
