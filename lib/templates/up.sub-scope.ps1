#Requires -Version 7.4
<#
.SYNOPSIS
  Reference up.ps1 for a subscription-scope lab (the A02 budget). Copy it and the skeleton
  up.sub-scope.bicep into the exercise folder, rename it up.ps1, and put the exercise's own
  resources in the Bicep (the skeleton deploys nothing).
.DESCRIPTION
  Contract (docs/AUTHORING-INFRA.md, "Subscription-scope up.ps1"):
  - lab-up.ps1 calls it as: & up.ps1 -Context <ctx> -Tags <tags> -LabEnv <env> -WhatIf:<bool>
    ONLY after Read-LabEnv, Assert-LabContext, and the budget gate (skipped for unit a02) passed.
  - Every az call goes through LabGuard functions (Invoke-LabAz and wrappers). Never az login,
    Connect-AzAccount, or az account set; never sign in. That keeps the mocked tests honest.
  - Honour -WhatIf: no state change when it is set.
  - Throw on failure; lab-up turns a throw into exit 1. Return nothing it needs to print.
  - Creates or reuses the persistent guardrails group (.lab-env.json guardrails.resourceGroup,
    default lagb-guardrails; tags = lab-up's New-LabTags set minus expires, with
    unit=a02-cost-and-guardrails and lifecycle=persistent),
    then runs az deployment sub create on up.sub-scope.bicep, passing budget.name (default
    lagb-monthly) as budgetName.
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
if (-not $contact) { throw '.lab-env.json budget.contactEmail is required for the budget alerts' }

$null = New-LabGuardrailsGroup -LabEnv $LabEnv -Tags $Tags -WhatIf:$WhatIfPreference

$guardrailTags = Get-LabGuardrailTags -LabEnv $LabEnv -Tags $Tags
$tagsFile = Join-Path ([IO.Path]::GetTempPath()) ('lagb-guardrail-tags-' + [guid]::NewGuid().ToString('n') + '.json')
try {
    # Object parameters go through a temp JSON file (no shell quoting differences between OSes).
    @{ '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'; contentVersion = '1.0.0.0'
        parameters = @{ guardrailTags = @{ value = $guardrailTags } } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tagsFile -Encoding utf8NoBOM -WhatIf:$false
    $null = Start-LabSubscriptionDeployment -Location $LabEnv.location -Name 'lagb-a02-budget' `
        -TemplateFile (Join-Path $PSScriptRoot 'up.sub-scope.bicep') `
        -Parameters @("@$tagsFile", "budgetName=$($LabEnv.budgetName)", "amount=$([int][math]::Ceiling($LabEnv.budgetAmount))",
            "guardrailsResourceGroup=$($LabEnv.guardrailsResourceGroup)", "contactEmail=$contact") `
        -WhatIf:$WhatIfPreference
} finally { Remove-Item -LiteralPath $tagsFile -Force -ErrorAction SilentlyContinue -WhatIf:$false }
Write-Host "up.ps1: subscription deployment lagb-a02-budget (guardrails group '$($LabEnv.guardrailsResourceGroup)') $(if ($WhatIfPreference) { 'would run' } else { 'finished' })."
