#Requires -Version 7.4
<#
.SYNOPSIS
  Install or check the pinned toolchain from scripts/toolchain.psd1. Offline course checks only;
  this never signs in to Azure.
.DESCRIPTION
  Default: installs Pester, PSRule, and PSRule.Rules.Azure at the pins (-Scope CurrentUser) and
  downloads the pinned Bicep CLI release into -BicepDir (default: ~/.lagb/bicep-<version>),
  outside the repo. Prints how to point the harness at it ($env:LAGB_BICEP).
  -Ci: same, and exports LAGB_BICEP / PATH through $env:GITHUB_ENV / $env:GITHUB_PATH.
  -CheckOnly: install nothing; print the versions found and exit 2 if a pin is not met.
#>
[CmdletBinding()]
param([switch]$Ci, [switch]$CheckOnly, [string]$BicepDir)
$ErrorActionPreference = 'Stop'
$pins = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'toolchain.psd1')
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force

function Show-Versions {
    $ok = $true
    Write-Host "pwsh                 $($PSVersionTable.PSVersion) (minimum $($pins.PowerShellMinimum))"
    if ($PSVersionTable.PSVersion -lt [version]$pins.PowerShellMinimum) { $ok = $false }
    $az = Get-Command az -ErrorAction SilentlyContinue
    if ($az) {
        $v = try { (az version --output json 2>$null | ConvertFrom-Json).'azure-cli' } catch { 'unknown' }
        Write-Host "azure-cli            $v (minimum $($pins.AzureCliMinimum); only [LAB] work needs it; never signed in by these scripts)"
    } else { Write-Host "azure-cli            not installed (only [LAB] work needs it)" }
    try {
        $b = Get-BicepPath
        $bv = (& $b --version) -replace '^Bicep CLI version (\S+).*$', '$1'
        Write-Host "bicep                $bv at $b (pin $($pins.BicepVersion))"
        if ($bv -ne $pins.BicepVersion) { $ok = $false }
    } catch { Write-Host "bicep                MISSING (pin $($pins.BicepVersion))"; $ok = $false }
    foreach ($m in @(@('Pester', $pins.PesterVersion), @('PSRule', $pins.PSRuleVersion), @('PSRule.Rules.Azure', $pins.PSRuleRulesAzureVersion))) {
        $found = @(Get-Module -ListAvailable $m[0] | ForEach-Object { "$($_.Version)" } | Sort-Object -Unique)
        $hit = $m[1] -in $found
        Write-Host ('{0,-20} {1} (pin {2})' -f $m[0], $(if ($found.Count) { $found -join ', ' } else { 'MISSING' }), $m[1])
        if (-not $hit) { $ok = $false }
    }
    Write-Host "PSRule baseline      $($pins.PSRuleBaseline) (ps-rule.yaml group '@course')"
    $ok
}

if ($CheckOnly) { if (Show-Versions) { exit 0 } else { Write-Host 'install-tools: a pinned tool is missing or at another version'; exit 2 } }

# ---- PowerShell modules
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
foreach ($m in @(@('Pester', $pins.PesterVersion), @('PSRule', $pins.PSRuleVersion), @('PSRule.Rules.Azure', $pins.PSRuleRulesAzureVersion))) {
    if (Get-Module -ListAvailable $m[0] | Where-Object { "$($_.Version)" -eq $m[1] }) { continue }
    Write-Host "installing $($m[0]) $($m[1])"
    Install-Module -Name $m[0] -RequiredVersion $m[1] -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber -Repository PSGallery
}

# ---- Bicep CLI (standalone release binary, pinned)
if (-not $BicepDir) {
    $base = if ($Ci -and $env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.lagb' }
    $BicepDir = Join-Path $base "bicep-$($pins.BicepVersion)"
}
$asset = if ($IsWindows) { 'bicep-win-x64.exe' }
elseif ($IsMacOS) { if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq 'Arm64') { 'bicep-osx-arm64' } else { 'bicep-osx-x64' } }
else { if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq 'Arm64') { 'bicep-linux-arm64' } else { 'bicep-linux-x64' } }
$exe = Join-Path $BicepDir $(if ($IsWindows) { 'bicep.exe' } else { 'bicep' })
if (-not (Test-Path -LiteralPath $exe)) {
    $null = New-Item -ItemType Directory -Force -Path $BicepDir
    $url = "https://github.com/Azure/bicep/releases/download/v$($pins.BicepVersion)/$asset"
    Write-Host "downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    if (-not $IsWindows) { chmod +x $exe }
}
$env:LAGB_BICEP = $exe
if ($Ci) {
    if ($env:GITHUB_ENV) { "LAGB_BICEP=$exe" | Add-Content -LiteralPath $env:GITHUB_ENV }
    if ($env:GITHUB_PATH) { $BicepDir | Add-Content -LiteralPath $env:GITHUB_PATH }
} else {
    Write-Host "Bicep $($pins.BicepVersion) is at $exe. The harness finds it if you set:"
    Write-Host "  `$env:LAGB_BICEP = '$exe'   (add to your PowerShell profile), or put that folder first on PATH."
    Write-Host "  (A Bicep from 'az bicep install' at the same version also works; see docs/AUTHORING-INFRA.md.)"
}
if (-not (Show-Versions)) { exit 2 }
