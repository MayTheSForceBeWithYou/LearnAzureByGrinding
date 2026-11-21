#Requires -Version 7.4
<#
.SYNOPSIS
  Repository lint: layout, pins, bicepconfig.json, ps-rule.yaml, manifests, portability,
  OUTPUT-PENDING, links to solutions/, and committed artefacts (SPEC 8.1).
.DESCRIPTION
  Fast and offline: no Bicep compile. Exit 0 clean, 1 findings.
#>
[CmdletBinding()]
param([string]$Root)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$Root = (Resolve-Path -LiteralPath $Root).Path
Import-Module (Join-Path $Root 'lib/AzGrinding.psd1') -Force
$f = [System.Collections.Generic.List[string]]::new()
function Rel([string]$p) { [IO.Path]::GetRelativePath($Root, $p).Replace('\', '/') }
$skipDirs = '(^|/)(\.git|reps|out|\.psrule|TestResults|node_modules)(/|$)'
$all = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { (Rel $_.FullName) -notmatch $skipDirs })

# ---- required files
foreach ($p in 'bicepconfig.json', 'ps-rule.yaml', '.gitignore', '.gitattributes', '.lab-env.example.json', 'scripts/toolchain.psd1',
    'docs/AUTHORING-INFRA.md', 'docs/SPEC.md', '.github/workflows/ci.yml', 'lib/AzGrinding.psd1', 'lib/AzGrinding.psm1') {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $p))) { $f.Add("missing required file $p") }
}
$pins = Import-PowerShellDataFile (Join-Path $Root 'scripts/toolchain.psd1')

# ---- bicepconfig.json
try {
    $bc = Get-Content -Raw (Join-Path $Root 'bicepconfig.json') | ConvertFrom-Json -AsHashtable
    $core = $bc.analyzers.core
    if (-not $core.enabled) { $f.Add('bicepconfig.json: analyzers.core.enabled must be true') }
    foreach ($k in $core.rules.Keys) {
        $lvl = $core.rules[$k].level
        if ($lvl -eq 'error') { $f.Add("bicepconfig.json: rule $k is 'error'; course rules are 'warning' so [BUG] starters compile, and the harness fails on warnings") }
    }
    if ($core.rules['use-recent-api-versions'].level -ne 'off') { $f.Add('bicepconfig.json: use-recent-api-versions must be off (date-dependent results)') }
} catch { $f.Add("bicepconfig.json: $($_.Exception.Message)") }

# ---- ps-rule.yaml (line checks; no YAML module dependency)
$yaml = Get-Content -Raw (Join-Path $Root 'ps-rule.yaml')
if ($yaml -notmatch '(?m)^\s*AZURE_BICEP_FILE_EXPANSION:\s*true\s*$') { $f.Add('ps-rule.yaml: AZURE_BICEP_FILE_EXPANSION: true is required') }
if ($yaml -notmatch "(?m)^\s*PSRule\.Rules\.Azure:\s*'$([regex]::Escape($pins.PSRuleRulesAzureVersion))'") { $f.Add("ps-rule.yaml: requires PSRule.Rules.Azure must pin '$($pins.PSRuleRulesAzureVersion)' (scripts/toolchain.psd1)") }
if ($yaml -notmatch "(?m)^\s*course:\s*$([regex]::Escape($pins.PSRuleBaseline))\s*$") { $f.Add("ps-rule.yaml: baseline group 'course' must be $($pins.PSRuleBaseline) (scripts/toolchain.psd1)") }
if ($yaml -notmatch "(?m)^\s*AZURE_BICEP_MINIMUM_VERSION:\s*'$([regex]::Escape($pins.BicepVersion))'") { $f.Add("ps-rule.yaml: AZURE_BICEP_MINIMUM_VERSION must be '$($pins.BicepVersion)'") }

# ---- pins are written down where SPEC 9 says
$infraDoc = Join-Path $Root 'docs/AUTHORING-INFRA.md'
if (Test-Path $infraDoc) {
    $doc = Get-Content -Raw $infraDoc
    foreach ($k in 'BicepVersion', 'PesterVersion', 'PSRuleVersion', 'PSRuleRulesAzureVersion', 'PSRuleBaseline') {
        if (-not $doc.Contains($pins[$k])) { $f.Add("docs/AUTHORING-INFRA.md does not mention $k $($pins[$k])") }
    }
}
$ci = Join-Path $Root '.github/workflows/ci.yml'
if (Test-Path $ci) {
    $ciText = Get-Content -Raw $ci
    if ($ciText -notmatch 'scripts/install-tools\.ps1') { $f.Add('ci.yml must install the toolchain with scripts/install-tools.ps1 (pins live in scripts/toolchain.psd1)') }
    if ($ciText -match '(?i)azure/login|Connect-AzAccount|az login|secrets\.') { $f.Add('ci.yml must not sign in to Azure or read secrets (SPEC 10.6)') }
}

# ---- .gitignore and committed local files
$gi = Get-Content (Join-Path $Root '.gitignore')
foreach ($p in '.lab-env.json', 'reps/', 'out/') { if ($p -notin $gi) { $f.Add(".gitignore must list $p") } }
if (Get-Command git -ErrorAction SilentlyContinue) {
    Push-Location $Root
    try {
        $tracked = @(git ls-files 2>$null)
        foreach ($t in $tracked) {
            if ((Split-Path $t -Leaf) -eq '.lab-env.json') { $f.Add("$t is committed; it holds your tenant pin and must stay local") }
            if ($t -like '*.local.bicepparam' -or $t -like 'reps/*' -or $t -like 'out/*') { $f.Add("$t is committed but is a local artefact") }
        }
    } finally { Pop-Location }
}

# ---- PowerShell parses; no hardcoded drive paths in harness code
foreach ($file in $all | Where-Object Extension -in '.ps1', '.psm1', '.psd1') {
    foreach ($e in (Test-PowerShellParse -Path $file.FullName)) { $f.Add("$(Rel $file.FullName): parse error $e") }
    $r = Rel $file.FullName
    if ($r -match '^(scripts|lib)/') {
        $n = 0
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            $n++
            $code = $line -replace '#.*$', ''
            if ($code -match '(?<![A-Za-z])[A-Za-z]:\\[A-Za-z]') { $f.Add("${r}:$n hardcoded Windows path (use Join-Path)") }
        }
    }
}

# ---- content trees: OUTPUT-PENDING, links to solutions, compiled JSON, manifests
$content = @($all | Where-Object { (Rel $_.FullName) -match '^(units|capstones|solutions)/' -or (Rel $_.FullName) -in 'README.md', 'PROGRESS.md', 'docs/ROADMAP.md' })
foreach ($file in $content) {
    $r = Rel $file.FullName
    if ($file.Extension -in '.md', '.txt', '.bicep', '.json', '.ps1', '.psd1', '.bicepparam') {
        if (Select-String -LiteralPath $file.FullName -SimpleMatch 'OUTPUT-PENDING' -Quiet) { $f.Add("${r}: OUTPUT-PENDING (blocks merging; capture real output)") }
    }
    if ($file.Extension -eq '.md' -and $r -notmatch '^solutions/') {
        if (Select-String -LiteralPath $file.FullName -Pattern '\]\([^)]*solutions/|(\.\./)+solutions/|solutions/(a\d\d|capstones)/' -Quiet) { $f.Add("${r}: links to or names solutions/ (SPEC 6: no README, lesson, or exercise file links to solutions)") }
    }
    if ($file.Extension -eq '.bicep' -and (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($file.FullName, '.json')))) {
        $f.Add("$([IO.Path]::ChangeExtension($r, '.json')): compiled JSON next to its .bicep (build artefact)")
    }
    if ($file.Name -eq 'exercise.psd1') {
        try {
            $m = Get-ExerciseManifest -Path $file.DirectoryName
            $kind = Get-ExerciseKind -Path $file.DirectoryName
            if (-not $kind) { $f.Add("${r}: exercise.psd1 in a folder that is not eNN-, drills/rNN-, or lesson-demo") ; continue }
            foreach ($p in (Test-ExerciseManifest -Manifest $m -Kind $kind)) { $f.Add("${r}: $p") }
        } catch { $f.Add("${r}: $($_.Exception.Message)") }
    }
}

foreach ($x in $f) { Write-Host "lint: $x" -ForegroundColor Red }
if ($f.Count) { Write-Host "lint: FAIL ($($f.Count) finding(s))"; exit 1 }
Write-Host "lint: OK ($($all.Count) files)"
exit 0
