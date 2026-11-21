@{
    RootModule        = 'AzGrinding.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '5d0b8f4e-3c55-4a43-9a8e-7f1f2c6a9b10'
    Author            = 'LearnAzureByGrinding'
    Description       = 'Shared offline helpers for LearnAzureByGrinding exercises, drills, and the verify harness.'
    PowerShellVersion = '7.4'
    FunctionsToExport = @(
        'Get-CourseRoot', 'Get-Toolchain', 'Get-BicepPath',
        'Get-ExerciseManifest', 'Test-ExerciseManifest', 'Get-ExerciseId', 'Get-ExerciseKind',
        'Invoke-BicepBuild', 'Invoke-BicepLint', 'Get-LintFindings', 'Invoke-CoursePSRule', 'Test-PowerShellParse',
        'Get-CompiledTemplate', 'Get-TemplateResources', 'Get-TemplateOutputNames', 'Get-PropertyValue',
        'Test-ExpectResources', 'Test-ExpectOutputs', 'Test-ExpectProperties',
        'Assert-ExpectResources', 'Assert-ExpectOutputs', 'Assert-ExpectProperties',
        'Test-AnswerFile', 'Find-OutputPending', 'Test-CaptureHashes',
        'Enable-AzMock', 'Disable-AzMock', 'Get-AzMockCalls',
        'Get-MarkerLineIndex', 'Get-HarnessText', 'Write-ChecksPassed'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
