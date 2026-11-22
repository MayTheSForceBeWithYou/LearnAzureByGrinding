#Requires -Version 7.4
<#
.SYNOPSIS
  Verify every starter, solution, and lesson demo in the course (offline layers only).
.DESCRIPTION
  Starters must obey the fail-until-worked rule for their primary tag (SPEC 4.3, 4.4, 8.2);
  solutions must pass everything and keep the shipped harness byte-identical (8.3);
  anything unrecognised is a counted SKIP row (8.5); missing and orphan solutions fail.
  Exit codes (SPEC 7.7): 0 pass, 1 a check failed or something was skipped, 2 usage or
  missing toolchain. Nothing is written into the tree.
.PARAMETER Only
  Path prefix (repo-relative, or an existing path). The mirrored solution or starter comes along.
.PARAMETER RequireItems
  Fail when nothing was checked (SPEC 7.7). Off until the first unit lands; see AUTHORING-INFRA.
.PARAMETER NoPSRule
  Skip PSRule (faster local loop). CI never passes this.
.PARAMETER Root
  Course root (default: the repo this script lives in). Used by selftest.ps1.
#>
[CmdletBinding()]
param(
    [string]$Only,
    [switch]$RequireItems,
    [switch]$NoPSRule,
    [string]$Root
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
$Root = (Resolve-Path -LiteralPath $Root).Path
Import-Module (Join-Path $Root 'lib/AzGrinding.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'internal/Verify.psm1') -Force

# ---- toolchain (exit 2 when missing)
try { $null = Get-BicepPath } catch { Write-Host "verify-all: $_"; exit 2 }
if (-not (Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -eq 5 })) { Write-Host 'verify-all: Pester 5 is not installed (see docs/AUTHORING-INFRA.md)'; exit 2 }
if (-not $NoPSRule -and -not (Get-Module -ListAvailable PSRule.Rules.Azure)) { Write-Host 'verify-all: PSRule.Rules.Azure is not installed (see docs/AUTHORING-INFRA.md)'; exit 2 }

# ---- -Only normalisation
$prefix = $null
if ($Only) {
    $cand = if ([IO.Path]::IsPathRooted($Only)) { $Only } else { Join-Path $PWD.Path $Only }
    if (Test-Path -LiteralPath $cand) { $prefix = [IO.Path]::GetRelativePath($Root, (Resolve-Path -LiteralPath $cand).Path).Replace('\', '/') }
    else { $prefix = $Only.Replace('\', '/') }
    $prefix = $prefix.TrimStart('.', '/').TrimEnd('/')
    if ($prefix.StartsWith('..')) { Write-Host "verify-all: -Only '$Only' is outside the course root"; exit 2 }
}
function Test-InScope([string[]]$paths) {
    if (-not $prefix) { return $true }
    foreach ($p in $paths) {
        if (-not $p) { continue }
        # units/aNN/... <-> solutions/aNN/...; capstones/... <-> solutions/capstones/...
        $mirror = if ($p -like 'solutions/capstones/*') { $p.Substring(10) } elseif ($p -like 'solutions/*') { "units/$($p.Substring(10))" } else { $null }
        foreach ($q in @($p, $mirror)) {
            if (-not $q) { continue }
            if ($q -eq $prefix -or $q.StartsWith("$prefix/") -or $prefix.StartsWith("$q/")) { return $true }
        }
    }
    $false
}

$found = Find-CourseItems -Root $Root
$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row([string]$Status, [string]$Role, [string]$Path, [string]$Detail) {
    $rows.Add([pscustomobject]@{ Status = $Status; Role = $Role; Path = $Path; Detail = $Detail })
    $color = @{ PASS = 'Green'; FAIL = 'Red'; SKIP = 'Yellow' }[$Status]
    Write-Host ('{0,-4}  {1,-11} {2}' -f $Status, $Role, $Path) -ForegroundColor $color
    foreach ($d in ($Detail -split "`n")) { if ($d) { Write-Host "            $d" } }
}
function Add-Result($r) {
    $detail = if ($r.Problems.Count) { ($r.Problems -join "`n") } else { (@($r.Verdict) + @($r.Notes) -join "`n") }
    Add-Row $(if ($r.Problems.Count) { 'FAIL' } else { 'PASS' }) $r.Role $r.Path $detail
}

$params = @{ Root = $Root; NoPSRule = [bool]$NoPSRule }
$checked = 0
foreach ($p in $found.Pairs) {
    if (-not (Test-InScope @($p.StarterRel, $p.SolutionRel))) { continue }
    $checked++
    $sr = Test-StarterItem -Dir $p.Starter -Rel $p.StarterRel -Kind $p.Kind @params
    Add-Result $sr
    if (-not $p.Solution) {
        Add-Row 'FAIL' 'solution' $p.SolutionRel 'missing solution (every exercise and drill needs one; SPEC 8.5)'
        continue
    }
    $wr = Test-WorkedItem -Dir $p.Solution -Rel $p.SolutionRel -Kind $p.Kind -Role 'solution' -RequireAnswer @params
    Test-Fidelity -Res $wr -StarterDir $p.Starter -SolutionDir $p.Solution
    if ($wr.Problems.Count) { $wr.Verdict = '' }
    Add-Result $wr
}
foreach ($d in $found.Demos) {
    if (-not (Test-InScope @($d.Rel))) { continue }
    $checked++
    Add-Result (Test-LessonDemo -Dir $d.Dir -Rel $d.Rel @params)
}
foreach ($o in $found.Orphans) {
    if (-not (Test-InScope @($o.Rel))) { continue }
    $checked++
    Add-Row 'FAIL' 'solution' $o.Rel 'orphan solution: no matching starter under units/ or capstones/'
}
foreach ($s in $found.Skips) {
    if (-not (Test-InScope @($s.Path))) { continue }
    Add-Row 'SKIP' 'path' $s.Path $s.Reason
}

$fail = @($rows | Where-Object Status -eq 'FAIL').Count
$skip = @($rows | Where-Object Status -eq 'SKIP').Count
$pass = @($rows | Where-Object Status -eq 'PASS').Count
Write-Host ''
if ($prefix -and -not $rows.Count) { Write-Host "verify-all: -Only '$Only' matched nothing"; exit 2 }
if ($checked -eq 0 -and -not $rows.Count) {
    Write-Host 'verify-all: 0 items checked (no units, capstones, or solutions yet).'
    if ($RequireItems) { Write-Host 'verify-all: FAIL (-RequireItems: at least one item must be checked)'; exit 1 }
    Write-Host 'verify-all: OK (empty course tree)'
    exit 0
}
Write-Host ("verify-all: {0} item(s), {1} row(s): {2} passed, {3} failed, {4} skipped" -f $checked, $rows.Count, $pass, $fail, $skip)
if ($checked -eq 0 -and $RequireItems) { Write-Host 'verify-all: FAIL (-RequireItems)'; exit 1 }
if ($fail -or $skip) { Write-Host 'verify-all: FAIL'; exit 1 }
Write-Host 'verify-all: OK'
exit 0
