#Requires -Version 7.4
<#
.SYNOPSIS
  PSRule for Azure over every .bicep that must be clean: solutions/ and units/*/lesson-demo/.
.DESCRIPTION
  Uses ps-rule.yaml and the '@course' baseline group (pinned in scripts/toolchain.psd1). Starters
  are not analysed here: verify-all.ps1 checks them per tag (a [BUG] starter may fail exactly its
  ExpectDiagnostics). Exit 0 clean (or nothing to analyse), 1 a rule failed, 2 missing toolchain.
#>
[CmdletBinding()]
param([string]$Root)
$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path $PSScriptRoot -Parent }
Import-Module (Join-Path $Root 'lib/AzGrinding.psd1') -Force
try { $env:PSRULE_AZURE_BICEP_PATH = Get-BicepPath } catch { Write-Host "psrule: $_"; exit 2 }
if (-not (Get-Module -ListAvailable PSRule.Rules.Azure)) { Write-Host 'psrule: PSRule.Rules.Azure is not installed'; exit 2 }
$files = @()
$sol = Join-Path $Root 'solutions'
if (Test-Path -LiteralPath $sol) { $files += Get-ChildItem -LiteralPath $sol -Recurse -File -Filter '*.bicep' }
$units = Join-Path $Root 'units'
if (Test-Path -LiteralPath $units) {
    foreach ($d in Get-ChildItem -LiteralPath $units -Directory) {
        $demo = Join-Path $d.FullName 'lesson-demo'
        if (Test-Path -LiteralPath $demo) { $files += Get-ChildItem -LiteralPath $demo -Recurse -File -Filter '*.bicep' }
    }
}
if (-not $files.Count) { Write-Host 'psrule: no Bicep under solutions/ or units/*/lesson-demo/ yet; nothing to analyse'; exit 0 }
Import-Module PSRule
Push-Location -LiteralPath $Root
try {
    $r = @(Invoke-PSRule -InputPath $files.FullName -Option (Join-Path $Root 'ps-rule.yaml') -Baseline '@course' -WarningAction SilentlyContinue)
} finally { Pop-Location }
$bad = @($r | Where-Object { $_.Outcome -in 'Fail', 'Error' })
Write-Host "psrule: $($files.Count) file(s), $($r.Count) rule result(s), $($bad.Count) failure(s) (baseline $((Import-PowerShellDataFile (Join-Path $Root 'scripts/toolchain.psd1')).PSRuleBaseline))"
if ($bad.Count) {
    $bad | ForEach-Object { [pscustomobject]@{ Rule = $_.RuleName; Outcome = $_.Outcome; Target = $_.TargetName; File = @($_.Source | ForEach-Object File)[0] } } |
        Format-Table -AutoSize | Out-String -Width 220 | Write-Host
    exit 1
}
exit 0
