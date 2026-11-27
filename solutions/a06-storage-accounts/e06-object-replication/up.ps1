#Requires -Version 7.4
<#
.SYNOPSIS
  Resource-group-scope up.ps1 for the A06 object-replication lab.
.DESCRIPTION
  Contract (docs/AUTHORING-INFRA.md):
  - lab-up.ps1 calls: & up.ps1 -Context <ctx> -Tags <tags> -LabEnv <env> -WhatIf:<bool>
    ONLY after Read-LabEnv, Assert-LabContext, and the budget gate have passed.
  - Every az call goes through LabGuard functions (Invoke-LabAz and wrappers). Never az login,
    Connect-AzAccount, or az account set; never sign in. Honour -WhatIf. Throw on failure.
  - Deploys up.bicep with up.bicepparam (SPEC 10.7), then overlays lab-up's tags and location
    so expires/lab-sweep stay correct.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Tags,
    [Parameter(Mandatory)]$LabEnv
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { throw 'up.ps1 runs only from scripts/lab/lab-up.ps1 (LabGuard is not loaded)' }

$rgName = Get-LabResourceGroupName -Prefix $LabEnv.prefix -ExerciseId 'a06-e06-object-replication'
$null = New-LabResourceGroup -Name $rgName -Location $LabEnv.location -Tags $Tags -WhatIf:$WhatIfPreference

$paramFile = Join-Path $PSScriptRoot 'up.bicepparam'
$tagsFile = Join-Path ([IO.Path]::GetTempPath()) ('lagb-a06-e06-tags-' + [guid]::NewGuid().ToString('n') + '.json')
try {
    @{
        '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        contentVersion = '1.0.0.0'
        parameters     = @{
            tags = @{ value = $Tags }
        }
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tagsFile -Encoding utf8NoBOM -WhatIf:$false
    $null = Start-LabDeployment -ResourceGroup $rgName -Name 'lagb-a06-e06-or' `
        -TemplateFile (Join-Path $PSScriptRoot 'up.bicep') `
        -ParameterFile $paramFile `
        -Parameters @("@$tagsFile", "location=$($LabEnv.location)") `
        -WhatIf:$WhatIfPreference
} finally {
    Remove-Item -LiteralPath $tagsFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
}
Write-Host "up.ps1: group '$rgName' $(if ($WhatIfPreference) { 'would deploy' } else { 'deployed' }) a06-e06-object-replication."
$null = $Context
