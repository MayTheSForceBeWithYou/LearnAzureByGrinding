#Requires -Version 7.4
<#
.SYNOPSIS
  Subscription-scope up.ps1 for the C1 governance-baseline lab.
.DESCRIPTION
  Contract (docs/AUTHORING-INFRA.md, "Subscription-scope up.ps1"):
  - lab-up.ps1 calls it as: & up.ps1 -Context <ctx> -Tags <tags> -LabEnv <env> -WhatIf:<bool>
    ONLY after Read-LabEnv, Assert-LabContext, and the budget gate have passed.
  - Every az call goes through LabGuard functions. Never az login, Connect-AzAccount, or
    az account set; never sign in. Honour -WhatIf. Throw on failure.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Tags,
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'up.ps1 runs only from scripts/lab/lab-up.ps1 (LabGuard is not loaded)' }

$contact = $LabEnv.budgetContactEmail
if (-not $contact) { throw '.lab-env.json budget.contactEmail is required for the capstone budget alerts' }

$rgName = Get-LabResourceGroupName -Prefix $LabEnv.prefix -ExerciseId 'c1-e01-governance-baseline'

$tagsFile = Join-Path ([IO.Path]::GetTempPath()) ('lagb-c1-tags-' + [guid]::NewGuid().ToString('n') + '.json')
try {
    @{ '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'; contentVersion = '1.0.0.0'
        parameters = @{ tags = @{ value = $Tags } } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tagsFile -Encoding utf8NoBOM -WhatIf:$false
    $null = Start-LabSubscriptionDeployment -Location $LabEnv.location -Name 'lagb-c1-e01-baseline' `
        -TemplateFile (Join-Path $PSScriptRoot 'main.bicep') `
        -Parameters @("@$tagsFile", "rgName=$rgName", "location=$($LabEnv.location)",
            'principalId=00000000-0000-0000-0000-000000000000', 'principalType=User',
            'budgetName=lagb-c1-baseline', "amount=$([int][math]::Ceiling($LabEnv.budgetAmount))",
            "contactEmail=$contact") `
        -WhatIf:$WhatIfPreference
} finally { Remove-Item -LiteralPath $tagsFile -Force -ErrorAction SilentlyContinue -WhatIf:$false }
Write-Host "up.ps1: subscription deployment lagb-c1-e01-baseline (group '$rgName') $(if ($WhatIfPreference) { 'would run' } else { 'finished' })."
$null = $Context
