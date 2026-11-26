#Requires -Version 7.4
<#
.SYNOPSIS
  Tear down the C1 governance baseline: lock first, then assignment, role, budget, group.
.DESCRIPTION
  lab-down.ps1 calls: & down.ps1 -LabEnv <env> -WhatIf:<bool> after Assert-LabContext.
  Never az login, Connect-AzAccount, or az account set. Honour -WhatIf. Throw on failure.
  A CanNotDelete lock on the group must be removed BEFORE az group delete.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'down.ps1 runs only from scripts/lab/lab-down.ps1 (LabGuard is not loaded)' }

$rgName = Get-LabResourceGroupName -Prefix $LabEnv.prefix -ExerciseId 'c1-e01-governance-baseline'
$budgetName = 'lagb-c1-baseline'
$lockName = 'lagb-cannotdelete'
$policyName = 'lagb-allowed-locations'

if ($PSCmdlet.ShouldProcess($rgName, 'remove lock, then policy assignment, role assignments, budget, and resource group')) {
    $null = Invoke-LabAz -Arguments @('lock', 'delete', '--name', $lockName, '--resource-group', $rgName)
    $null = Invoke-LabAz -Arguments @('policy', 'assignment', 'delete', '--name', $policyName)
    $assignments = @(Invoke-LabAz -Arguments @('role', 'assignment', 'list', '--resource-group', $rgName, '--role', 'Reader'))
    foreach ($a in $assignments) {
        if ($a -and $a.id) { $null = Invoke-LabAz -Arguments @('role', 'assignment', 'delete', '--ids', $a.id) }
    }
    $null = Invoke-LabAz -Arguments @('consumption', 'budget', 'delete', '--budget-name', $budgetName)
    $null = Invoke-LabAz -Arguments @('group', 'delete', '--name', $rgName, '--yes', '--no-wait')
}
Write-Host "down.ps1: $(if ($WhatIfPreference) { "would tear down '$rgName'" } else { "tore down '$rgName'" }) (lock removed first)."
