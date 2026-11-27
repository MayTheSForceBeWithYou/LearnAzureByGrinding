#Requires -Version 7.4
<#
.SYNOPSIS
  Tests of the harness itself (SPEC 8.6).
.DESCRIPTION
  1. Unit tests for lib/AzGrinding (scripts/selftest/AzGrinding.Tests.ps1).
  2. Builds throwaway course trees in the OS temp dir from scripts/selftest/fixtures and runs
     verify-all.ps1 against each, asserting the exit code, the rows it must print, and that
     the tree is byte-for-byte unchanged afterwards. The temp dir is deleted at the end.
  Exit 0 when every case behaves; 1 otherwise; 2 for a missing toolchain.
.PARAMETER Case
  Run only cases whose name matches this wildcard.
#>
[CmdletBinding()]
param([string]$Case = '*', [switch]$KeepTemp)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$repo = Split-Path $PSScriptRoot -Parent
$fx = Join-Path $PSScriptRoot 'selftest/fixtures'
Import-Module (Join-Path $repo 'lib/AzGrinding.psd1') -Force
try { $null = Get-BicepPath } catch { Write-Host "selftest: $_"; exit 2 }
$pwshExe = (Get-Process -Id $PID).Path
$tmpBase = Join-Path ([IO.Path]::GetTempPath()) ('lagb-selftest-' + [guid]::NewGuid().ToString('n').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $tmpBase
$failures = [System.Collections.Generic.List[string]]::new()

# ---------------------------------------------------------------- 1. lib unit tests
if ('lib' -like $Case) {
    Import-Module Pester -MinimumVersion 5.0.0 -MaximumVersion 5.999.999
    $c = New-PesterConfiguration
    $c.Run.Path = Join-Path $PSScriptRoot 'selftest/AzGrinding.Tests.ps1'
    $c.Run.PassThru = $true
    $c.Output.Verbosity = 'Normal'
    $r = Invoke-Pester -Configuration $c
    if ($r.Result -ne 'Passed') { $failures.Add('lib unit tests') }
}

# ---------------------------------------------------------------- 2. verify-all cases
function New-Tree([string]$Name) {
    $t = Join-Path $tmpBase $Name
    $null = New-Item -ItemType Directory -Path (Join-Path $t 'scripts')
    Copy-Item -Recurse (Join-Path $repo 'lib') $t
    Copy-Item -Recurse (Join-Path $repo 'scripts/internal') (Join-Path $t 'scripts')
    Copy-Item (Join-Path $repo 'scripts/verify-all.ps1'), (Join-Path $repo 'scripts/toolchain.psd1') (Join-Path $t 'scripts')
    Copy-Item (Join-Path $repo 'bicepconfig.json'), (Join-Path $repo 'ps-rule.yaml') $t
    $t
}
function Put([string]$Tree, [string]$From, [string]$To) {
    $dest = Join-Path $Tree $To
    $null = New-Item -ItemType Directory -Force -Path $dest
    Copy-Item -Recurse -Path (Join-Path $fx "$From/*") -Destination $dest
}
function Set-Text([string]$Tree, [string]$Rel, [string]$Text) {
    $p = Join-Path $Tree $Rel
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $p -Parent)
    [IO.File]::WriteAllText($p, $Text.Replace("`r`n", "`n"))
}
function Get-TreeState([string]$Tree) {
    Get-ChildItem -LiteralPath $Tree -Recurse -File -Force | Sort-Object FullName |
        ForEach-Object { "$([IO.Path]::GetRelativePath($Tree, $_.FullName))|$((Get-FileHash -LiteralPath $_.FullName).Hash)" }
}
$U = 'units/a99-selftest'; $S = 'solutions/a99-selftest'
$cases = [ordered]@{}
function Add-Case([string]$Name, [scriptblock]$Build, [int]$Exit, [string[]]$Expect = @(), [string[]]$Absent = @(), [string[]]$VerifyArgs = @()) {
    $cases[$Name] = @{ Build = $Build; Exit = $Exit; Expect = $Expect; Absent = $Absent; Args = $VerifyArgs }
}

Add-Case 'empty-tree-passes' { param($t) } 0 @('0 items checked', 'OK (empty course tree)')
Add-Case 'empty-tree-require-items' { param($t) } 1 @('-RequireItems') -VerifyArgs @('-RequireItems')
Add-Case 'write-scaffold-ok-and-solution-pass' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    Put $t 'lesson-demo' "$U/lesson-demo"
    Set-Text $t "$U/LESSON.md" "# A99: Selftest`n"
} 0 @('scaffold OK: structural tests fail pending: Microsoft.Storage/storageAccounts', 'a99-e01-storage: all checks passed',
    'lesson demo passes like a solution', '3 passed, 0 failed, 0 skipped')
Add-Case 'write-starter-that-passes-is-flagged' {
    param($t)
    Put $t 'write-storage/solution' "$U/e01-storage"; Remove-Item (Join-Path $t "$U/e01-storage/NOTES.md")
    Put $t 'write-storage/solution' "$S/e01-storage"
} 1 @('starter already satisfies its Expect* list', 'starter PASSES its tests') -VerifyArgs @('-NoPSRule')
Add-Case 'write-starter-compile-error-is-exercise-bug' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    Add-Content -LiteralPath (Join-Path $t "$U/e01-storage/main.bicep") -Value "resource broken 'Microsoft.Storage/storageAccounts@2023-05-01' = {"
} 1 @('does not compile', 'exercise bug: a starter must compile') -VerifyArgs @('-NoPSRule')
Add-Case 'write-stop-line-is-rejected' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    Add-Content -LiteralPath (Join-Path $t "$U/e01-storage/main.bicep") -Value '#disable-next-line no-unused-params'
} 1 @('stop line or suppression in main.bicep') -VerifyArgs @('-NoPSRule')
Add-Case 'dummy-resource-fails-the-sample-test' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    Copy-Item (Join-Path $fx 'write-storage/dummy.bicep') (Join-Path $t "$S/e01-storage/main.bicep") -Force
} 1 @('Pester test(s) failed', 'refuses plain HTTP') -VerifyArgs @('-NoPSRule')
Add-Case 'fidelity-harness-file-drift' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    Add-Content -LiteralPath (Join-Path $t "$S/e01-storage/main.tests.ps1") -Value '# edited in the solution'
} 1 @('fidelity: harness file main.tests.ps1 is not byte-identical') -VerifyArgs @('-NoPSRule')
Add-Case 'fidelity-edit-above-marker' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"; Put $t 'write-storage/solution' "$S/e01-storage"
    $p = Join-Path $t "$S/e01-storage/main.bicep"
    [IO.File]::WriteAllText($p, ([IO.File]::ReadAllText($p) -replace 'targetScope', "metadata note = 'x'`ntargetScope"))
} 1 @('fidelity: main.bicep differs from the starter above the marker') -VerifyArgs @('-NoPSRule')
Add-Case 'missing-and-orphan-solutions-fail' {
    param($t)
    Put $t 'write-storage/starter' "$U/e01-storage"
    Put $t 'write-storage/solution' "$S/e09-nobody"
} 1 @('missing solution', 'orphan solution') -VerifyArgs @('-NoPSRule')
Add-Case 'stray-paths-are-counted-skips' {
    param($t)
    Set-Text $t "$U/notes.txt" "stray`n"
    Set-Text $t 'units/scratch/README.md' "stray`n"
} 1 @('SKIP', 'units/a99-selftest/notes.txt', 'units/scratch', '2 skipped')
Add-Case 'bug-fails-exactly-expectdiagnostics' {
    param($t)
    Put $t 'bug-https/starter' "$U/e02-https-bug"; Put $t 'bug-https/solution' "$S/e02-https-bug"
} 0 @('bug OK: starter fails exactly Azure.Storage.SecureTransfer', 'a99-e02-https-bug: all checks passed')
Add-Case 'bug-pester-only-zero-diagnostics' {
    param($t)
    Put $t 'bug-pester-only/starter' "$U/e07-pester-bug"; Put $t 'bug-pester-only/solution' "$S/e07-pester-bug"
} 0 @('bug OK: Pester fails on the defect', 'output ready is true', 'a99-e07-pester-bug: all checks passed') @("The property 'Count' cannot be found", 'PropertyNotFoundException')
Add-Case 'bug-pester-only-one-diagnostic-does-not-throw' {
    param($t)
    Put $t 'bug-pester-only/starter' "$U/e07-pester-bug"; Put $t 'bug-pester-only/solution' "$S/e07-pester-bug"
    Add-Content -LiteralPath (Join-Path $t "$U/e07-pester-bug/main.bicep") -Value "`n@description('Unused; one lint diagnostic.')`nparam unused string = 'x'`n"
} 1 @('BUG starter has diagnostics but no ExpectDiagnostics: no-unused-params') @("The property 'Count' cannot be found", 'PropertyNotFoundException')
Add-Case 'bug-wrong-expectdiagnostics-fails' {
    param($t)
    Put $t 'bug-https/starter' "$U/e02-https-bug"; Put $t 'bug-https/solution' "$S/e02-https-bug"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e02-https-bug/exercise.psd1"
        [IO.File]::WriteAllText($p, ([IO.File]::ReadAllText($p) -replace 'Azure.Storage.SecureTransfer', 'Azure.Storage.MinTLS'))
    }
} 1 @('BUG starter does not fail ExpectDiagnostics: Azure.Storage.MinTLS', 'fails rules not in ExpectDiagnostics: Azure.Storage.SecureTransfer')
Add-Case 'modify-expectproperties' {
    param($t)
    Put $t 'modify-sku/starter' "$U/e03-cheaper-sku"; Put $t 'modify-sku/solution' "$S/e03-cheaper-sku"
} 0 @('scaffold OK: structural tests fail pending: Microsoft.Storage/storageAccounts sku.name = "Standard_LRS"', 'a99-e03-cheaper-sku: all checks passed')
Add-Case 'cli-drill-with-mocked-az' {
    param($t)
    Put $t 'cli-drill/starter' "$U/drills/r01-course-groups"; Put $t 'cli-drill/solution' "$S/drills/r01-course-groups"
    Set-Text $t "$U/drills/README.md" "# Drills`n"
} 0 @('scaffold OK: structural tests fail pending:', 'a99-r01-course-groups: all checks passed')
Add-Case 'cli-drill-without-mock-is-no-live' {
    param($t)
    Put $t 'cli-drill/starter' "$U/drills/r01-course-groups"; Put $t 'cli-drill/solution' "$S/drills/r01-course-groups"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/drills/r01-course-groups/main.tests.ps1"
        $txt = [IO.File]::ReadAllText($p) -replace '(?s)    Enable-AzMock -Fixtures @\{.*?\n    \}\n', '' -replace 'AfterAll \{ Disable-AzMock \}', ''
        [IO.File]::WriteAllText($p, $txt)
    }
} 1 @('NO-LIVE')
Add-Case 'explain-answer-pass' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
} 0 @('offline checks pass; graded artefact is ANSWER.md', 'a99-e04-explain-output: all checks passed') -VerifyArgs @('-NoPSRule')
Add-Case 'answer-missing-heading-fails' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
    Set-Text $t "$S/e04-explain-output/ANSWER.md" "# a99-e04`n`n## What the output is`nThe string lagb-demo.`n"
} 1 @("ANSWER.md lacks heading '## Why'") -VerifyArgs @('-NoPSRule')
Add-Case 'empty-answer-fails' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
    Set-Text $t "$S/e04-explain-output/ANSWER.md" "   `n"
} 1 @('ANSWER.md is empty') -VerifyArgs @('-NoPSRule')
Add-Case 'whatif-real-capture-passes' {
    param($t)
    Put $t 'whatif/starter' "$U/e05-whatif"; Put $t 'whatif/solution' "$S/e05-whatif"
    $h = (Get-FileHash (Join-Path $t "$U/e05-whatif/main.bicep") -Algorithm SHA256).Hash.ToLowerInvariant()
    $cap = "# source: main.bicep sha256=$h`nResource and property changes are indicated with this symbol:`n  = NoChange`n"
    Set-Text $t "$U/e05-whatif/capture.txt" $cap; Set-Text $t "$S/e05-whatif/capture.txt" $cap
} 0 @('a99-e05-whatif: all checks passed') -VerifyArgs @('-NoPSRule')
Add-Case 'whatif-output-pending-and-stale-fail' {
    param($t)
    Put $t 'whatif/starter' "$U/e05-whatif"; Put $t 'whatif/solution' "$S/e05-whatif"
    Set-Text $t "$U/e05-whatif/capture.txt" "OUTPUT-PENDING`n"; Set-Text $t "$S/e05-whatif/capture.txt" "OUTPUT-PENDING`n"
    Put $t 'whatif/starter' "$U/e06-whatif-stale"; Put $t 'whatif/solution' "$S/e06-whatif-stale"
    $stale = "# source: main.bicep sha256=$('0' * 64)`n  = NoChange`n"
    Set-Text $t "$U/e06-whatif-stale/capture.txt" $stale; Set-Text $t "$S/e06-whatif-stale/capture.txt" $stale
} 1 @('OUTPUT-PENDING in capture.txt', 'STALE: capture.txt') -VerifyArgs @('-NoPSRule')
Add-Case 'manifest-errors-fail' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e04-explain-output/exercise.psd1"
        [IO.File]::WriteAllText($p, ([IO.File]::ReadAllText($p) -replace "'EXPLAIN'", "'EXPLAIN', 'SHINY'" -replace 'whole-file', 'middle'))
    }
} 1 @("unknown tag 'SHINY'", "StudentRegion 'middle'") -VerifyArgs @('-NoPSRule')
Add-Case 'cli-starter-fails-tests-declared' {
    param($t)
    Put $t 'cli-drill/starter' "$U/e08-cli-script"; Put $t 'cli-drill/solution' "$S/e08-cli-script"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e08-cli-script/exercise.psd1"
        $txt = [IO.File]::ReadAllText($p).Replace("Tags          = @('DRILL', 'CLI')", "Tags          = @('CLI')`n    StarterFailsTests = `$true")
        [IO.File]::WriteAllText($p, $txt)
    }
} 0 @('scaffold OK: structural tests fail pending:', 'a99-e08-cli-script: all checks passed') -VerifyArgs @('-NoPSRule')
Add-Case 'cli-starter-fails-tests-undeclared' {
    param($t)
    Put $t 'cli-drill/starter' "$U/e08-cli-script"; Put $t 'cli-drill/solution' "$S/e08-cli-script"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e08-cli-script/exercise.psd1"
        $txt = [IO.File]::ReadAllText($p).Replace("Tags          = @('DRILL', 'CLI')", "Tags          = @('CLI')")
        [IO.File]::WriteAllText($p, $txt)
    }
} 1 @('shipped checks must pass for CLI') -VerifyArgs @('-NoPSRule')
Add-Case 'cli-starter-fails-tests-wrong-tag' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e04-explain-output/exercise.psd1"
        $txt = [IO.File]::ReadAllText($p).Replace("Tags           = @('EXPLAIN')", "Tags           = @('EXPLAIN')`n    StarterFailsTests = `$true")
        [IO.File]::WriteAllText($p, $txt)
    }
} 1 @('StarterFailsTests is only allowed when the primary tag is CLI') -VerifyArgs @('-NoPSRule')
Add-Case 'cli-starter-fails-tests-pass' {
    # Key cannot go stale: a starter that already passes Pester is rejected even with the key.
    param($t)
    Put $t 'cli-drill/solution' "$U/e08-cli-script"; Remove-Item (Join-Path $t "$U/e08-cli-script/NOTES.md") -ErrorAction SilentlyContinue
    Put $t 'cli-drill/solution' "$S/e08-cli-script"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e08-cli-script/exercise.psd1"
        $txt = [IO.File]::ReadAllText($p).Replace("Tags          = @('DRILL', 'CLI')", "Tags          = @('CLI')`n    StarterFailsTests = `$true")
        [IO.File]::WriteAllText($p, $txt)
    }
} 1 @('starter PASSES its tests; a CLI starter with StarterFailsTests must fail until the student does the work') -VerifyArgs @('-NoPSRule')
Add-Case 'cli-starter-fails-tests-solution-fails' {
    # The key does not relax the solution: an empty script as the solution still fails.
    param($t)
    Put $t 'cli-drill/starter' "$U/e08-cli-script"
    Put $t 'cli-drill/starter' "$S/e08-cli-script"
    Set-Text $t "$S/e08-cli-script/NOTES.md" "placeholder notes for a failing solution`n"
    foreach ($side in $U, $S) {
        $p = Join-Path $t "$side/e08-cli-script/exercise.psd1"
        $txt = [IO.File]::ReadAllText($p).Replace("Tags          = @('DRILL', 'CLI')", "Tags          = @('CLI')`n    StarterFailsTests = `$true")
        [IO.File]::WriteAllText($p, $txt)
    }
} 1 @('Pester test(s) failed') -VerifyArgs @('-NoPSRule')
Add-Case 'only-filter-and-mirror' {
    param($t)
    Put $t 'explain/starter' "$U/e04-explain-output"; Put $t 'explain/solution' "$S/e04-explain-output"
    Put $t 'write-storage/starter' "$U/e01-storage"   # no solution: would fail if in scope
} 0 @('a99-e04-explain-output: all checks passed', 'solutions/a99-selftest/e04-explain-output') @('e01-storage') -VerifyArgs @('-NoPSRule', '-Only', "$U/e04-explain-output")

$n = 0
foreach ($name in $cases.Keys) {
    if ($name -notlike $Case) { continue }
    $n++
    $c = $cases[$name]
    $tree = New-Tree $name
    & $c.Build $tree
    $before = Get-TreeState $tree
    $args2 = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $tree 'scripts/verify-all.ps1'), '-Root', $tree) + $c.Args
    $out = (& $pwshExe @args2 *>&1 | Out-String)
    $code = $LASTEXITCODE
    $after = Get-TreeState $tree
    $why = [System.Collections.Generic.List[string]]::new()
    if ($code -ne $c.Exit) { $why.Add("exit $code, expected $($c.Exit)") }
    foreach ($e in $c.Expect) { if (-not $out.Contains($e)) { $why.Add("missing text: $e") } }
    foreach ($e in $c.Absent) { if ($out.Contains($e)) { $why.Add("unexpected text: $e") } }
    if (Compare-Object @($before) @($after)) { $why.Add('verify-all changed the tree (it must leave it clean)') }
    if ($why.Count) {
        $failures.Add($name)
        Write-Host "FAIL  $name" -ForegroundColor Red
        foreach ($w in $why) { Write-Host "      $w" }
        Write-Host ($out -split "`n" | ForEach-Object { "      | $_" } | Out-String)
    } else { Write-Host "ok    $name" -ForegroundColor Green }
}

if (-not $KeepTemp) { Remove-Item -Recurse -Force -LiteralPath $tmpBase -ErrorAction SilentlyContinue } else { Write-Host "kept $tmpBase" }
Write-Host ''
if ($failures.Count) { Write-Host "selftest: FAIL ($($failures -join ', '))"; exit 1 }
Write-Host "selftest: OK ($n verify-all case(s)$(if ('lib' -like $Case) { ' + lib unit tests' }))"
exit 0
