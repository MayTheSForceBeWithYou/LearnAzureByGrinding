#Requires -Version 7.4
<#
.SYNOPSIS
  List leftover course-tagged resources and soft-deleted vaults in the lab subscription. List-only.
.DESCRIPTION
  Runs the resource-scope guard, then lists every resource group and resource tagged
  course=LearnAzureByGrinding with type, region, expires tag, whether it is past expiry, and a
  cost-risk class (SPEC 10.4). Also lists soft-deleted Key Vaults. Deletes nothing; use
  lab-down.ps1. Exit codes: 0 nothing left, 1 leftovers found or az failure, 3 refused.
#>
[CmdletBinding()]
param([string]$EnvFile, [datetime]$Now = [datetime]::UtcNow)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { Import-Module (Join-Path $PSScriptRoot 'LabGuard.psm1') }
$root = Get-LabRoot -Start $PSScriptRoot
if (-not $EnvFile) { $EnvFile = Join-Path $root '.lab-env.json' }

try {
    $labEnv = Read-LabEnv -Path $EnvFile
    $null = Assert-LabContext -LabEnv $labEnv -Scope Resource
    $left = Get-LabLeftovers -Now $Now
    $rows = $left.Rows
    $deletedKv = @($left.DeletedKeyVaults)
    if ($rows) { $rows | Sort-Object Risk, Name | Format-Table -AutoSize | Out-String -Width 220 | Write-Host }
    foreach ($v in $deletedKv) { Write-Host "soft-deleted Key Vault: $($v.name) (purge: az keyvault purge --name $($v.name))" -ForegroundColor Yellow }
    $n = @($rows).Count + $deletedKv.Count
    if ($n) { Write-Host "lab-sweep: $n leftover item(s). Remove them with lab-down.ps1 -Unit <unit> (or -Path <exercise>)."; exit 1 }
    Write-Host 'lab-sweep: nothing course-tagged is left in the lab subscription.'
    exit 0
} catch {
    if ($_.Exception.GetType().Name -eq 'LabGuardRefusal') { Write-Host $_.Exception.Message -ForegroundColor Red; exit 3 }
    Write-Host "lab-sweep: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
