#Requires -Version 7.4
# Runs one Pester file in a fresh pwsh process for scripts/verify-all.ps1 and scripts/check.ps1.
# Writes a JSON summary to -ResultFile. Before the tests run, `az` and the Az PowerShell
# entry points are replaced with functions that throw "NO-LIVE", so a test that is not
# mocked fails loudly instead of reaching Azure. Enable-AzMock or Pester `Mock az` override it.
param(
    [Parameter(Mandatory)][string]$TestPath,
    [Parameter(Mandatory)][string]$ResultFile
)
$ErrorActionPreference = 'Stop'
Set-Item -Path function:global:az -Value ([scriptblock]::Create(
        'throw "NO-LIVE: the test called the real Azure CLI (az $args). Use Enable-AzMock or Mock az."'))
foreach ($n in 'Connect-AzAccount', 'Invoke-AzRestMethod', 'Get-AzAccessToken', 'New-AzResourceGroupDeployment',
    'New-AzDeployment', 'New-AzSubscriptionDeployment', 'New-AzManagementGroupDeployment', 'New-AzTenantDeployment',
    'Test-AzResourceGroupDeployment', 'Get-AzResourceGroupDeploymentWhatIfResult') {
    Set-Item -Path "function:global:$n" -Value ([scriptblock]::Create("throw 'NO-LIVE: the test called $n. Mock it.'"))
}
Import-Module Pester -MinimumVersion 5.0.0 -MaximumVersion 5.999.999 -ErrorAction Stop
$c = New-PesterConfiguration
$c.Run.Path = $TestPath
$c.Run.PassThru = $true
$c.Output.Verbosity = 'None'
$c.TestResult.Enabled = $false
$c.CodeCoverage.Enabled = $false
$r = Invoke-Pester -Configuration $c
function First-Line([object]$rec) {
    if (-not $rec) { return $null }
    $m = (@($rec)[0]).Exception.Message
    ($m -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
}
$failed = @($r.Failed | ForEach-Object { [pscustomobject]@{ Name = $_.ExpandedPath; Error = (First-Line $_.ErrorRecord) } })
$crashes = @()
$crashes += @($r.FailedBlocks | ForEach-Object { "block '$($_.ExpandedPath)': $(First-Line $_.ErrorRecord)" })
$crashes += @($r.FailedContainers | ForEach-Object { "file: $(First-Line $_.ErrorRecord)" })
$all = (@($failed.Error) + $crashes) -join "`n"
[pscustomobject]@{
    Result      = "$($r.Result)"
    Total       = $r.TotalCount
    Passed      = $r.PassedCount
    Failed      = $r.FailedCount
    FailedTests = $failed
    Crashes     = $crashes
    NoLive      = [bool]($all -match 'NO-LIVE')
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ResultFile -Encoding utf8
