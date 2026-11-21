#Requires -Version 7.4
<#
.SYNOPSIS
  Guarded deploy for one [LAB] exercise into a dedicated, course-tagged resource group.
.DESCRIPTION
  1. Reads .lab-env.json (refuses if missing).
  2. Checks the Azure CLI context: personal tenant + subscription for resource labs, or the
     disposable Entra test tenant for unit A05 / directory changes. Refuses a corporate-looking
     tenant (anything containing 'deloitte', or a verified custom domain not allowed in .lab-env.json).
  3. Resource-scope labs in every unit except A02: refuses unless a subscription budget named
     budget.name (default lagb-monthly) with amount > 0 exists. -BudgetOverride deploys anyway
     with console warnings (no log file). This runs BEFORE the up.ps1 branch.
  4. If the exercise ships up.ps1, runs it (guards already passed) with -Context -Tags -LabEnv
     -WhatIf; see docs/AUTHORING-INFRA.md for the contract. Otherwise creates <prefix>-<exercise-id>
     with the SPEC 10.2 tags and deploys up.bicep (or the entry), with up.bicepparam when present.
  Use -WhatIf for a dry run: the read-only guard calls still run; nothing is created.
  Exit codes: 0 ok, 1 az failure, 2 usage, 3 refused by the guard (SPEC 7.7).
.EXAMPLE
  pwsh -File scripts/lab/lab-up.ps1 -Path units/a12-virtual-machines/e03-vm-lab -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Path,
    [int]$ExpiresInHours = 8,
    [switch]$BudgetOverride,
    [string]$EnvFile
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { Import-Module (Join-Path $PSScriptRoot 'LabGuard.psm1') }
$root = Get-LabRoot -Start $PSScriptRoot
if (-not (Get-Module AzGrinding)) { Import-Module (Join-Path $root 'lib/AzGrinding.psd1') }
if (-not $EnvFile) { $EnvFile = Join-Path $root '.lab-env.json' }

try {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Host "lab-up: no such exercise folder: $Path"; exit 2 }
    $dir = (Resolve-Path -LiteralPath $Path).Path
    $m = Get-ExerciseManifest -Path $dir
    if ('LAB' -notin $m.Tags) { Write-Host "lab-up: $Path is not tagged LAB; nothing to deploy"; exit 2 }
    $id = Get-ExerciseId -Path $dir
    $unit = Split-Path (Split-Path $dir -Parent) -Leaf
    $labEnv = Read-LabEnv -Path $EnvFile
    $scope = Get-LabScope -Unit $unit
    $ctx = Assert-LabContext -LabEnv $labEnv -Scope $scope
    Write-Host "lab-up: $scope scope OK (tenant $($ctx.TenantId)$(if ($scope -eq 'Resource') { ", subscription $($ctx.SubscriptionId)" }))"
    $tags = New-LabTags -Unit $unit -ExerciseId $id -Owner $labEnv.owner -ExpiresInHours $ExpiresInHours

    if ($scope -eq 'Resource' -and $unit -notmatch '^a02(-|$)') {
        if (-not (Test-LabBudget -LabEnv $labEnv)) {
            if (-not $BudgetOverride) { throw [System.Exception]::new('BUDGET') }
            Write-Warning '**************************************************************'
            Write-Warning "lab-up: NO A02 BUDGET '$($labEnv.budgetName)' FOUND. -BudgetOverride given; deploying anyway."
            Write-Warning '**************************************************************'
        }
    }

    $upScript = Join-Path $dir 'up.ps1'
    if (Test-Path -LiteralPath $upScript) {
        & $upScript -Context $ctx -Tags $tags -LabEnv $labEnv -WhatIf:$WhatIfPreference
        Write-Host "lab-up: up.ps1 finished for $id$(if ($WhatIfPreference) { ' (dry run)' })"
        exit 0
    }
    if ($scope -eq 'Entra') { Write-Host "lab-up: Entra-scope labs ship an up.ps1; $Path has none"; exit 2 }

    $template = if (Test-Path -LiteralPath (Join-Path $dir 'up.bicep')) { Join-Path $dir 'up.bicep' } else { Join-Path $dir $m.Entry }
    $param = Join-Path $dir 'up.bicepparam'
    $rg = Get-LabResourceGroupName -Prefix $labEnv.prefix -ExerciseId $id
    $null = New-LabResourceGroup -Name $rg -Location $labEnv.location -Tags $tags -WhatIf:$WhatIfPreference
    $null = Start-LabDeployment -ResourceGroup $rg -TemplateFile $template -ParameterFile $(if (Test-Path -LiteralPath $param) { $param } else { $null }) -WhatIf:$WhatIfPreference
    Write-Host "lab-up: $(if ($WhatIfPreference) { 'dry run for' } else { 'deployed' }) $rg (expires $($tags.expires)). Tear down today: pwsh -File scripts/lab/lab-down.ps1 -Path $Path"
    exit 0
} catch {
    if ($_.Exception.GetType().Name -eq 'LabGuardRefusal') { Write-Host $_.Exception.Message -ForegroundColor Red; exit 3 }
    if ($_.Exception.Message -eq 'BUDGET') {
        Write-Host "lab guard refused: no subscription budget named '$($labEnv.budgetName)' with amount > 0 (az consumption budget list). Do the A02 budget lab first (SPEC 10.3), or pass -BudgetOverride to deploy anyway (console warning only)." -ForegroundColor Red
        exit 3
    }
    Write-Host "lab-up: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
