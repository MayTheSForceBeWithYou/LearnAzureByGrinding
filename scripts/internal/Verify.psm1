#Requires -Version 7.4
# Verify engine shared by scripts/verify-all.ps1, scripts/check.ps1, and scripts/selftest.ps1.
# Offline only. Builds go to stdout (bicep build --stdout); Pester runs in a child pwsh whose
# result is written to the OS temp dir and deleted. Nothing is written into the course tree.
Set-StrictMode -Version 3.0

$script:Pwsh = (Get-Process -Id $PID).Path
$script:Runner = Join-Path $PSScriptRoot 'pester-runner.ps1'
$script:LivePattern = '(^|[\s;|({&=])(az|az\.cmd|az\.exe)\s+[a-z]|Connect-AzAccount|Invoke-AzRestMethod|Get-AzAccessToken|New-Az\w*Deployment\b|Test-Az\w*Deployment\b|management\.azure\.com'
$script:MockPattern = 'Enable-AzMock|\bMock\s+(-CommandName\s+)?[''"]?(az|Connect-AzAccount|Invoke-AzRestMethod|Get-AzAccessToken|New-Az\w*|Test-Az\w*)\b'

function New-Result([string]$Path, [string]$Role) {
    [pscustomobject]@{ Path = $Path; Role = $Role; Problems = [System.Collections.Generic.List[string]]::new(); Verdict = ''; Notes = [System.Collections.Generic.List[string]]::new() }
}

function Invoke-IsolatedPester {
    param([Parameter(Mandatory)][string]$TestPath)
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("lagb-pester-" + [guid]::NewGuid().ToString('n') + '.json')
    try {
        $null = & $script:Pwsh -NoProfile -NonInteractive -File $script:Runner -TestPath $TestPath -ResultFile $tmp 2>&1
        if (-not (Test-Path -LiteralPath $tmp)) {
            return [pscustomobject]@{ Result = 'Crashed'; Total = 0; Passed = 0; Failed = 0; FailedTests = @(); Crashes = @('Pester runner produced no result (is Pester 5 installed?)'); NoLive = $false }
        }
        Get-Content -Raw -LiteralPath $tmp | ConvertFrom-Json -Depth 6
    } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

function Get-LiveCallFindings {
    <# NO-LIVE static scan: a non-LAB item whose PowerShell calls az / Az deployment cmdlets / ARM without a mock in its test file. #>
    param([Parameter(Mandatory)][string]$Directory, [Parameter(Mandatory)][hashtable]$Manifest)
    if ('LAB' -in $Manifest.Tags) { return @() }
    $testFile = Join-Path $Directory $Manifest.Test
    $mocked = (Test-Path -LiteralPath $testFile) -and ((Get-Content -Raw -LiteralPath $testFile) -match $script:MockPattern)
    $hits = foreach ($f in Get-ChildItem -LiteralPath $Directory -Recurse -File -Include '*.ps1', '*.psm1') {
        $n = 0
        foreach ($line in Get-Content -LiteralPath $f.FullName) {
            $n++
            $code = ($line -replace '#.*$', '')
            if ($code -match $script:LivePattern) { "$($f.Name):$n"; break }
        }
    }
    if ($hits -and -not $mocked) {
        return @("NO-LIVE: live Azure call without a mock or fixture ($(@($hits) -join ', ')); mock it with Enable-AzMock or Pester Mock, or tag the item LAB")
    }
    @()
}

function Get-Diagnostics {
    <# Lint findings (warnings + errors) and PSRule failures for a .bicep entry: names, as one sorted set. #>
    param([string]$EntryPath, [string]$Root, [switch]$NoPSRule)
    $lint = @(Get-LintFindings -Path $EntryPath)
    $ps = if ($NoPSRule) { @() } else { @(Invoke-CoursePSRule -Path $EntryPath -Root $Root) }
    [pscustomobject]@{
        Lint   = $lint
        PSRule = $ps
        Names  = @(@($lint | ForEach-Object RuleId) + $ps | Where-Object { $_ } | Sort-Object -Unique)
        Text   = @(@($lint | ForEach-Object { "lint $($_.RuleId) (line $($_.Line))" }) + @($ps | ForEach-Object { "PSRule $_" }))
    }
}

function Test-CommonOffline {
    <# Manifest, OUTPUT-PENDING, STALE captures, NO-LIVE, compile. Returns the build object (or $null). #>
    param($Res, [string]$Dir, [hashtable]$M, [string]$Kind)
    foreach ($p in (Test-ExerciseManifest -Manifest $M -Kind $Kind)) { $Res.Problems.Add("manifest: $p") }
    foreach ($f in (Find-OutputPending -Path $Dir)) { $Res.Problems.Add("OUTPUT-PENDING in $f (capture real output before merging)") }
    foreach ($p in (Test-CaptureHashes -Path $Dir)) { $Res.Problems.Add($p) }
    foreach ($p in (Get-LiveCallFindings -Directory $Dir -Manifest $M)) { $Res.Problems.Add($p) }
    $entry = Join-Path $Dir $M.Entry
    if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { return $null }
    if ($M.Entry -match '\.ps1$') {
        $errs = @(Test-PowerShellParse -Path $entry)
        if ($errs.Count) { $Res.Problems.Add("does not parse: $($errs -join '; ')") }
        return [pscustomobject]@{ Ok = (-not $errs.Count); Template = $null; Errors = $errs }
    }
    $b = Invoke-BicepBuild -Path $entry
    if (-not $b.Ok) { $Res.Problems.Add("does not compile: $(@($b.Errors | Select-Object -First 3) -join ' | ')") }
    $up = Join-Path $Dir 'up.bicep'
    if ('LAB' -in $M.Tags -and (Test-Path -LiteralPath $up) -and $M.Entry -ne 'up.bicep') {
        $ub = Invoke-BicepBuild -Path $up
        if (-not $ub.Ok) { $Res.Problems.Add("up.bicep does not compile: $(@($ub.Errors | Select-Object -First 2) -join ' | ')") }
        else { foreach ($l in (Get-LintFindings -Path $up)) { $Res.Problems.Add("up.bicep lint $($l.RuleId) (line $($l.Line))") } }
    }
    $b
}

function Format-Pester($pr) {
    if ($pr.Crashes.Count) { return "harness crashed: $(@($pr.Crashes)[0])" }
    "$($pr.Failed) of $($pr.Total) Pester test(s) failed: $(@($pr.FailedTests | Select-Object -First 2 | ForEach-Object { "$($_.Name): $($_.Error)" }) -join ' | ')"
}

function Test-StarterItem {
    <# The fail-until-worked rule for one starter (exercise or drill) by primary tag. #>
    param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Rel, [string]$Kind, [string]$Root, [switch]$NoPSRule)
    $res = New-Result $Rel 'starter'
    try { $m = Get-ExerciseManifest -Path $Dir } catch { $res.Problems.Add("$_"); return $res }
    $b = Test-CommonOffline $res $Dir $m $Kind
    if (-not $b -or -not $b.Ok) {
        if ($b) { $res.Problems.Add('exercise bug: a starter must compile (section 4.4)') }
        return $res
    }
    $isBicep = $m.Entry -match '\.bicep$'
    $diag = if ($isBicep) { Get-Diagnostics -EntryPath (Join-Path $Dir $m.Entry) -Root $Root -NoPSRule:$NoPSRule } else { $null }
    $testPath = Join-Path $Dir $m.Test
    $pr = if (Test-Path -LiteralPath $testPath -PathType Leaf) { Invoke-IsolatedPester -TestPath $testPath } else { $null }
    if ($pr -and $pr.NoLive) { $res.Problems.Add('NO-LIVE: a test reached for live Azure (the runner trapped it); mock az / Az cmdlets') }
    if ($pr -and $pr.Total -eq 0 -and -not $pr.Crashes.Count) { $res.Problems.Add("$($m.Test) contains no tests") }
    $t = $b.Template
    switch ($m.PrimaryTag) {
        { $_ -in 'WRITE', 'DRILL', 'MODIFY' } {
            foreach ($f in Get-ChildItem -LiteralPath $Dir -Recurse -File -Include '*.bicep', '*.json', '*.ps1' -Exclude '*.tests.ps1') {
                if (Select-String -LiteralPath $f.FullName -Pattern '#disable-next-line|#disable-diagnostics|#error' -Quiet) {
                    $res.Problems.Add("stop line or suppression in $($f.Name) (no #disable-next-line / #disable-diagnostics in a starter)")
                }
            }
            if ($diag) { foreach ($x in $diag.Text) { $res.Problems.Add("starter must be lint/PSRule clean: $x") } }
            $pending = @()
            if ($t) {
                if ($m.PrimaryTag -eq 'MODIFY') { $pending += Test-ExpectProperties -Template $t -Expect $m.ExpectProperties }
                $pending += Test-ExpectResources -Template $t -Types $m.ExpectResources
                $pending += Test-ExpectOutputs -Template $t -Names $m.ExpectOutputs
                $declared = $m.ExpectResources.Count + $m.ExpectOutputs.Count + $(if ($m.PrimaryTag -eq 'MODIFY') { $m.ExpectProperties.Count } else { 0 })
                if ($declared -and -not $pending.Count) { $res.Problems.Add('starter already satisfies its Expect* list; nothing is left for the student to write') }
            }
            if (-not $pr) { break }
            if ($pr.Crashes.Count) { $res.Problems.Add("starter harness crashed instead of failing an assertion: $(@($pr.Crashes)[0])") }
            elseif ($pr.Failed -eq 0) { $res.Problems.Add("starter PASSES its tests; a $($m.PrimaryTag) starter must fail until the student does the work") }
            if (-not $res.Problems.Count) {
                if (-not $pending.Count) { $pending = @($pr.FailedTests | ForEach-Object Name) }
                $res.Verdict = "scaffold OK: structural tests fail pending: $($pending -join '; ')"
            }
        }
        'BUG' {
            $want = @($m.ExpectDiagnostics | Sort-Object -Unique)
            # @() so an empty or single-element Names (PowerShell unwraps both) still has .Count under StrictMode.
            $have = @($(if ($diag) { @($diag.Names) }) | Where-Object { $_ })
            if ($pr -and @($pr.Crashes).Count) { $res.Problems.Add("starter harness crashed: $(@($pr.Crashes)[0])") }
            if ($want.Count) {
                $missing = @($want | Where-Object { $_ -notin $have })
                $extra = @($have | Where-Object { $_ -notin $want })
                if ($missing.Count) { $res.Problems.Add("BUG starter does not fail ExpectDiagnostics: $($missing -join ', ')") }
                if ($extra.Count) { $res.Problems.Add("BUG starter fails rules not in ExpectDiagnostics: $($extra -join ', ') (a bug exercise contains exactly the advertised defects)") }
                if (-not $res.Problems.Count) { $res.Verdict = "bug OK: starter fails exactly $($want -join ', ')" + $(if ($pr -and $pr.Failed) { ' and its Pester test' } else { '' }) }
            } else {
                if ($have.Count) { $res.Problems.Add("BUG starter has diagnostics but no ExpectDiagnostics: $($have -join ', ')") }
                if (-not $pr) { $res.Problems.Add('BUG starter without ExpectDiagnostics needs a failing Pester test') }
                elseif (-not @($pr.Crashes).Count -and $pr.Failed -eq 0) { $res.Problems.Add('BUG starter passes its Pester test; the defect must make a check fail') }
                if (-not $res.Problems.Count) { $res.Verdict = "bug OK: Pester fails on the defect ($(@($pr.FailedTests | ForEach-Object Name) -join '; '))" }
            }
        }
        default {
            # PREDICT, EXPLAIN, WHATIF, PORTAL, CLI: shipped checks pass; the prose is the work.
            if ($diag) { foreach ($x in $diag.Text) { $res.Problems.Add("shipped file must be lint/PSRule clean: $x") } }
            if ($pr -and ($pr.Crashes.Count -or $pr.Failed)) { $res.Problems.Add("shipped checks must pass for $($m.PrimaryTag): $(Format-Pester $pr)") }
            $ans = Join-Path $Dir 'ANSWER.md'
            if ((Test-Path -LiteralPath $ans) -and $m.AnswerHeadings.Count) { foreach ($p in (Test-AnswerFile -Path $ans -Headings $m.AnswerHeadings)) { $res.Problems.Add($p) } }
            if (-not $res.Problems.Count) { $res.Verdict = "offline checks pass; graded artefact is $(if ($m.AnswerHeadings.Count) { 'ANSWER.md' } else { 'the student''s work' })" }
        }
    }
    if ('LAB' -in $m.Tags) { $res.Notes.Add('offline only; live steps not run') }
    $res
}

function Test-WorkedItem {
    <#
      The pass rule for completed work: a solution, a lesson-demo with a manifest, or a student's
      own folder (scripts/check.ps1). Compiles, lint/PSRule clean, Expect* satisfied, Pester passes,
      ANSWER.md complete when AnswerHeadings is set.
    #>
    param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Rel, [string]$Kind, [string]$Role = 'solution',
        [string]$Root, [switch]$NoPSRule, [switch]$RequireAnswer)
    $res = New-Result $Rel $Role
    try { $m = Get-ExerciseManifest -Path $Dir } catch { $res.Problems.Add("$_"); return $res }
    $b = Test-CommonOffline $res $Dir $m $Kind
    if (-not $b -or -not $b.Ok) { return $res }
    if ($m.Entry -match '\.bicep$') {
        $d = Get-Diagnostics -EntryPath (Join-Path $Dir $m.Entry) -Root $Root -NoPSRule:$NoPSRule
        foreach ($x in $d.Text) { $res.Problems.Add("must be lint/PSRule clean: $x") }
    }
    if ($b.Template) {
        foreach ($x in (Test-ExpectResources -Template $b.Template -Types $m.ExpectResources)) { $res.Problems.Add("missing resource type $x") }
        foreach ($x in (Test-ExpectOutputs -Template $b.Template -Names $m.ExpectOutputs)) { $res.Problems.Add("missing output $x") }
        foreach ($x in (Test-ExpectProperties -Template $b.Template -Expect $m.ExpectProperties)) { $res.Problems.Add("expected property not present: $x") }
    }
    $testPath = Join-Path $Dir $m.Test
    if (Test-Path -LiteralPath $testPath -PathType Leaf) {
        $pr = Invoke-IsolatedPester -TestPath $testPath
        if ($pr.NoLive) { $res.Problems.Add('NO-LIVE: a test reached for live Azure (the runner trapped it); mock az / Az cmdlets') }
        if ($pr.Crashes.Count -or $pr.Failed) { $res.Problems.Add((Format-Pester $pr)) }
        elseif ($pr.Total -eq 0) { $res.Problems.Add("$($m.Test) contains no tests") }
    }
    if ($m.AnswerHeadings.Count -and ($RequireAnswer -or (Test-Path -LiteralPath (Join-Path $Dir 'ANSWER.md')))) {
        foreach ($p in (Test-AnswerFile -Path (Join-Path $Dir 'ANSWER.md') -Headings $m.AnswerHeadings)) { $res.Problems.Add($p) }
    }
    if ('LAB' -in $m.Tags) { $res.Notes.Add('offline only; live steps not run') }
    if (-not $res.Problems.Count) { $res.Verdict = "$(Get-ExerciseId -Path $Dir): all checks passed" }
    $res
}

function Test-Fidelity {
    <# Harness byte-identity between a starter and its solution, outside StudentRegion. Adds problems to $Res. #>
    param($Res, [string]$StarterDir, [string]$SolutionDir)
    try { $m = Get-ExerciseManifest -Path $StarterDir } catch { return }
    $sFiles = Get-ChildItem -LiteralPath $StarterDir -Recurse -File
    foreach ($f in $sFiles) {
        $rel = [IO.Path]::GetRelativePath($StarterDir, $f.FullName).Replace('\', '/')
        if ($rel -eq 'ANSWER.md') { continue }  # the student's artefact, not harness
        $other = Join-Path $SolutionDir $rel
        if (-not (Test-Path -LiteralPath $other -PathType Leaf)) { $Res.Problems.Add("fidelity: harness file $rel is missing from the solution"); continue }
        if ($rel -eq $m.Entry.Replace('\', '/')) {
            if ($m.StudentRegion -eq 'whole-file') { continue }
            try {
                $a = Get-HarnessText -Path $f.FullName -Region $m.StudentRegion
                $bb = Get-HarnessText -Path $other -Region $m.StudentRegion
                if ($a -cne $bb) { $Res.Problems.Add("fidelity: $rel differs from the starter $(if ($m.StudentRegion -eq 'below-marker') { 'above' } else { 'below' }) the marker (StudentRegion $($m.StudentRegion))") }
            } catch { $Res.Problems.Add("fidelity: $rel $_") }
            continue
        }
        $x = [IO.File]::ReadAllBytes($f.FullName); $y = [IO.File]::ReadAllBytes($other)
        if ($x.Length -ne $y.Length -or -not [System.Linq.Enumerable]::SequenceEqual($x, $y)) {
            $Res.Problems.Add("fidelity: harness file $rel is not byte-identical to the starter")
        }
    }
    $notes = Join-Path $SolutionDir 'NOTES.md'
    if (-not (Test-Path -LiteralPath $notes) -or -not (Get-Content -Raw -LiteralPath $notes).Trim()) { $Res.Problems.Add('solution needs a non-empty NOTES.md (section 7.6)') }
}

function Test-LessonDemo {
    param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Rel, [string]$Root, [switch]$NoPSRule)
    if (Test-Path -LiteralPath (Join-Path $Dir 'exercise.psd1')) {
        return Test-WorkedItem -Dir $Dir -Rel $Rel -Kind 'lesson-demo' -Role 'lesson-demo' -Root $Root -NoPSRule:$NoPSRule
    }
    $res = New-Result $Rel 'lesson-demo'
    foreach ($f in (Find-OutputPending -Path $Dir)) { $res.Problems.Add("OUTPUT-PENDING in $f") }
    foreach ($p in (Test-CaptureHashes -Path $Dir)) { $res.Problems.Add($p) }
    foreach ($f in Get-ChildItem -LiteralPath $Dir -Recurse -File) {
        $r = [IO.Path]::GetRelativePath($Dir, $f.FullName)
        if ($f.Extension -eq '.bicep') {
            $b = Invoke-BicepBuild -Path $f.FullName
            if (-not $b.Ok) { $res.Problems.Add("$r does not compile: $(@($b.Errors)[0])"); continue }
            foreach ($x in (Get-Diagnostics -EntryPath $f.FullName -Root $Root -NoPSRule:$NoPSRule).Text) { $res.Problems.Add("${r}: $x") }
        } elseif ($f.Name -like '*.tests.ps1') {
            $pr = Invoke-IsolatedPester -TestPath $f.FullName
            if ($pr.Crashes.Count -or $pr.Failed) { $res.Problems.Add("${r}: $(Format-Pester $pr)") }
        } elseif ($f.Extension -eq '.ps1') {
            foreach ($e in (Test-PowerShellParse -Path $f.FullName)) { $res.Problems.Add("$r does not parse: $e") }
        }
    }
    if (-not $res.Problems.Count) { $res.Verdict = 'lesson demo passes like a solution' }
    $res
}

function Find-CourseItems {
    <#
      Walks units/, capstones/, solutions/. Returns Pairs (starter + mirrored solution), Demos,
      Orphans (solution items with no starter), and Skips (path + reason) for anything else.
    #>
    param([Parameter(Mandatory)][string]$Root)
    $pairs = [ordered]@{}; $demos = [System.Collections.Generic.List[object]]::new()
    $skips = [System.Collections.Generic.List[object]]::new(); $sols = [ordered]@{}
    function Rel([string]$p) { [IO.Path]::GetRelativePath($Root, $p).Replace('\', '/') }
    function Skip([string]$p, [string]$why) { $skips.Add([pscustomobject]@{ Path = (Rel $p); Reason = $why }) }
    function Walk-Unit([string]$unitDir, [string]$mirrorRel, [bool]$isSolution, [bool]$isCapstone) {
        foreach ($c in Get-ChildItem -LiteralPath $unitDir -Force) {
            $n = $c.Name
            if (-not $c.PSIsContainer) {
                if (-not $isSolution -and ($n -eq 'LESSON.md' -or ($isCapstone -and $n -eq 'README.md'))) { continue }
                Skip $c.FullName 'not an exercise, drill, lesson demo, or LESSON.md'; continue
            }
            if ($n -match '^e\d\d-[a-z0-9][a-z0-9-]*$') { Add-Item $c.FullName "$mirrorRel/$n" 'exercise' $isSolution; continue }
            if ($n -eq 'lesson-demo' -and -not $isCapstone -and -not $isSolution) { $demos.Add([pscustomobject]@{ Dir = $c.FullName; Rel = (Rel $c.FullName) }); continue }
            if ($n -eq 'drills' -and -not $isCapstone) {
                foreach ($d in Get-ChildItem -LiteralPath $c.FullName -Force) {
                    if (-not $d.PSIsContainer) {
                        if ($d.Name -eq 'README.md' -and -not $isSolution) { continue }
                        Skip $d.FullName 'stray file in drills/'; continue
                    }
                    if ($d.Name -match '^r\d\d-[a-z0-9][a-z0-9-]*$') { Add-Item $d.FullName "$mirrorRel/drills/$($d.Name)" 'drill' $isSolution }
                    else { Skip $d.FullName 'drill folders are rNN-<slug>' }
                }
                continue
            }
            Skip $c.FullName $(if ($isSolution -and $n -eq 'lesson-demo') { 'lesson demos have no solution mirror' } else { 'unrecognised folder (exercises are eNN-<slug>)' })
        }
    }
    function Add-Item([string]$dir, [string]$key, [string]$kind, [bool]$isSolution) {
        if ($isSolution) { $sols[$key] = [pscustomobject]@{ Dir = $dir; Rel = (Rel $dir) }; return }
        $pairs[$key] = [pscustomobject]@{ Key = $key; Kind = $kind; Starter = $dir; StarterRel = (Rel $dir); Solution = $null; SolutionRel = $null }
    }
    foreach ($top in 'units', 'capstones') {
        $tdir = Join-Path $Root $top
        if (-not (Test-Path -LiteralPath $tdir)) { continue }
        $pat = if ($top -eq 'units') { '^a\d\d-[a-z0-9][a-z0-9-]*$' } else { '^c\d+-[a-z0-9][a-z0-9-]*$' }
        foreach ($u in Get-ChildItem -LiteralPath $tdir -Force) {
            if (-not $u.PSIsContainer -or $u.Name -notmatch $pat) { Skip $u.FullName "not a $(if ($top -eq 'units') { 'unit (aNN-<slug>)' } else { 'capstone (cN-<name>)' })"; continue }
            $mirror = if ($top -eq 'units') { $u.Name } else { "capstones/$($u.Name)" }
            Walk-Unit $u.FullName $mirror $false ($top -eq 'capstones')
        }
    }
    $sdir = Join-Path $Root 'solutions'
    if (Test-Path -LiteralPath $sdir) {
        foreach ($u in Get-ChildItem -LiteralPath $sdir -Force) {
            if ($u.PSIsContainer -and $u.Name -eq 'capstones') {
                foreach ($c in Get-ChildItem -LiteralPath $u.FullName -Force) {
                    if ($c.PSIsContainer -and $c.Name -match '^c\d+-[a-z0-9][a-z0-9-]*$') { Walk-Unit $c.FullName "capstones/$($c.Name)" $true $true }
                    else { Skip $c.FullName 'not a capstone solution folder' }
                }
                continue
            }
            if (-not $u.PSIsContainer -or $u.Name -notmatch '^a\d\d-[a-z0-9][a-z0-9-]*$') { Skip $u.FullName 'not a unit solution folder'; continue }
            Walk-Unit $u.FullName $u.Name $true $false
        }
    }
    $orphans = [System.Collections.Generic.List[object]]::new()
    foreach ($k in $sols.Keys) {
        if ($pairs.Contains($k)) { $pairs[$k].Solution = $sols[$k].Dir; $pairs[$k].SolutionRel = $sols[$k].Rel }
        else { $orphans.Add($sols[$k]) }
    }
    foreach ($p in $pairs.Values) {
        if (-not $p.SolutionRel) {
            $p.SolutionRel = if ($p.Key -like 'capstones/*') { "solutions/$($p.Key)" } else { "solutions/$($p.Key)" }
        }
    }
    [pscustomobject]@{ Pairs = @($pairs.Values); Demos = @($demos); Orphans = @($orphans); Skips = @($skips) }
}

Export-ModuleMember -Function Invoke-IsolatedPester, Get-LiveCallFindings, Test-StarterItem, Test-WorkedItem, Test-Fidelity, Test-LessonDemo, Find-CourseItems
