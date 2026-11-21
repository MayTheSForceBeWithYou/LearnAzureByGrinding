# Offline tests for the lab guard and lab-up / lab-down / lab-sweep.
# Invoke-LabAz (the only function that runs the Azure CLI) is mocked, and a global `az`
# function that throws is installed first, so no test can reach the real CLI or Azure.
BeforeAll {
    function global:az { throw 'TEST BUG: the real az was called' }
    $labDir = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $labDir 'LabGuard.psm1') -Force
    Import-Module (Join-Path $labDir '../../lib/AzGrinding.psd1') -Force
    $script:LabUp = Join-Path $labDir 'lab-up.ps1'
    $script:LabDown = Join-Path $labDir 'lab-down.ps1'
    $script:LabSweep = Join-Path $labDir 'lab-sweep.ps1'

    $script:Personal = '11111111-1111-1111-1111-111111111111'
    $script:Sub = '22222222-2222-2222-2222-222222222222'
    $script:EntraTest = '33333333-3333-3333-3333-333333333333'
    $script:Corp = '44444444-4444-4444-4444-444444444444'

    function New-EnvFile([hashtable]$Override = @{}) {
        $o = [ordered]@{
            expectedTenantId = $script:Personal; expectedSubscriptionId = $script:Sub; expectedEntraTenantId = $script:EntraTest
            prefix = 'lagb'; location = 'eastus'; owner = 'n8'; budget = @{ name = 'lagb-monthly'; amount = 25 }
            allowedCustomDomains = @('skopekreep.com'); corporatePatterns = @()
        }
        foreach ($k in $Override.Keys) { $o[$k] = $Override[$k] }
        $p = Join-Path $TestDrive "lab-env-$([guid]::NewGuid().ToString('n')).json"
        $o | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $p
        $p
    }
    function New-Tenant([string]$Id, [string]$Name, [string[]]$Domains) {
        [pscustomobject]@{ tenantId = $Id; displayName = $Name; defaultDomain = $Domains[0]; domains = $Domains }
    }
    # Fake CLI state, keyed by argument prefix; Set-Signin chooses who is signed in.
    function Set-Signin([string]$Tenant, [string]$Subscription = $script:Sub, [string]$User = 'maytheforce@gmail.com', [object[]]$Tenants) {
        if (-not $PSBoundParameters.ContainsKey("Tenants")) {
            $Tenants = @(
                (New-Tenant $script:Personal 'Default Directory' @('maytheforcegmail.onmicrosoft.com')),
                (New-Tenant $script:EntraTest 'LAGB A05 Test' @('lagba05test.onmicrosoft.com'))
            )
        }
        $global:LabTestFake['account show'] = [pscustomobject]@{ id = $(if ($Tenant -eq $script:EntraTest) { $script:EntraTest } else { $Subscription }); tenantId = $Tenant; user = [pscustomobject]@{ name = $User } }
        $global:LabTestFake['account tenant list'] = $Tenants
    }
    function New-Exercise([string]$Unit, [string]$Name, [string[]]$Tags = @('WRITE', 'LAB'), [switch]$UpScript) {
        $d = Join-Path $TestDrive "units/$Unit/$Name"
        $null = New-Item -ItemType Directory -Force -Path $d
        "@{ Tags = @($(($Tags | ForEach-Object { "'$_'" }) -join ', ')); Entry = 'main.bicep'; StudentRegion = 'whole-file'; ExpectResources = @('Microsoft.Storage/storageAccounts') }" |
            Set-Content -LiteralPath (Join-Path $d 'exercise.psd1')
        "targetScope = 'resourceGroup'" | Set-Content -LiteralPath (Join-Path $d 'main.bicep')
        if ($UpScript) { '[CmdletBinding(SupportsShouldProcess)] param($Context, $Tags, $LabEnv) Write-Host "up.ps1 ran in $($Context.TenantId)"' | Set-Content -LiteralPath (Join-Path $d 'up.ps1') }
        $d
    }
    function Get-Calls { @($global:LabTestCalls) }
}

Describe 'lab guard (offline; az mocked)' {
    BeforeEach {
        $global:LabTestCalls = [System.Collections.Generic.List[string]]::new()
        $global:LabTestFake = @{
            'consumption budget list' = @([pscustomobject]@{ name = 'lagb-monthly'; amount = 25 })
            'group create'            = [pscustomobject]@{ name = 'created' }
            'deployment group create' = [pscustomobject]@{ properties = @{ provisioningState = 'Succeeded' } }
            'group list'              = @()
            'resource list'           = @()
            'group delete'            = $null
            'keyvault list-deleted'   = @()
        }
        Set-Signin -Tenant $script:Personal
        Mock -ModuleName LabGuard Invoke-LabAz {
            $line = $Arguments -join ' '
            $global:LabTestCalls.Add($line)
            $key = $global:LabTestFake.Keys | Where-Object { $line -eq $_ -or $line.StartsWith("$_ ") } | Sort-Object Length -Descending | Select-Object -First 1
            if (-not $key) { throw "unexpected az call in test: az $line" }
            $v = $global:LabTestFake[$key]
            if ($v -is [scriptblock]) { & $v } else { $v }
        }
    }

    Describe 'Read-LabEnv' {
        It 'refuses when .lab-env.json is missing' {
            { Read-LabEnv -Path (Join-Path $TestDrive 'nope.json') } | Should -Throw '*is missing*'
        }
        It 'refuses the unedited example (placeholder GUIDs)' {
            $example = Join-Path $PSScriptRoot '../../../.lab-env.example.json'
            { Read-LabEnv -Path $example } | Should -Throw '*placeholder*'
        }
        It 'requires two distinct tenant fields' {
            { Read-LabEnv -Path (New-EnvFile @{ expectedEntraTenantId = $script:Personal }) } | Should -Throw '*expectedEntraTenantId must be the disposable A05 test tenant*'
            { Read-LabEnv -Path (New-EnvFile @{ expectedEntraTenantId = 'not-a-guid' }) } | Should -Throw '*expectedEntraTenantId must be a GUID*'
        }
        It 'loads a valid file and always includes the built-in deloitte pattern' {
            $e = Read-LabEnv -Path (New-EnvFile @{ corporatePatterns = @('acme') })
            $e.expectedEntraTenantId | Should -Be $script:EntraTest
            $e.corporatePatterns | Should -Contain 'deloitte'
            $e.corporatePatterns | Should -Contain 'acme'
        }
    }

    Describe 'Get-LabScope' {
        It 'is Entra for unit A05 and for directory changes, Resource otherwise' {
            Get-LabScope -Unit 'a05-entra-users-groups' | Should -Be 'Entra'
            Get-LabScope -Unit 'a12-virtual-machines' -DirectoryChange | Should -Be 'Entra'
            Get-LabScope -Unit 'a12-virtual-machines' | Should -Be 'Resource'
        }
    }

    Describe 'Assert-LabContext' {
        BeforeEach { $script:E = Read-LabEnv -Path (New-EnvFile) }
        It 'accepts the personal tenant and subscription for resource labs' {
            (Assert-LabContext -LabEnv $script:E -Scope Resource).TenantId | Should -Be $script:Personal
        }
        It 'refuses the wrong tenant for resource labs' {
            Set-Signin -Tenant $script:EntraTest
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*is not expectedTenantId*'
        }
        It 'refuses the wrong subscription' {
            Set-Signin -Tenant $script:Personal -Subscription '99999999-9999-9999-9999-999999999999'
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*is not expectedSubscriptionId*'
        }
        It 'accepts the Entra test tenant for Entra scope' {
            Set-Signin -Tenant $script:EntraTest
            (Assert-LabContext -LabEnv $script:E -Scope Entra).TenantId | Should -Be $script:EntraTest
        }
        It 'refuses Entra-scope work in the personal resource tenant' {
            { Assert-LabContext -LabEnv $script:E -Scope Entra } | Should -Throw '*must run in expectedEntraTenantId*'
        }
        It 'refuses a tenant whose name contains deloitte, in either scope' {
            $t = @((New-Tenant $script:Personal 'Deloitte Touche Tohmatsu' @('x.onmicrosoft.com')))
            Set-Signin -Tenant $script:Personal -Tenants $t
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*corporate pattern*deloitte*'
            $t = @((New-Tenant $script:EntraTest 'deloitte sandbox' @('y.onmicrosoft.com')))
            Set-Signin -Tenant $script:EntraTest -Tenants $t
            { Assert-LabContext -LabEnv $script:E -Scope Entra } | Should -Throw '*corporate pattern*deloitte*'
        }
        It 'refuses a deloitte domain even when it is listed in allowedCustomDomains' {
            $e2 = Read-LabEnv -Path (New-EnvFile @{ allowedCustomDomains = @('deloitte.com') })
            Set-Signin -Tenant $script:Personal -Tenants @((New-Tenant $script:Personal 'Default Directory' @('a.onmicrosoft.com', 'deloitte.com')))
            { Assert-LabContext -LabEnv $e2 -Scope Resource } | Should -Throw '*deloitte*'
        }
        It 'refuses a signed-in work account' {
            Set-Signin -Tenant $script:Personal -User 'n8@deloitte.com'
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*n8@deloitte.com*'
        }
        It 'refuses an unlisted verified custom domain and allows a listed one' {
            Set-Signin -Tenant $script:Personal -Tenants @((New-Tenant $script:Personal 'Default Directory' @('a.onmicrosoft.com', 'contoso.com')))
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw "*custom domain 'contoso.com'*"
            Set-Signin -Tenant $script:Personal -Tenants @((New-Tenant $script:Personal 'Default Directory' @('a.onmicrosoft.com', 'skopekreep.com')))
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Not -Throw
        }
        It 'applies extra corporatePatterns from .lab-env.json' {
            $e2 = Read-LabEnv -Path (New-EnvFile @{ corporatePatterns = @('acme') })
            Set-Signin -Tenant $script:Personal -Tenants @((New-Tenant $script:Personal 'ACME Corp' @('acmecorp.onmicrosoft.com')))
            { Assert-LabContext -LabEnv $e2 -Scope Resource } | Should -Throw "*pattern 'acme'*"
        }
        It 'refuses when the tenant cannot be found in the tenant list' {
            Set-Signin -Tenant $script:Personal -Tenants @()
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*cannot rule out a work directory*'
        }
        It 'refuses when the CLI is not signed in' {
            $global:LabTestFake['account show'] = { throw 'Please run az login' }
            { Assert-LabContext -LabEnv $script:E -Scope Resource } | Should -Throw '*cannot read the Azure CLI context*'
        }
        It 'only makes read-only calls' {
            $null = Assert-LabContext -LabEnv $script:E -Scope Resource
            Get-Calls | Should -Be @('account show', 'account tenant list')
        }
    }

    Describe 'helpers' {
        It 'tags carry course, unit, exercise, expires, owner' {
            $t = New-LabTags -Unit 'a12-virtual-machines' -ExerciseId 'a12-e03-vm' -Owner 'n8' -ExpiresInHours 2 -Now ([datetime]'2026-11-21T10:00:00Z').ToUniversalTime()
            $t.course | Should -Be 'LearnAzureByGrinding'
            $t.expires | Should -Be '2026-11-21T12:00:00Z'
            @($t.Keys) | Should -Be @('course', 'unit', 'exercise', 'expires', 'owner')
        }
        It 'warns about soft delete for vaults' {
            $w = Get-SoftDeleteWarnings -Resources @(
                [pscustomobject]@{ type = 'Microsoft.KeyVault/vaults'; name = 'kv1'; location = 'eastus' },
                [pscustomobject]@{ type = 'Microsoft.RecoveryServices/vaults'; name = 'rsv1'; location = 'eastus' },
                [pscustomobject]@{ type = 'Microsoft.Storage/storageAccounts'; name = 'st1'; location = 'eastus' })
            $w.Count | Should -Be 2
            $w[0] | Should -Match 'az keyvault purge --name kv1'
            $w[1] | Should -Match 'Recovery Services vault rsv1'
        }
        It 'classifies cost risk' {
            Get-ResourceRisk -Type 'Microsoft.Network/bastionHosts' | Should -Be 'HIGH'
            Get-ResourceRisk -Type 'Microsoft.Network/virtualNetworks' | Should -Be 'LOW'
        }
    }

    Describe 'lab-up.ps1' {
        It 'refuses (exit 3) without .lab-env.json and calls nothing' {
            $ex = New-Exercise 'a12-virtual-machines' 'e03-vm-lab'
            & $script:LabUp -Path $ex -EnvFile (Join-Path $TestDrive 'missing.json') *> $null
            $LASTEXITCODE | Should -Be 3
            Get-Calls | Should -BeNullOrEmpty
        }
        It 'refuses (exit 3) in a deloitte tenant and creates nothing' {
            Set-Signin -Tenant $script:Personal -Tenants @((New-Tenant $script:Personal 'Deloitte' @('deloitte.onmicrosoft.com')))
            & $script:LabUp -Path (New-Exercise 'a12-virtual-machines' 'e03-vm-lab') -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 3
            Get-Calls | Where-Object { $_ -like 'group create*' -or $_ -like 'deployment*' } | Should -BeNullOrEmpty
        }
        It 'refuses an A05 lab unless signed in to the Entra test tenant' {
            $ex = New-Exercise 'a05-entra-users-groups' 'e02-group-lab' -UpScript
            & $script:LabUp -Path $ex -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 3
            Set-Signin -Tenant $script:EntraTest
            & $script:LabUp -Path $ex -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 0
        }
        It 'refuses a non-LAB exercise (exit 2)' {
            & $script:LabUp -Path (New-Exercise 'a12-virtual-machines' 'e01-write' -Tags @('WRITE')) -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 2
        }
        It '-WhatIf runs the guard but creates nothing' {
            & $script:LabUp -Path (New-Exercise 'a12-virtual-machines' 'e03-vm-lab') -EnvFile (New-EnvFile) -WhatIf *> $null
            $LASTEXITCODE | Should -Be 0
            Get-Calls | Where-Object { $_ -like 'group create*' -or $_ -like 'deployment*' } | Should -BeNullOrEmpty
        }
        It 'creates a tagged resource group and deploys when every gate passes' {
            & $script:LabUp -Path (New-Exercise 'a12-virtual-machines' 'e03-vm-lab') -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 0
            $create = Get-Calls | Where-Object { $_ -like 'group create*' }
            $create | Should -Match '--name lagb-a12-e03-vm-lab --location eastus --tags course=LearnAzureByGrinding unit=a12-virtual-machines exercise=a12-e03-vm-lab expires=\S+Z owner=n8'
            Get-Calls | Where-Object { $_ -like 'deployment group create*' } | Should -Match '--resource-group lagb-a12-e03-vm-lab'
        }
        It 'refuses without the A02 budget unless -BudgetOverride' {
            $global:LabTestFake['consumption budget list'] = @()
            $ex = New-Exercise 'a12-virtual-machines' 'e03-vm-lab'
            & $script:LabUp -Path $ex -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 3
            & $script:LabUp -Path $ex -EnvFile (New-EnvFile) -BudgetOverride *> $null
            $LASTEXITCODE | Should -Be 0
        }
        It 'does not need the budget for the A02 budget lab itself' {
            $global:LabTestFake['consumption budget list'] = @()
            & $script:LabUp -Path (New-Exercise 'a02-cost-control' 'e04-budget-lab') -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 0
        }
    }

    Describe 'lab-down.ps1' {
        BeforeEach {
            $tag = { param($u, $e) [pscustomobject]@{ course = 'LearnAzureByGrinding'; unit = $u; exercise = $e } }
            $global:LabTestFake['group list'] = @(
                [pscustomobject]@{ name = 'lagb-a12-e03-vm-lab'; tags = (& $tag 'a12-virtual-machines' 'a12-e03-vm-lab') },
                [pscustomobject]@{ name = 'lagb-a12-e04-other'; tags = (& $tag 'a12-virtual-machines' 'a12-e04-other') },
                [pscustomobject]@{ name = 'lagb-a13-e01-acr'; tags = (& $tag 'a13-containers' 'a13-e01-acr') },
                [pscustomobject]@{ name = 'my-own-rg'; tags = (& $tag 'a12-virtual-machines' 'a12-e03-vm-lab') }
            )
            $global:LabTestFake['resource list'] = @([pscustomobject]@{ type = 'Microsoft.KeyVault/vaults'; name = 'kv1'; location = 'eastus' })
        }
        It 'deletes only the exercise''s tagged, prefixed group and warns about soft delete' {
            $out = & $script:LabDown -Path (New-Exercise 'a12-virtual-machines' 'e03-vm-lab') -EnvFile (New-EnvFile) 3>&1 6>&1 | Out-String
            $LASTEXITCODE | Should -Be 0
            Get-Calls | Where-Object { $_ -like 'group delete*' } | Should -Be @('group delete --name lagb-a12-e03-vm-lab --yes --no-wait')
            $out | Should -Match 'az keyvault purge --name kv1'
        }
        It 'deletes every tagged group of a unit, never another unit''s or an unprefixed group' {
            & $script:LabDown -Unit 'a12-virtual-machines' -EnvFile (New-EnvFile) *> $null
            $d = Get-Calls | Where-Object { $_ -like 'group delete*' }
            $d | Should -Be @('group delete --name lagb-a12-e03-vm-lab --yes --no-wait', 'group delete --name lagb-a12-e04-other --yes --no-wait')
        }
        It '-WhatIf deletes nothing' {
            & $script:LabDown -Unit 'a12-virtual-machines' -EnvFile (New-EnvFile) -WhatIf *> $null
            $LASTEXITCODE | Should -Be 0
            Get-Calls | Where-Object { $_ -like 'group delete*' } | Should -BeNullOrEmpty
        }
        It 'refuses (exit 3) in the wrong subscription and deletes nothing' {
            Set-Signin -Tenant $script:Personal -Subscription '99999999-9999-9999-9999-999999999999'
            & $script:LabDown -Unit 'a12-virtual-machines' -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 3
            Get-Calls | Where-Object { $_ -like 'group delete*' } | Should -BeNullOrEmpty
        }
        It 'Remove-LabResourceGroup refuses an untagged group outright' {
            { Remove-LabResourceGroup -Group ([pscustomobject]@{ name = 'lagb-x'; tags = $null }) -Prefix 'lagb' } | Should -Throw '*refusing to delete*'
        }
    }

    Describe 'lab-sweep.ps1' {
        It 'lists leftovers with risk and expiry (exit 1) and deletes nothing' {
            $global:LabTestFake['resource list'] = @([pscustomobject]@{ name = 'bas1'; type = 'Microsoft.Network/bastionHosts'; location = 'eastus'; tags = [pscustomobject]@{ course = 'LearnAzureByGrinding'; expires = '2026-11-20T00:00:00Z' } })
            $out = & $script:LabSweep -EnvFile (New-EnvFile) -Now ([datetime]'2026-11-21T00:00:00Z').ToUniversalTime() 6>&1 | Out-String
            $LASTEXITCODE | Should -Be 1
            $out | Should -Match 'HIGH'
            $out | Should -Match 'EXPIRED'
            Get-Calls | Where-Object { $_ -match '(^| )(delete|purge)( |$)' } | Should -BeNullOrEmpty
        }
        It 'exits 0 when nothing is left' {
            $o = & $script:LabSweep -EnvFile (New-EnvFile) *>&1 | Out-String
            $LASTEXITCODE | Should -Be 0 -Because $o
        }
        It 'refuses (exit 3) in a corporate tenant' {
            Set-Signin -Tenant $script:Personal -User 'someone@deloitte.com'
            & $script:LabSweep -EnvFile (New-EnvFile) *> $null
            $LASTEXITCODE | Should -Be 3
        }
    }
}

AfterAll {
    Remove-Item -Path function:global:az -ErrorAction SilentlyContinue
    Remove-Variable -Name LabTestCalls, LabTestFake -Scope Global -ErrorAction SilentlyContinue
}
