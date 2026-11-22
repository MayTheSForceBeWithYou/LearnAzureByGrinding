#Requires -Version 7.4
# AzGrinding: shared offline helpers for LearnAzureByGrinding.
#
# Used by exercise Pester harnesses (main.tests.ps1) and by scripts/verify-all.ps1,
# scripts/check.ps1, scripts/lint.ps1, and scripts/selftest.ps1.
# Nothing in this module talks to Azure. Bicep is compiled with `bicep build --stdout`,
# so no compiled JSON is ever written next to a source file.

Set-StrictMode -Version 3.0

$script:KnownTags = @('WRITE', 'MODIFY', 'DRILL', 'BUG', 'PREDICT', 'WHATIF', 'EXPLAIN', 'LAB', 'PORTAL', 'CLI', 'NO-LIVE')
$script:KnownKeys = @('Tags', 'Entry', 'Test', 'StudentRegion', 'ExpectResources', 'ExpectOutputs',
    'ExpectProperties', 'ExpectDiagnostics', 'AnswerHeadings')
$script:Regions = @('below-marker', 'above-marker', 'whole-file')
$script:MarkerPattern = '---- Your .+ go(es)? below this line\. ----'

# --------------------------------------------------------------------------- course + toolchain

function Get-CourseRoot {
    <# Walks up from -Start to the folder that contains lib/AzGrinding.psd1 and bicepconfig.json. #>
    [CmdletBinding()]
    param([string]$Start = $PWD.Path)
    $dir = (Resolve-Path -LiteralPath $Start).Path
    if (Test-Path -LiteralPath $dir -PathType Leaf) { $dir = Split-Path $dir -Parent }
    while ($dir) {
        if ((Test-Path (Join-Path $dir 'lib/AzGrinding.psd1')) -and (Test-Path (Join-Path $dir 'bicepconfig.json'))) {
            return $dir
        }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    throw "Not inside a LearnAzureByGrinding course tree (no lib/AzGrinding.psd1 + bicepconfig.json above '$Start')."
}

function Get-Toolchain {
    [CmdletBinding()]
    param([string]$Root = (Get-CourseRoot))
    Import-PowerShellDataFile -LiteralPath (Join-Path $Root 'scripts/toolchain.psd1')
}

function Get-BicepPath {
    <# Finds the Bicep CLI: $env:LAGB_BICEP, then `bicep` on PATH, then the copy `az bicep install` puts in ~/.azure/bin. #>
    [CmdletBinding()]
    param()
    if ($env:LAGB_BICEP -and (Test-Path -LiteralPath $env:LAGB_BICEP)) { return $env:LAGB_BICEP }
    $cmd = Get-Command bicep -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    $name = if ($IsWindows) { 'bicep.exe' } else { 'bicep' }
    $azCopy = Join-Path ([Environment]::GetFolderPath('UserProfile')) ".azure/bin/$name"
    if (Test-Path -LiteralPath $azCopy) { return $azCopy }
    throw 'Bicep CLI not found. Install it (see docs/AUTHORING-INFRA.md) or set $env:LAGB_BICEP.'
}

# --------------------------------------------------------------------------- manifest + ids

function Get-ExerciseManifest {
    <#
      Loads exercise.psd1 from -Path (a folder) and returns a hashtable with every v0.3 key
      present: Tags (string[]; Tags[0] is the primary tag), PrimaryTag, Entry, Test,
      StudentRegion, ExpectResources, ExpectOutputs, ExpectProperties, ExpectDiagnostics,
      AnswerHeadings, plus Path and Raw (the keys as written).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $file = Join-Path $Path 'exercise.psd1'
    if (-not (Test-Path -LiteralPath $file)) { throw "missing exercise.psd1 in '$Path'" }
    $raw = Import-PowerShellDataFile -LiteralPath $file
    $m = @{ Path = (Resolve-Path -LiteralPath $Path).Path; Raw = $raw }
    $m.Tags = @($raw['Tags'] | ForEach-Object { "$_".Trim().ToUpperInvariant() } | Where-Object { $_ })
    $m.PrimaryTag = if ($m.Tags.Count) { $m.Tags[0] } else { $null }
    $m.Entry = if ($raw.ContainsKey('Entry')) { [string]$raw.Entry } else { 'main.bicep' }
    $m.Test = if ($raw.ContainsKey('Test')) { [string]$raw.Test } else { 'main.tests.ps1' }
    $m.StudentRegion = if ($raw.ContainsKey('StudentRegion')) { [string]$raw.StudentRegion } else { 'below-marker' }
    foreach ($k in 'ExpectResources', 'ExpectOutputs', 'ExpectDiagnostics', 'AnswerHeadings') {
        $m[$k] = @(if ($raw.ContainsKey($k)) { $raw[$k] | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_ } })
    }
    $m.ExpectProperties = @(if ($raw.ContainsKey('ExpectProperties')) { $raw.ExpectProperties | Where-Object { $_ } })
    $m
}

function Test-ExerciseManifest {
    <# Returns a list of problems with a loaded manifest (empty list = valid). -Kind is exercise|drill|lesson-demo. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Manifest, [string]$Kind = 'exercise')
    $p = [System.Collections.Generic.List[string]]::new()
    $m = $Manifest
    foreach ($k in $m.Raw.Keys) { if ($k -notin $script:KnownKeys) { $p.Add("unknown key '$k' (known: $($script:KnownKeys -join ', '))") } }
    if (-not $m.Tags.Count) { $p.Add("Tags is empty; the first tag is the primary tag") }
    foreach ($t in $m.Tags) { if ($t -notin $script:KnownTags) { $p.Add("unknown tag '$t'") } }
    if ($m.Tags.Count -ne @($m.Tags | Select-Object -Unique).Count) { $p.Add('duplicate tag') }
    if ($m.PrimaryTag -in 'LAB', 'NO-LIVE') { $p.Add("'$($m.PrimaryTag)' cannot be the primary tag; list the graded tag first") }
    if ('LAB' -in $m.Tags -and 'NO-LIVE' -in $m.Tags) { $p.Add('LAB and NO-LIVE are contradictory') }
    if ($Kind -eq 'drill' -and $m.PrimaryTag -ne 'DRILL') { $p.Add("a drill's primary tag must be DRILL") }
    if ($Kind -eq 'drill' -and 'LAB' -in $m.Tags) { $p.Add('drills are offline; LAB is not allowed') }
    if ($m.StudentRegion -notin $script:Regions) { $p.Add("StudentRegion '$($m.StudentRegion)' is not one of $($script:Regions -join ' | ')") }
    $entryPath = Join-Path $m.Path $m.Entry
    if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) { $p.Add("Entry '$($m.Entry)' does not exist") }
    elseif ($m.Entry -notmatch '\.(bicep|json|ps1)$') { $p.Add("Entry '$($m.Entry)' must be .bicep, .json (ARM), or .ps1 (CLI)") }
    $testPath = Join-Path $m.Path $m.Test
    $needsTest = $m.PrimaryTag -in 'WRITE', 'MODIFY', 'DRILL' -or ($m.PrimaryTag -eq 'BUG' -and -not $m.ExpectDiagnostics.Count)
    if ($needsTest -and -not (Test-Path -LiteralPath $testPath -PathType Leaf)) { $p.Add("Test '$($m.Test)' does not exist (required for $($m.PrimaryTag))") }
    $isTemplate = $m.Entry -match '\.(bicep|json)$'
    if ($m.PrimaryTag -in 'WRITE', 'DRILL' -and $isTemplate -and -not ($m.ExpectResources.Count + $m.ExpectOutputs.Count)) {
        $p.Add("$($m.PrimaryTag) with a template entry needs ExpectResources or ExpectOutputs (the 'symbol list')")
    }
    if ($m.PrimaryTag -eq 'MODIFY' -and $isTemplate -and -not ($m.ExpectProperties.Count + $m.ExpectResources.Count + $m.ExpectOutputs.Count)) {
        $p.Add('MODIFY with a template entry needs ExpectProperties (or ExpectResources/ExpectOutputs)')
    }
    if ($m.ExpectDiagnostics.Count -and $m.PrimaryTag -ne 'BUG') { $p.Add('ExpectDiagnostics is only allowed on BUG') }
    $i = 0
    foreach ($e in $m.ExpectProperties) {
        $i++
        if ($e -isnot [hashtable]) { $p.Add("ExpectProperties[$i] must be a hashtable"); continue }
        foreach ($k in $e.Keys) { if ($k -notin 'ResourceType', 'Path', 'Value', 'Match') { $p.Add("ExpectProperties[$i] unknown key '$k'") } }
        if (-not $e.ResourceType -or -not $e.Path) { $p.Add("ExpectProperties[$i] needs ResourceType and Path") }
        if (-not ($e.ContainsKey('Value') -xor $e.ContainsKey('Match'))) { $p.Add("ExpectProperties[$i] needs exactly one of Value or Match") }
    }
    if ($m.PrimaryTag -eq 'WHATIF') {
        $caps = @(Get-ChildItem -LiteralPath $m.Path -File | Where-Object Name -match '^(capture|whatif).*\.txt$')
        if (-not $caps.Count) { $p.Add('WHATIF needs a capture*.txt or whatif*.txt fixture (real output, or OUTPUT-PENDING until captured)') }
    }
    if ($m.StudentRegion -ne 'whole-file' -and (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
        if ((Get-MarkerLineIndex -Lines @(Get-Content -LiteralPath $entryPath)) -lt 0) {
            $p.Add("StudentRegion '$($m.StudentRegion)' needs the marker line in $($m.Entry): '// ---- Your resources go below this line. ----' (any comment style)")
        }
    }
    foreach ($h in $m.AnswerHeadings) { if ($h -notmatch '^#{1,6} \S') { $p.Add("AnswerHeadings entry '$h' must be a Markdown heading line, e.g. '## Mechanism'") } }
    $p
}

function Get-ExerciseKind {
    <# exercise | drill | lesson-demo | $null, from the folder name and its parent. #>
    param([Parameter(Mandatory)][string]$Path)
    $leaf = Split-Path $Path -Leaf
    $parent = Split-Path (Split-Path $Path -Parent) -Leaf
    if ($leaf -eq 'lesson-demo') { return 'lesson-demo' }
    if ($leaf -match '^r\d\d-[a-z0-9][a-z0-9-]*$' -and $parent -eq 'drills') { return 'drill' }
    if ($leaf -match '^e\d\d-[a-z0-9][a-z0-9-]*$') { return 'exercise' }
    $null
}

function Get-ExerciseId {
    <#
      aNN-eNN-slug, aNN-rNN-slug, cN-eNN-slug, aNN-lesson-demo. Works for units/, capstones/,
      solutions/ mirrors, and reps/<id>/<stamp>/ copies made by scripts/rep.ps1.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $leaf = Split-Path $full -Leaf
    $parentDir = Split-Path $full -Parent
    $parent = Split-Path $parentDir -Leaf
    if ($parent -match '^(a\d\d|c\d+)-(e|r)\d\d-' -or $parent -match '^(a\d\d|c\d+)-lesson-demo$') { return $parent }  # reps/<id>/<stamp>
    $unitDir = if ($parent -eq 'drills') { Split-Path $parentDir -Parent } else { $parentDir }
    $unit = Split-Path $unitDir -Leaf
    $tok = if ($unit -match '^(a\d\d|c\d+)-') { $Matches[1] } else { $unit }
    "$tok-$leaf"
}

# --------------------------------------------------------------------------- compile, lint, PSRule

function Invoke-Native {
    param([string]$File, [string[]]$Arguments)
    $errFile = [IO.Path]::GetTempFileName()
    try {
        $out = & $File @Arguments 2>$errFile
        $code = $LASTEXITCODE
        [pscustomobject]@{ ExitCode = $code; StdOut = (@($out) -join "`n"); StdErr = (Get-Content -Raw -LiteralPath $errFile) }
    } finally { Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue }
}

function Invoke-BicepBuild {
    <#
      Compiles a .bicep to an ARM template in memory (bicep build --stdout), or parses an ARM
      .json entry. Returns Ok, Template (hashtable), and Errors (string[]).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $full = (Resolve-Path -LiteralPath $Path).Path
    if ($full -match '\.json$') {
        try {
            $t = Get-Content -Raw -LiteralPath $full | ConvertFrom-Json -AsHashtable -Depth 200
            return [pscustomobject]@{ Ok = $true; Template = $t; Errors = @() }
        } catch { return [pscustomobject]@{ Ok = $false; Template = $null; Errors = @("ARM JSON does not parse: $($_.Exception.Message)") } }
    }
    $r = Invoke-Native (Get-BicepPath) @('build', $full, '--stdout')
    $errs = @(($r.StdErr -split "`r?`n") | Where-Object { $_ -match ' : Error ' })
    if ($r.ExitCode -ne 0) {
        if (-not $errs.Count) { $errs = @(($r.StdErr -split "`r?`n") | Where-Object { $_.Trim() }) }
        return [pscustomobject]@{ Ok = $false; Template = $null; Errors = $errs }
    }
    try { $t = $r.StdOut | ConvertFrom-Json -AsHashtable -Depth 200 }
    catch { return [pscustomobject]@{ Ok = $false; Template = $null; Errors = @("bicep build output is not JSON: $($_.Exception.Message)") } }
    [pscustomobject]@{ Ok = $true; Template = $t; Errors = @() }
}

function Invoke-BicepLint {
    <# Runs `bicep lint` (repo bicepconfig.json is found by walking up) and returns every diagnostic: RuleId, Level, Line, Message. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $full = (Resolve-Path -LiteralPath $Path).Path
    $r = Invoke-Native (Get-BicepPath) @('lint', $full, '--diagnostics-format', 'sarif')
    if (-not $r.StdOut.Trim()) { throw "bicep lint produced no SARIF for '$Path': $($r.StdErr)" }
    $sarif = $r.StdOut | ConvertFrom-Json -Depth 50
    foreach ($run in @($sarif.runs)) {
        foreach ($res in @($run.results)) {
            if (-not $res) { continue }
            $lvl = if ($res.PSObject.Properties['level'] -and $res.level) { $res.level } else { 'warning' }
            $line = $null
            try { $line = $res.locations[0].physicalLocation.region.startLine } catch { }
            [pscustomobject]@{ RuleId = $res.ruleId; Level = $lvl; Line = $line; Message = $res.message.text }
        }
    }
}

function Get-LintFindings {
    <# The course is -Werror: every error or warning is a finding. Info/note are ignored. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    @(Invoke-BicepLint -Path $Path | Where-Object { $_.Level -in 'error', 'warning' })
}

function Invoke-CoursePSRule {
    <#
      Runs PSRule for Azure on one .bicep file with the repo ps-rule.yaml and the '@course'
      baseline group. Returns the sorted unique names of rules whose outcome is Fail or Error.
      An exception (e.g. Bicep expansion failure) is returned as 'PSRule.Exception: <message>'.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$Root)
    if (-not $Root) { $Root = Get-CourseRoot -Start (Split-Path (Resolve-Path -LiteralPath $Path).Path -Parent) }
    $full = (Resolve-Path -LiteralPath $Path).Path
    $env:PSRULE_AZURE_BICEP_PATH = Get-BicepPath
    Import-Module PSRule -ErrorAction Stop -Verbose:$false
    Push-Location -LiteralPath $Root
    try {
        $r = Invoke-PSRule -InputPath $full -Option (Join-Path $Root 'ps-rule.yaml') -Baseline '@course' `
            -Outcome Fail, Error -WarningAction SilentlyContinue -ErrorAction Stop
        @($r | ForEach-Object RuleName | Sort-Object -Unique)
    } catch {
        @("PSRule.Exception: $($_.Exception.Message)")
    } finally { Pop-Location }
}

function Test-PowerShellParse {
    <# Returns parse errors for a .ps1 file (empty = parses). #>
    param([Parameter(Mandatory)][string]$Path)
    $tokens = $null; $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $Path).Path, [ref]$tokens, [ref]$errors)
    @($errors | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" })
}

# --------------------------------------------------------------------------- compiled-template queries

function Get-CompiledTemplate {
    <# For Pester harnesses: compile the exercise entry (default main.bicep next to the test) and return the template; throws on a compile error. #>
    [CmdletBinding()]
    param([string]$Directory, [string]$Entry = 'main.bicep')
    if (-not $Directory) { throw 'Get-CompiledTemplate: pass -Directory $PSScriptRoot' }
    $b = Invoke-BicepBuild -Path (Join-Path $Directory $Entry)
    if (-not $b.Ok) { throw "build failed for ${Entry}:`n$($b.Errors -join "`n")" }
    $b.Template
}

function Get-TemplateResources {
    <#
      Flattens every resource in a compiled template, including nested child resources and the
      inner templates of module deployments (Microsoft.Resources/deployments). Returns objects
      with Type (full type), Name, and Resource (the hashtable). -Type filters (case-insensitive).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [string]$Type)
    $all = [System.Collections.Generic.List[object]]::new()
    function Add-Res([object]$resources, [string]$parentType) {
        if ($null -eq $resources) { return }
        $list = if ($resources -is [System.Collections.IDictionary]) { @($resources.Values) } else { @($resources) }
        foreach ($r in $list) {
            if ($r -isnot [System.Collections.IDictionary] -or -not $r.Contains('type')) { continue }
            $t = [string]$r['type']
            if ($parentType -and ($t.Split('/')[0] -notmatch '\.')) { $t = "$parentType/$t" }
            $all.Add([pscustomobject]@{ Type = $t; Name = $r['name']; Resource = $r })
            if ($r.Contains('resources')) { Add-Res $r['resources'] $t }
            if ($t -ieq 'Microsoft.Resources/deployments' -and $r.Contains('properties') -and
                $r['properties'] -is [System.Collections.IDictionary] -and $r['properties'].Contains('template')) {
                Add-Res $r['properties']['template']['resources'] $null
            }
        }
    }
    if ($Template.Contains('resources')) { Add-Res $Template['resources'] $null }
    if ($Type) { return @($all | Where-Object { $_.Type -ieq $Type }) }
    @($all)
}

function Get-TemplateOutputNames {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template)
    if (-not $Template.Contains('outputs') -or -not $Template['outputs']) { return @() }
    @($Template['outputs'].Keys)
}

function Get-PropertyValue {
    <#
      Looks up a dotted path ('properties.networkAcls.defaultAction', 'sku.name',
      'properties.securityRules[0].properties.access') in a hashtable. Returns Found and Value.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)
    $cur = $Object
    foreach ($seg in $Path.Split('.')) {
        if ($seg -notmatch '^(?<name>[^\[\]]+)(?<idx>(\[\d+\])*)$') { throw "bad path segment '$seg' in '$Path'" }
        $name = $Matches.name; $idx = $Matches.idx
        if ($cur -isnot [System.Collections.IDictionary]) { return [pscustomobject]@{ Found = $false; Value = $null } }
        $key = @($cur.Keys | Where-Object { $_ -ieq $name } | Select-Object -First 1)
        if (-not $key.Count) { return [pscustomobject]@{ Found = $false; Value = $null } }
        $cur = $cur[$key[0]]
        foreach ($m in [regex]::Matches($idx, '\[(\d+)\]')) {
            $i = [int]$m.Groups[1].Value
            $arr = @($cur)
            if ($cur -is [string] -or $i -ge $arr.Count) { return [pscustomobject]@{ Found = $false; Value = $null } }
            $cur = $arr[$i]
        }
    }
    [pscustomobject]@{ Found = $true; Value = $cur }
}

function Test-ValueMatch($actual, $expected) {
    if ($expected -is [bool] -or $expected -is [int] -or $expected -is [long] -or $expected -is [double]) {
        return ($actual -is [bool] -or $actual -is [ValueType]) -and ($actual -eq $expected) -and ($actual.GetType() -eq [bool]) -eq ($expected -is [bool])
    }
    if ($expected -is [string]) { return ($actual -is [string]) -and ($actual -ieq $expected) }
    (ConvertTo-Json $actual -Depth 50 -Compress) -eq (ConvertTo-Json $expected -Depth 50 -Compress)
}

function Test-ExpectResources {
    <# Returns the ExpectResources types missing from the template (empty = all present). #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [string[]]$Types = @())
    $have = @(Get-TemplateResources -Template $Template | ForEach-Object Type)
    @($Types | Where-Object { $t = $_; -not ($have | Where-Object { $_ -ieq $t }) })
}

function Test-ExpectOutputs {
    <# Returns the ExpectOutputs names missing from the template. #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [string[]]$Names = @())
    $have = Get-TemplateOutputNames -Template $Template
    @($Names | Where-Object { $n = $_; -not ($have | Where-Object { $_ -ieq $n }) })
}

function Test-ExpectProperties {
    <#
      Returns a description of every ExpectProperties entry that no resource of that type
      satisfies. Entry: @{ ResourceType = '...'; Path = 'properties.x'; Value = <literal> }
      or Match = '<regex>' in place of Value. Values compare against the compiled JSON, so a
      Bicep expression compiles to an ARM expression string ("[parameters('sku')]").
    #>
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [object[]]$Expect = @())
    $unmet = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $Expect) {
        $want = if ($e.ContainsKey('Match')) { "matches /$($e.Match)/" } else { "= $(ConvertTo-Json $e.Value -Compress -Depth 20)" }
        $ok = $false
        foreach ($r in (Get-TemplateResources -Template $Template -Type $e.ResourceType)) {
            $v = Get-PropertyValue -Object $r.Resource -Path $e.Path
            if (-not $v.Found) { continue }
            if ($e.ContainsKey('Match')) { if ("$($v.Value)" -match $e.Match) { $ok = $true; break } }
            elseif (Test-ValueMatch $v.Value $e.Value) { $ok = $true; break }
        }
        if (-not $ok) { $unmet.Add("$($e.ResourceType) $($e.Path) $want") }
    }
    @($unmet)
}

function Assert-ExpectResources {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [string[]]$Types = @())
    $miss = @(Test-ExpectResources -Template $Template -Types $Types)
    if ($miss.Count) { throw "missing resource type(s): $($miss -join ', ')" }
}
function Assert-ExpectOutputs {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [string[]]$Names = @())
    $miss = @(Test-ExpectOutputs -Template $Template -Names $Names)
    if ($miss.Count) { throw "missing output(s): $($miss -join ', ')" }
}
function Assert-ExpectProperties {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Template, [object[]]$Expect = @())
    $miss = @(Test-ExpectProperties -Template $Template -Expect $Expect)
    if ($miss.Count) { throw "expected change not present: $($miss -join '; ')" }
}

# --------------------------------------------------------------------------- prose, captures, markers

function Test-AnswerFile {
    <#
      Checks ANSWER.md: exists, not blank, contains every required heading line exactly, each
      heading has non-blank text under it, and no OUTPUT-PENDING. Returns problems (empty = ok).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string[]]$Headings = @())
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @("ANSWER.md is missing") }
    $text = Get-Content -Raw -LiteralPath $Path
    if (-not $text -or -not $text.Trim()) { return @("ANSWER.md is empty") }
    $p = [System.Collections.Generic.List[string]]::new()
    $lines = $text -split "`r?`n"
    foreach ($h in $Headings) {
        $i = [array]::FindIndex($lines, [Predicate[string]] { param($l) $l.TrimEnd() -ceq $h })
        if ($i -lt 0) { $p.Add("ANSWER.md lacks heading '$h'"); continue }
        $body = $false
        for ($j = $i + 1; $j -lt $lines.Count -and $lines[$j] -notmatch '^#{1,6} '; $j++) { if ($lines[$j].Trim()) { $body = $true; break } }
        if (-not $body) { $p.Add("ANSWER.md heading '$h' has no text under it") }
    }
    if ($text -match 'OUTPUT-PENDING') { $p.Add('ANSWER.md contains OUTPUT-PENDING') }
    @($p)
}

function Find-OutputPending {
    <# Relative paths of text files under -Path that contain OUTPUT-PENDING. #>
    param([Parameter(Mandatory)][string]$Path)
    $base = (Resolve-Path -LiteralPath $Path).Path
    @(Get-ChildItem -LiteralPath $base -Recurse -File | Where-Object {
            $_.Extension -in '.md', '.txt', '.bicep', '.json', '.bicepparam', '.ps1', '.psd1', '.kql'
        } | Where-Object { Select-String -LiteralPath $_.FullName -SimpleMatch 'OUTPUT-PENDING' -Quiet } |
        ForEach-Object { [IO.Path]::GetRelativePath($base, $_.FullName) })
}

function Test-CaptureHashes {
    <#
      For capture*.txt / whatif*.txt files whose leading lines are '# source: <relpath> sha256=<hex>',
      checks that each named source still has that SHA-256. Returns 'STALE: ...' problems.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $p = [System.Collections.Generic.List[string]]::new()
    foreach ($cap in Get-ChildItem -LiteralPath $Path -Recurse -File | Where-Object Name -match '^(capture|whatif).*\.txt$') {
        foreach ($line in Get-Content -LiteralPath $cap.FullName -TotalCount 20) {
            if ($line -notmatch '^# source: (?<src>\S+) sha256=(?<h>[0-9a-fA-F]{64})\s*$') { continue }
            $src = Join-Path $cap.DirectoryName $Matches.src
            if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { $p.Add("STALE: $($cap.Name) names missing source $($Matches.src)"); continue }
            $h = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
            if ($h -ne $Matches.h.ToUpperInvariant()) { $p.Add("STALE: $($cap.Name) was captured from a different $($Matches.src)") }
        }
    }
    @($p)
}

function Get-MarkerLineIndex {
    <# 0-based index of the student marker line ('---- Your resources go below this line. ----', any comment style), or -1. #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines)
    for ($i = 0; $i -lt $Lines.Count; $i++) { if ($Lines[$i] -match $script:MarkerPattern) { return $i } }
    -1
}

function Get-HarnessText {
    <#
      The shipped (harness) part of an entry file under a StudentRegion: below-marker = start of
      file through the marker line; above-marker = marker line through end of file; whole-file =
      $null (nothing is harness). Throws if a marker region has no marker.
    #>
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Region)
    if ($Region -eq 'whole-file') { return $null }
    $lines = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path) -split "`n"
    $i = Get-MarkerLineIndex -Lines $lines
    if ($i -lt 0) { throw "no student marker line in $(Split-Path $Path -Leaf)" }
    if ($Region -eq 'below-marker') { return ($lines[0..$i] -join "`n") }
    ($lines[$i..($lines.Count - 1)] -join "`n")
}

function Write-ChecksPassed {
    param([Parameter(Mandatory)][string]$Id)
    Write-Host "${Id}: all checks passed"
}

# --------------------------------------------------------------------------- az mock (offline CLI exercises)

function Enable-AzMock {
    <#
      Replaces `az` with an offline fake for the current session. -Fixtures maps an argument
      prefix (e.g. 'account show', 'storage account list') to a reply: a string (returned as-is,
      usually JSON from a checked-in fixture file), a scriptblock (invoked with the arguments), or
      any other object (returned as JSON). The longest matching prefix wins. An unmatched call
      throws, so a test can never fall through to the real CLI. Calls are recorded.
      Works whether or not the Azure CLI is installed. Pair with Disable-AzMock in AfterAll.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Fixtures, [int]$ExitCode = 0)
    $global:__AzGrindingMock = @{
        Fixtures = $Fixtures; ExitCode = $ExitCode
        Calls    = [System.Collections.Generic.List[string]]::new()
        Previous = (Get-Item -Path function:global:az -ErrorAction SilentlyContinue)?.ScriptBlock
    }
    Set-Item -Path function:global:az -Value {
        $line = ($args | ForEach-Object { "$_" }) -join ' '
        $st = $global:__AzGrindingMock
        $st.Calls.Add($line)
        $key = $st.Fixtures.Keys | Where-Object { $line -eq $_ -or $line.StartsWith("$_ ") } |
            Sort-Object Length -Descending | Select-Object -First 1
        if (-not $key) { $global:LASTEXITCODE = 1; throw "az mock: no fixture for 'az $line'" }
        $global:LASTEXITCODE = $st.ExitCode
        $reply = $st.Fixtures[$key]
        if ($reply -is [scriptblock]) { & $reply @args }
        elseif ($reply -is [string]) { $reply }
        else { ConvertTo-Json $reply -Depth 50 }
    }
}

function Disable-AzMock {
    [CmdletBinding()]
    param()
    $st = Get-Variable -Name __AzGrindingMock -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    # Remove-Item function:global:az from inside a module does not remove it; go through the caller's session state.
    try { $PSCmdlet.SessionState.InvokeProvider.Item.Remove('function:\az', $false) } catch { }
    if ($st -and $st.Previous) { Set-Item -Path function:global:az -Value $st.Previous }
    Remove-Variable -Name __AzGrindingMock -Scope Global -ErrorAction SilentlyContinue
}

function Get-AzMockCalls {
    <# The argument strings of every `az` call the mock has seen. #>
    $st = Get-Variable -Name __AzGrindingMock -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($st) { @($st.Calls) } else { @() }
}

Export-ModuleMember -Function @(
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
