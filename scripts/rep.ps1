#Requires -Version 7.4
<#
.SYNOPSIS
  Fresh copy of a drill (or exercise) starter into the gitignored reps/ folder.
.EXAMPLE
  pwsh -File scripts/rep.ps1 units/a06-storage-accounts/drills/r01-sku-and-kind-reps
  # then work in reps/a06-r01-sku-and-kind-reps/<timestamp>/ and check it with
  pwsh -File scripts/check.ps1 -Path reps/a06-r01-sku-and-kind-reps/<timestamp>
#>
[CmdletBinding()]
param([Parameter(Mandatory, Position = 0)][string]$Path)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Host "rep: no such folder: $Path"; exit 2 }
$src = (Resolve-Path -LiteralPath $Path).Path
$rel = [IO.Path]::GetRelativePath($root, $src).Replace('\', '/')
if ($rel -notmatch '^(units|capstones)/' -or -not (Get-ExerciseKind -Path $src) -or (Get-ExerciseKind -Path $src) -eq 'lesson-demo') {
    Write-Host "rep: $rel is not a drill or exercise under units/ or capstones/"; exit 2
}
$id = Get-ExerciseId -Path $src
$dest = Join-Path $root "reps/$id/$((Get-Date).ToString('yyyyMMdd-HHmmss'))"
$null = New-Item -ItemType Directory -Force -Path $dest
Get-ChildItem -LiteralPath $src -Force | Where-Object Name -ne 'ANSWER.md' | Copy-Item -Destination $dest -Recurse
$relDest = [IO.Path]::GetRelativePath($root, $dest).Replace('\', '/')
Write-Host "rep: fresh copy of $id in $relDest"
Write-Host "rep: when done, run: pwsh -File scripts/check.ps1 -Path $relDest"
