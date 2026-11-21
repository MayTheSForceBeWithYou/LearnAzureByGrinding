#Requires -Version 7.4
<#
.SYNOPSIS
  Delete the course-tagged lab resource groups for one exercise (-Path) or one unit (-Unit).
.DESCRIPTION
  Runs the same guard as lab-up (tenant/subscription pin, Entra test tenant for A05, refuses
  corporate-looking tenants, refuses without .lab-env.json). Selects only resource groups
  tagged course=LearnAzureByGrinding, named <prefix>-..., with the matching unit (and exercise)
  tag. Prints soft-delete / purge warnings (Key Vault, Recovery Services, Log Analytics, ...)
  before deleting. An exercise that ships down.ps1 (A05 directory labs) has it run instead.
  -WhatIf lists what would be deleted. Exit codes: 0 ok, 1 az failure, 2 usage, 3 refused.
.EXAMPLE
  pwsh -File scripts/lab/lab-down.ps1 -Path units/a12-virtual-machines/e03-vm-lab
.EXAMPLE
  pwsh -File scripts/lab/lab-down.ps1 -Unit a12-virtual-machines -WhatIf
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Path')][string]$Path,
    [Parameter(Mandatory, ParameterSetName = 'Unit')][string]$Unit,
    [string]$EnvFile
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Module LabGuard)) { Import-Module (Join-Path $PSScriptRoot 'LabGuard.psm1') }
$root = Get-LabRoot -Start $PSScriptRoot
if (-not (Get-Module AzGrinding)) { Import-Module (Join-Path $root 'lib/AzGrinding.psd1') }
if (-not $EnvFile) { $EnvFile = Join-Path $root '.lab-env.json' }

try {
    $id = $null; $dir = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Host "lab-down: no such exercise folder: $Path"; exit 2 }
        $dir = (Resolve-Path -LiteralPath $Path).Path
        $id = Get-ExerciseId -Path $dir
        $Unit = Split-Path (Split-Path $dir -Parent) -Leaf
    }
    if ($Unit -notmatch '^(a\d\d|c\d+)-[a-z0-9-]+$') { Write-Host "lab-down: '$Unit' is not a unit folder name (e.g. a12-virtual-machines)"; exit 2 }
    $labEnv = Read-LabEnv -Path $EnvFile
    $scope = Get-LabScope -Unit $Unit
    $null = Assert-LabContext -LabEnv $labEnv -Scope $scope

    if ($dir -and (Test-Path -LiteralPath (Join-Path $dir 'down.ps1'))) {
        & (Join-Path $dir 'down.ps1') -LabEnv $labEnv -WhatIf:$WhatIfPreference
        exit 0
    }
    if ($scope -eq 'Entra') { Write-Host 'lab-down: Entra-scope labs clean up with their down.ps1; nothing tagged to delete here'; exit 0 }

    $groups = @(Get-CourseResourceGroups -Prefix $labEnv.prefix -Unit $Unit -ExerciseId $id)
    if (-not $groups.Count) { Write-Host "lab-down: no course-tagged resource groups for $(if ($id) { $id } else { $Unit })"; exit 0 }
    foreach ($g in $groups) {
        $r = Remove-LabResourceGroup -Group $g -Prefix $labEnv.prefix -WhatIf:$WhatIfPreference
        Write-Host "lab-down: $(if ($WhatIfPreference) { 'would delete' } else { 'deleting' }) $($r.Name) ($($r.Resources) resource(s))$(if ($r.Warnings.Count) { "; $($r.Warnings.Count) soft-delete warning(s) above" })"
    }
    Write-Host 'lab-down: deletion runs in the background. Check with: pwsh -File scripts/lab/lab-sweep.ps1'
    exit 0
} catch {
    if ($_.Exception.GetType().Name -eq 'LabGuardRefusal') { Write-Host $_.Exception.Message -ForegroundColor Red; exit 3 }
    Write-Host "lab-down: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
