#Requires -Version 7.4
<#
.SYNOPSIS
  Student-facing check of YOUR work in one exercise, drill, or rep folder (offline).
.DESCRIPTION
  Applies the "done" rule (SPEC 8.4) to the folder as it is now: the entry compiles, bicep lint
  and PSRule are clean (warnings count, like -Werror), the Expect* lists in exercise.psd1 are
  satisfied, the Pester harness passes, and ANSWER.md has every required heading with text
  under it. verify-all.ps1 is the author tool: it expects untouched starters to FAIL.
  Exit 0 done, 1 not yet, 2 usage or missing toolchain.
.EXAMPLE
  pwsh -File ../../../scripts/check.ps1        # from units/aNN-<slug>/eNN-<slug>
#>
[CmdletBinding()]
param([string]$Path = '.', [switch]$NoPSRule)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
Import-Module (Join-Path $PSScriptRoot 'internal/Verify.psm1') -Force
try { $null = Get-BicepPath } catch { Write-Host "check: $_"; exit 2 }
if (-not (Test-Path -LiteralPath (Join-Path $Path 'exercise.psd1'))) { Write-Host "check: no exercise.psd1 in '$Path'"; exit 2 }
$dir = (Resolve-Path -LiteralPath $Path).Path
$m = Get-ExerciseManifest -Path $dir
$kind = if ($m.PrimaryTag -eq 'DRILL') { 'drill' } else { 'exercise' }
$rel = [IO.Path]::GetRelativePath($root, $dir).Replace('\', '/')
$r = Test-WorkedItem -Dir $dir -Rel $rel -Kind $kind -Role 'your work' -Root $root -NoPSRule:$NoPSRule -RequireAnswer
if ($r.Problems.Count) {
    Write-Host "NOT YET  $rel" -ForegroundColor Yellow
    foreach ($p in $r.Problems) { Write-Host "  - $p" }
    exit 1
}
Write-Host $r.Verdict -ForegroundColor Green
foreach ($n in $r.Notes) { Write-Host "  ($n)" }
if ('LAB' -in $m.Tags) { Write-Host '  [LAB]: done also means lab-down has run and lab-sweep shows nothing for this unit.' }
exit 0
