#Requires -Version 7.4
<#
.SYNOPSIS
  Remove the custom Policy assignment, then the definition this lab created.
.DESCRIPTION
  lab-down.ps1 calls: & down.ps1 -LabEnv <env> -WhatIf:<bool> after Assert-LabContext.
  Never az login, Connect-AzAccount, or az account set. Honour -WhatIf. Throw on failure.
  Delete the assignment before the definition (Azure refuses to delete a definition that is still assigned).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'down.ps1 runs only from scripts/lab/lab-down.ps1 (LabGuard is not loaded)' }

$null = $LabEnv
$name = 'lagb-sku-region-guard'
if ($PSCmdlet.ShouldProcess($name, 'delete policy assignment then policy definition')) {
    $null = Invoke-LabAz -Arguments @('policy', 'assignment', 'delete', '--name', $name)
    $null = Invoke-LabAz -Arguments @('policy', 'definition', 'delete', '--name', $name)
}
Write-Host "down.ps1: $(if ($WhatIfPreference) { "would remove assignment and definition '$name'" } else { "removed assignment and definition '$name'" })."
