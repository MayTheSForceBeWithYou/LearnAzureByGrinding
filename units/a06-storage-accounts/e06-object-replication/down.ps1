#Requires -Version 7.4
<#
.SYNOPSIS
  Tear down the A06 object-replication lab resource group.
.DESCRIPTION
  lab-down.ps1 calls: & down.ps1 -LabEnv <env> -WhatIf:<bool> after Assert-LabContext.
  Never az login, Connect-AzAccount, or az account set. Honour -WhatIf. Throw on failure.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'down.ps1 runs only from scripts/lab/lab-down.ps1 (LabGuard is not loaded)' }

$rgName = Get-LabResourceGroupName -Prefix $LabEnv.prefix -ExerciseId 'a06-e06-object-replication'
if ($PSCmdlet.ShouldProcess($rgName, 'delete resource group')) {
    $null = Invoke-LabAz -Arguments @('group', 'delete', '--name', $rgName, '--yes', '--no-wait')
}
$confirm = "az group exists --name $rgName"
Write-Host "down.ps1: $(if ($WhatIfPreference) { "would request teardown of '$rgName'" } else { "teardown of '$rgName' was requested" }) (az group delete --yes --no-wait). Confirm with: $confirm. Soft-deleted storage accounts, if any, can linger; lab-sweep still lists leftovers."
