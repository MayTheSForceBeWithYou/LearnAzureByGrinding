#Requires -Version 7.4
<#
.SYNOPSIS
  Subscription-scope up.ps1 for the A04 SKU/region Policy lab.
.DESCRIPTION
  Contract (docs/AUTHORING-INFRA.md, "Subscription-scope up.ps1"):
  - lab-up.ps1 calls it as: & up.ps1 -Context <ctx> -Tags <tags> -LabEnv <env> -WhatIf:<bool>
    ONLY after Read-LabEnv, Assert-LabContext, and the budget gate have passed.
  - Every az call goes through LabGuard functions (Invoke-LabAz and wrappers). Never az login,
    Connect-AzAccount, or az account set; never sign in.
  - Honour -WhatIf: no state change when it is set.
  - Throw on failure; lab-up turns a throw into exit 1.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Tags,
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'up.ps1 runs only from scripts/lab/lab-up.ps1 (LabGuard is not loaded)' }

$null = $Context
$null = $Tags
$null = Start-LabSubscriptionDeployment -Location $LabEnv.location -Name 'lagb-a04-e02-policy' `
    -TemplateFile (Join-Path $PSScriptRoot 'main.bicep') `
    -WhatIf:$WhatIfPreference
Write-Host "up.ps1: subscription deployment lagb-a04-e02-policy $(if ($WhatIfPreference) { 'would run' } else { 'finished' })."
