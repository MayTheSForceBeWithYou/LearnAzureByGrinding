# Template manifest (spec v0.3). Copy into an exercise, drill, or lesson-demo folder; the
# solution's copy must be byte-identical. Delete the keys you do not use.
@{
    # First tag is the primary tag and decides the fail-until-worked rule.
    # Words: WRITE MODIFY DRILL BUG PREDICT WHATIF EXPLAIN LAB PORTAL CLI NO-LIVE
    Tags              = @('WRITE')
    Entry             = 'main.bicep'          # .bicep, ARM .json, or .ps1 (CLI drills)
    Test              = 'main.tests.ps1'      # Pester 5 harness (required for WRITE/MODIFY/DRILL)
    StudentRegion     = 'below-marker'        # below-marker | above-marker | whole-file
    ExpectResources   = @('Microsoft.Storage/storageAccounts')
    ExpectOutputs     = @('storageAccountName')
    # MODIFY: the change the student must make, checked over the compiled JSON.
    ExpectProperties  = @(
        @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Value = 'Standard_LRS' }
        # or Match = '^Standard_(LRS|ZRS)$' in place of Value
    )
    # BUG only: lint and PSRule rule names the starter fails, exactly.
    ExpectDiagnostics = @()
    # Required ANSWER.md headings (exact lines). ANSWER.md must exist, be non-empty, and have text under each.
    AnswerHeadings    = @()
    # Primary tag CLI only: the empty starter fails its Pester tests until the student writes
    # the commands (Nathan's fail-until-worked rule). The matching solution must pass. Omit
    # on every other tag (including when CLI is a modifier, not Tags[0]).
    # StarterFailsTests   = $true
}
