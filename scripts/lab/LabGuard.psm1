#Requires -Version 7.4
# LabGuard: the guard and helpers behind scripts/lab/lab-up.ps1, lab-down.ps1, lab-sweep.ps1.
#
# Every live action goes through Invoke-LabAz, which is the only function here that runs the
# Azure CLI. The Pester tests in scripts/lab/tests mock Invoke-LabAz, so the guard logic is
# tested offline and the real `az` is never called by CI.
#
# Rules (SPEC 3.2 "Deloitte / work-tenant isolation guardrails", 10.1-10.5):
#   - .lab-env.json (gitignored, repo root) must exist and name three ids:
#       expectedTenantId        personal Default Directory, resource labs A00-A04 and A06-A17
#       expectedSubscriptionId  personal subscription inside that tenant
#       expectedEntraTenantId   disposable Entra test tenant, A05 and any directory change
#   - Resource scope: active tenant = expectedTenantId and subscription = expectedSubscriptionId.
#   - Entra scope (unit a05-*, or a script that creates/modifies users, groups, guests, or
#     directory policies): active tenant = expectedEntraTenantId.
#   - Either scope: refuse a tenant that looks corporate (name, domain, or signed-in user
#     contains 'deloitte' or a configured pattern; or the tenant has a verified custom domain
#     that is not explicitly allowed).
#   - Resource scope, every unit except a02: the A02 budget must exist (Test-LabBudget).
#   - Persistent groups (tag lifecycle=persistent, e.g. the A02 guardrails group holding the
#     budget's action group) are never deleted by lab-down without -IncludePersistent.
#   - Refusals throw LabGuardRefusal; the scripts turn that into exit code 3 (SPEC 7.7).
Set-StrictMode -Version 3.0

$script:CourseTag = 'LearnAzureByGrinding'
$script:GuardrailsUnit = 'a02-cost-and-guardrails'
$script:BuiltInCorporatePatterns = @('deloitte')
$script:GuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

class LabGuardRefusal : System.Exception {
    [string[]]$Reasons
    LabGuardRefusal([string[]]$reasons) : base(("lab guard refused:`n  - " + ($reasons -join "`n  - "))) { $this.Reasons = $reasons }
}

function Stop-Lab([string[]]$Reasons) { throw [LabGuardRefusal]::new($Reasons) }

function Invoke-LabAz {
    <# The only call to the real Azure CLI. Returns parsed JSON (or $null for empty output). Mocked in tests. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments)
    $out = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "az $($Arguments -join ' ') failed (exit $LASTEXITCODE): $(@($out) -join ' ')" }
    $text = (@($out) -join "`n").Trim()
    if (-not $text) { return $null }
    $text | ConvertFrom-Json -Depth 50
}

function Get-LabRoot {
    param([string]$Start = $PSScriptRoot)
    $d = (Resolve-Path -LiteralPath $Start).Path
    while ($d) {
        if (Test-Path (Join-Path $d 'lib/AzGrinding.psd1')) { return $d }
        $p = Split-Path $d -Parent; if (-not $p -or $p -eq $d) { break }; $d = $p
    }
    throw 'course root not found'
}

function Read-LabEnv {
    <# Loads and validates .lab-env.json. Missing file or bad values: LabGuardRefusal. #>
    [CmdletBinding()]
    param([string]$Path = (Join-Path (Get-LabRoot) '.lab-env.json'))
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Stop-Lab @("$Path is missing. Copy .lab-env.example.json to .lab-env.json and fill in your personal tenant, subscription, and Entra test tenant ids (SPEC 3.2).")
    }
    try { $j = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -AsHashtable -Depth 10 }
    catch { Stop-Lab @(".lab-env.json is not valid JSON: $($_.Exception.Message)") }
    $r = [System.Collections.Generic.List[string]]::new()
    foreach ($k in 'expectedTenantId', 'expectedSubscriptionId', 'expectedEntraTenantId') {
        if (-not $j.ContainsKey($k) -or "$($j[$k])" -notmatch $script:GuidPattern) { $r.Add(".lab-env.json: $k must be a GUID") }
    }
    foreach ($k in 'expectedTenantId', 'expectedSubscriptionId', 'expectedEntraTenantId') {
        if ($j.ContainsKey($k) -and "$($j[$k])" -eq '00000000-0000-0000-0000-000000000000') { $r.Add(".lab-env.json: $k is still the placeholder all-zero GUID") }
    }
    if (-not $r.Count -and $j.expectedTenantId -eq $j.expectedEntraTenantId) {
        $r.Add('.lab-env.json: expectedEntraTenantId must be the disposable A05 test tenant, not the same tenant as expectedTenantId')
    }
    $envObj = [ordered]@{
        expectedTenantId       = "$($j['expectedTenantId'])".ToLowerInvariant()
        expectedSubscriptionId = "$($j['expectedSubscriptionId'])".ToLowerInvariant()
        expectedEntraTenantId  = "$($j['expectedEntraTenantId'])".ToLowerInvariant()
        prefix                 = if ($j.ContainsKey('prefix')) { [string]$j.prefix } else { 'lagb' }
        location               = if ($j.ContainsKey('location')) { [string]$j.location } else { 'eastus' }
        owner                  = if ($j.ContainsKey('owner')) { [string]$j.owner } else { 'n8' }
        budgetName             = 'lagb-monthly'
        budgetAmount           = 25
        budgetContactEmail     = ''
        guardrailsResourceGroup = 'lagb-guardrails'
        allowedCustomDomains   = @(if ($j.ContainsKey('allowedCustomDomains')) { $j.allowedCustomDomains | ForEach-Object { "$_".ToLowerInvariant() } })
        corporatePatterns      = @($script:BuiltInCorporatePatterns + @(if ($j.ContainsKey('corporatePatterns')) { $j.corporatePatterns }) |
                ForEach-Object { "$_".ToLowerInvariant() } | Where-Object { $_ } | Select-Object -Unique)
    }
    if ($envObj.prefix -notmatch '^[a-z][a-z0-9]{1,9}$') { $r.Add('.lab-env.json: prefix must be 2-10 lowercase letters/digits, starting with a letter') }
    if ($j.ContainsKey('budget')) {
        $b = $j.budget
        if ($b -isnot [System.Collections.IDictionary]) { $r.Add('.lab-env.json: budget must be an object { "name", "amount", "contactEmail" }') }
        else {
            if ($b.Contains('name')) { $envObj.budgetName = [string]$b.name }
            if ($b.Contains('amount')) { $envObj.budgetAmount = $b.amount }
            if ($b.Contains('contactEmail')) { $envObj.budgetContactEmail = [string]$b.contactEmail }
            if ($envObj.budgetName -notmatch '^[A-Za-z0-9_-]{1,63}$') { $r.Add('.lab-env.json: budget.name must be 1-63 letters, digits, - or _') }
            $amt = 0.0
            if (-not [double]::TryParse("$($envObj.budgetAmount)", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$amt) -or $amt -le 0) { $r.Add('.lab-env.json: budget.amount must be a number > 0') }
            else { $envObj.budgetAmount = $amt }
            if ($envObj.budgetContactEmail -and $envObj.budgetContactEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { $r.Add('.lab-env.json: budget.contactEmail is not an email address') }
        }
    }
    if ($j.ContainsKey('guardrails')) {
        $g = $j.guardrails
        if ($g -isnot [System.Collections.IDictionary]) { $r.Add('.lab-env.json: guardrails must be an object { "resourceGroup" }') }
        elseif ($g.Contains('resourceGroup')) { $envObj.guardrailsResourceGroup = [string]$g.resourceGroup }
    }
    if ($envObj.guardrailsResourceGroup -notmatch '^[A-Za-z0-9._()-]{1,90}$' -or $envObj.guardrailsResourceGroup.EndsWith('.')) {
        $r.Add('.lab-env.json: guardrails.resourceGroup is not a valid resource group name')
    }
    if ($r.Count) { Stop-Lab $r }
    [pscustomobject]$envObj
}

function Get-LabScope {
    <# 'Entra' for unit a05-* or when the caller says it changes the directory; otherwise 'Resource'. #>
    param([string]$Unit, [switch]$DirectoryChange)
    if ($DirectoryChange -or $Unit -match '^a05(-|$)') { 'Entra' } else { 'Resource' }
}

function Test-CorporateTenant {
    <# Reasons a tenant looks like a work directory (empty = looks personal). #>
    param([AllowNull()]$Tenant, [string]$UserName, [Parameter(Mandatory)]$LabEnv)
    $reasons = [System.Collections.Generic.List[string]]::new()
    $names = @()
    if ($Tenant) {
        foreach ($p in 'displayName', 'defaultDomain') { if ($Tenant.PSObject.Properties[$p] -and $Tenant.$p) { $names += [string]$Tenant.$p } }
    }
    $domains = @(if ($Tenant -and $Tenant.PSObject.Properties['domains']) { $Tenant.domains | ForEach-Object { "$_".ToLowerInvariant() } })
    foreach ($pat in $LabEnv.corporatePatterns) {
        foreach ($v in @($names + $domains + @($UserName) | Where-Object { $_ })) {
            if ($v.ToLowerInvariant().Contains($pat)) { $reasons.Add("tenant or account '$v' matches corporate pattern '$pat'") }
        }
    }
    foreach ($d in $domains) {
        if ($d -like '*.onmicrosoft.com') { continue }
        if ($d -in $LabEnv.allowedCustomDomains) { continue }
        $reasons.Add("tenant has verified custom domain '$d' (work directories have these; add it to allowedCustomDomains only if it is yours)")
    }
    @($reasons | Select-Object -Unique)
}

function Assert-LabContext {
    <#
      Compares the signed-in Azure CLI context with .lab-env.json for -Scope Resource|Entra and
      refuses (LabGuardRefusal) on any mismatch or corporate-looking tenant. Read-only az calls:
      `az account show` and `az account tenant list`.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$LabEnv, [Parameter(Mandatory)][ValidateSet('Resource', 'Entra')][string]$Scope)
    try { $acct = Invoke-LabAz -Arguments @('account', 'show') }
    catch { Stop-Lab @("cannot read the Azure CLI context (are you signed in to the right tenant?): $($_.Exception.Message)") }
    if (-not $acct) { Stop-Lab @('az account show returned nothing; sign in with az login --tenant <id>') }
    $tid = "$($acct.tenantId)".ToLowerInvariant()
    $sid = "$($acct.id)".ToLowerInvariant()
    $user = if ($acct.PSObject.Properties['user'] -and $acct.user) { [string]$acct.user.name } else { '' }
    $r = [System.Collections.Generic.List[string]]::new()
    if ($Scope -eq 'Entra') {
        if ($tid -ne $LabEnv.expectedEntraTenantId) {
            $r.Add("Entra-scope work (A05 / users, groups, guests, directory policies) must run in expectedEntraTenantId $($LabEnv.expectedEntraTenantId); active tenant is $tid. Run: az login --tenant $($LabEnv.expectedEntraTenantId) --allow-no-subscriptions")
        }
    } else {
        if ($tid -ne $LabEnv.expectedTenantId) { $r.Add("active tenant $tid is not expectedTenantId $($LabEnv.expectedTenantId). Run: az login --tenant $($LabEnv.expectedTenantId)") }
        if ($sid -ne $LabEnv.expectedSubscriptionId) { $r.Add("active subscription $sid is not expectedSubscriptionId $($LabEnv.expectedSubscriptionId). Run: az account set --subscription $($LabEnv.expectedSubscriptionId)") }
    }
    $tenant = $null
    try { $tenant = @(Invoke-LabAz -Arguments @('account', 'tenant', 'list')) | Where-Object { "$($_.tenantId)".ToLowerInvariant() -eq $tid } | Select-Object -First 1 }
    catch { $r.Add("cannot read tenant details to rule out a work directory: $($_.Exception.Message)") }
    if (-not $tenant -and -not ($r | Where-Object { $_ -like 'cannot read tenant*' })) { $r.Add("tenant $tid is not in az account tenant list; cannot rule out a work directory") }
    $corp = @(Test-CorporateTenant -Tenant $tenant -UserName $user -LabEnv $LabEnv)
    if (-not $tenant -and $acct.PSObject.Properties['tenantDisplayName']) {
        $corp = @(Test-CorporateTenant -Tenant ([pscustomobject]@{ displayName = $acct.tenantDisplayName; defaultDomain = $acct.tenantDefaultDomain }) -UserName $user -LabEnv $LabEnv)
    }
    foreach ($c in $corp) { $r.Add("looks corporate: $c") }
    if ($r.Count) { Stop-Lab $r }
    [pscustomobject]@{ Scope = $Scope; TenantId = $tid; SubscriptionId = $sid; User = $user; TenantName = if ($tenant) { $tenant.displayName } else { '' } }
}

function Test-LabBudget {
    <#
      True when a subscription-scope budget named .lab-env.json budget.name (default lagb-monthly)
      with amount > 0 exists, per `az consumption budget list` (subscription scope; the CLI
      prints amount as a string). Alerts, thresholds, Forecasted, the ceiling, and tags are NOT checked.
    #>
    param([Parameter(Mandatory)]$LabEnv)
    $budgets = @(Invoke-LabAz -Arguments @('consumption', 'budget', 'list'))
    [bool](@($budgets | Where-Object {
                $a = 0.0
                $_ -and $_.name -eq $LabEnv.budgetName -and
                [double]::TryParse("$($_.amount)", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$a) -and $a -gt 0
            }).Count)
}

function New-LabTags {
    <# SPEC 10.2 tags: course, unit, exercise, expires (UTC, ISO 8601), owner. #>
    param([Parameter(Mandatory)][string]$Unit, [Parameter(Mandatory)][string]$ExerciseId, [Parameter(Mandatory)][string]$Owner,
        [int]$ExpiresInHours = 8, [datetime]$Now = [datetime]::UtcNow)
    [ordered]@{
        course   = $script:CourseTag
        unit     = $Unit
        exercise = $ExerciseId
        expires  = $Now.ToUniversalTime().AddHours($ExpiresInHours).ToString("yyyy-MM-ddTHH:mm:ssZ")
        owner    = $Owner
    }
}

function Get-LabResourceGroupName {
    param([Parameter(Mandatory)][string]$Prefix, [Parameter(Mandatory)][string]$ExerciseId)
    $n = "$Prefix-$ExerciseId"
    if ($n.Length -gt 90) { $n = $n.Substring(0, 90) }
    $n
}

function New-LabResourceGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Location, [Parameter(Mandatory)][System.Collections.IDictionary]$Tags)
    $tagArgs = @($Tags.Keys | ForEach-Object { "$_=$($Tags[$_])" })
    if ($PSCmdlet.ShouldProcess($Name, "create resource group in $Location with tags $($tagArgs -join ' ')")) {
        Invoke-LabAz -Arguments (@('group', 'create', '--name', $Name, '--location', $Location, '--tags') + $tagArgs)
    }
}

function Start-LabDeployment {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$ResourceGroup, [Parameter(Mandatory)][string]$TemplateFile, [string]$ParameterFile, [string]$Name = ('lagb-' + [datetime]::UtcNow.ToString('yyyyMMddHHmmss')))
    $a = @('deployment', 'group', 'create', '--resource-group', $ResourceGroup, '--name', $Name, '--template-file', $TemplateFile)
    if ($ParameterFile) { $a += @('--parameters', $ParameterFile) }
    if ($PSCmdlet.ShouldProcess($ResourceGroup, "deploy $(Split-Path $TemplateFile -Leaf)")) { Invoke-LabAz -Arguments $a }
}

function Start-LabSubscriptionDeployment {
    <# az deployment sub create (subscription scope). -Parameters are 'name=value' strings and/or a parameter file path. #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Location, [Parameter(Mandatory)][string]$TemplateFile, [string[]]$Parameters = @(),
        [string]$Name = ('lagb-sub-' + [datetime]::UtcNow.ToString('yyyyMMddHHmmss')))
    $a = @('deployment', 'sub', 'create', '--location', $Location, '--name', $Name, '--template-file', $TemplateFile)
    if ($Parameters.Count) { $a += @('--parameters') + $Parameters }
    if ($PSCmdlet.ShouldProcess("subscription", "deploy $(Split-Path $TemplateFile -Leaf) at subscription scope")) { Invoke-LabAz -Arguments $a }
}

function Get-LabGuardrailTags {
    <#
      Tags for the persistent guardrails group: the New-LabTags set minus expires, with
      unit=a02-cost-and-guardrails and lifecycle=persistent. -Tags is lab-up's New-LabTags dictionary
      (adds its exercise tag); without it: course, unit, lifecycle, owner.
    #>
    param([Parameter(Mandatory)]$LabEnv, [System.Collections.IDictionary]$Tags)
    $t = [ordered]@{ course = $script:CourseTag; unit = $script:GuardrailsUnit }
    if ($Tags) { foreach ($k in $Tags.Keys) { if ($k -notin 'course', 'unit', 'expires', 'lifecycle', 'owner') { $t[$k] = $Tags[$k] } } }
    $t['lifecycle'] = 'persistent'
    $t['owner'] = if ($Tags -and $Tags.Contains('owner')) { $Tags['owner'] } else { $LabEnv.owner }
    $t
}

function New-LabGuardrailsGroup {
    <# Creates or reuses (az group create is idempotent) the persistent guardrails group from .lab-env.json guardrails.resourceGroup. #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)]$LabEnv, [System.Collections.IDictionary]$Tags)
    New-LabResourceGroup -Name $LabEnv.guardrailsResourceGroup -Location $LabEnv.location -Tags (Get-LabGuardrailTags -LabEnv $LabEnv -Tags $Tags) -WhatIf:$WhatIfPreference
}

function Test-LabPersistent {
    param([Parameter(Mandatory)]$Group)
    [bool]($Group.PSObject.Properties['tags'] -and $Group.tags -and $Group.tags.PSObject.Properties['lifecycle'] -and $Group.tags.lifecycle -eq 'persistent')
}

function Get-CourseResourceGroups {
    <# Resource groups tagged course=LearnAzureByGrinding whose name starts with '<prefix>-', optionally filtered by unit and exercise tags. #>
    param([Parameter(Mandatory)][string]$Prefix, [string]$Unit, [string]$ExerciseId)
    @(Invoke-LabAz -Arguments @('group', 'list', '--tag', "course=$($script:CourseTag)")) | Where-Object {
        $_ -and $_.tags -and $_.tags.course -eq $script:CourseTag -and $_.name.StartsWith("$Prefix-") -and
        (-not $Unit -or ($_.tags.PSObject.Properties['unit'] -and $_.tags.unit -eq $Unit)) -and
        (-not $ExerciseId -or ($_.tags.PSObject.Properties['exercise'] -and $_.tags.exercise -eq $ExerciseId))
    }
}

$script:SoftDelete = [ordered]@{
    'Microsoft.KeyVault/vaults'                   = 'Key Vault {0} stays soft-deleted (7-90 days) and keeps its name reserved. If purge protection is off: az keyvault purge --name {0} --location {1}. List: az keyvault list-deleted'
    'Microsoft.KeyVault/managedHSMs'              = 'Managed HSM {0} is billed while soft-deleted. Purge: az keyvault purge --hsm-name {0} --location {1}'
    'Microsoft.RecoveryServices/vaults'           = 'Recovery Services vault {0}: the group delete fails while it holds backup items or replicated items. Stop protection and delete backup data (soft-deleted items are kept 14 days), disable soft delete for labs, then delete the vault. See https://learn.microsoft.com/azure/backup/backup-azure-delete-vault'
    'Microsoft.DataProtection/backupVaults'       = 'Backup vault {0}: soft-deleted backup instances are kept for the retention period and block deletion; delete them first.'
    'Microsoft.CognitiveServices/accounts'        = 'Azure AI services account {0} stays soft-deleted for 48 hours. Purge: az cognitiveservices account purge --name {0} --resource-group <rg> --location {1}'
    'Microsoft.OperationalInsights/workspaces'    = 'Log Analytics workspace {0} is soft-deleted for 14 days. To delete permanently: az monitor log-analytics workspace delete --force true --workspace-name {0} --resource-group <rg>'
    'Microsoft.ApiManagement/service'             = 'API Management {0} is soft-deleted for 48 hours. Purge: az apim deletedservice purge --service-name {0} --location {1}'
    'Microsoft.AppConfiguration/configurationStores' = 'App Configuration store {0} may be soft-deleted. Purge: az appconfig purge --name {0}'
}

function Get-SoftDeleteWarnings {
    <# Purge / soft-delete warnings for the resources about to be deleted. #>
    param([object[]]$Resources = @())
    foreach ($r in $Resources) {
        if (-not $r) { continue }
        $k = @($script:SoftDelete.Keys | Where-Object { $_ -ieq $r.type })
        if ($k.Count) { $script:SoftDelete[$k[0]] -f $r.name, $r.location }
    }
}

function Get-ResourceRisk {
    <# Cost risk if left running (SPEC 10.4). #>
    param([Parameter(Mandatory)][string]$Type)
    $high = 'Microsoft.Network/bastionHosts', 'Microsoft.Network/publicIPAddresses', 'Microsoft.Compute/virtualMachines',
    'Microsoft.Compute/virtualMachineScaleSets', 'Microsoft.Web/serverfarms', 'Microsoft.Network/loadBalancers',
    'Microsoft.RecoveryServices/vaults', 'Microsoft.Network/azureFirewalls', 'Microsoft.Network/virtualNetworkGateways',
    'Microsoft.Network/applicationGateways', 'Microsoft.ContainerService/managedClusters', 'Microsoft.Network/natGateways'
    $medium = 'Microsoft.Compute/disks', 'Microsoft.ContainerRegistry/registries', 'Microsoft.App/managedEnvironments',
    'Microsoft.ContainerInstance/containerGroups', 'Microsoft.OperationalInsights/workspaces', 'Microsoft.Network/dnsZones',
    'Microsoft.Network/privateEndpoints', 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts', 'Microsoft.Compute/snapshots'
    if ($high | Where-Object { $_ -ieq $Type }) { return 'HIGH' }
    if ($medium | Where-Object { $_ -ieq $Type }) { return 'MEDIUM' }
    'LOW'
}

function Remove-LabResourceGroup {
    <# Deletes one course-tagged lab resource group after printing soft-delete warnings. Refuses an untagged group. #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)]$Group, [Parameter(Mandatory)][string]$Prefix, [switch]$IncludePersistent)
    if (-not ($Group.tags -and $Group.tags.course -eq $script:CourseTag -and $Group.name.StartsWith("$Prefix-"))) {
        Stop-Lab @("refusing to delete $($Group.name): it is not tagged course=$($script:CourseTag) with prefix '$Prefix-'")
    }
    if ((Test-LabPersistent -Group $Group) -and -not $IncludePersistent) {
        $why = "skipped $($Group.name): tagged lifecycle=persistent (the A02 guardrails group; the budget's action group lives there). Pass -IncludePersistent to delete it."
        Write-Host "lab-down: $why" -ForegroundColor Yellow
        return [pscustomobject]@{ Name = $Group.name; Resources = 0; Warnings = @(); Skipped = $true; Reason = $why }
    }
    $res = @(Invoke-LabAz -Arguments @('resource', 'list', '--resource-group', $Group.name))
    $warn = @(Get-SoftDeleteWarnings -Resources $res)
    foreach ($w in $warn) { Write-Warning $w }
    if ($PSCmdlet.ShouldProcess($Group.name, "delete resource group ($($res.Count) resource(s))")) {
        $null = Invoke-LabAz -Arguments @('group', 'delete', '--name', $Group.name, '--yes', '--no-wait')
    }
    [pscustomobject]@{ Name = $Group.name; Resources = $res.Count; Warnings = $warn; Skipped = $false; Reason = '' }
}

function Get-LabLeftovers {
    <# Course-tagged groups and resources (with risk and expiry) plus soft-deleted Key Vaults. Read-only. #>
    param([datetime]$Now = [datetime]::UtcNow)
    $tag = "course=$($script:CourseTag)"
    $groups = @(Invoke-LabAz -Arguments @('group', 'list', '--tag', $tag) | Where-Object { $_ })
    $resources = @(Invoke-LabAz -Arguments @('resource', 'list', '--tag', $tag) | Where-Object { $_ })
    $deletedKv = @(try { Invoke-LabAz -Arguments @('keyvault', 'list-deleted') | Where-Object { $_ } } catch { @() })
    $rows = @(foreach ($x in @($groups) + @($resources)) {
        $exp = if ($x.PSObject.Properties['tags'] -and $x.tags -and $x.tags.PSObject.Properties['expires']) { [string]$x.tags.expires } else { '' }
        $expired = $false
        if ($exp) {
            $d = [datetime]::MinValue
            if ([datetime]::TryParse($exp, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$d)) { $expired = $d -lt $Now.ToUniversalTime() }
        }
        $type = if ($x.PSObject.Properties['type'] -and $x.type) { [string]$x.type } else { 'Microsoft.Resources/resourceGroups' }
        [pscustomobject]@{
            Risk     = if ($type -eq 'Microsoft.Resources/resourceGroups') { '-' } else { Get-ResourceRisk -Type $type }
            Name     = $x.name; Type = $type; Location = $x.location
            Expires  = $exp; Expired = if ($expired) { 'EXPIRED' } else { '' }
        }
    })
    $persistentNames = @($groups | Where-Object { Test-LabPersistent -Group $_ } | ForEach-Object name)
    $isPersistent = {
        param($row, $src)
        if ($row.Type -eq 'Microsoft.Resources/resourceGroups') { return $row.Name -in $persistentNames }
        $rg = if ($src.PSObject.Properties['resourceGroup']) { [string]$src.resourceGroup } else { '' }
        ($rg -and ($persistentNames | Where-Object { $_ -ieq $rg })) -or (Test-LabPersistent -Group $src)
    }
    $all = @($groups) + @($resources)
    $keep = [System.Collections.Generic.List[object]]::new(); $left = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $rows.Count; $i++) { if (& $isPersistent $rows[$i] $all[$i]) { $keep.Add($rows[$i]) } else { $left.Add($rows[$i]) } }
    [pscustomobject]@{ Rows = @($left); Persistent = @($keep); DeletedKeyVaults = $deletedKv }
}

Export-ModuleMember -Function Invoke-LabAz, Get-LabRoot, Read-LabEnv, Get-LabScope, Test-CorporateTenant, Assert-LabContext,
Test-LabBudget, New-LabTags, Get-LabResourceGroupName, New-LabResourceGroup, Start-LabDeployment, Get-CourseResourceGroups,
Get-SoftDeleteWarnings, Get-ResourceRisk, Remove-LabResourceGroup, Get-LabLeftovers,
Start-LabSubscriptionDeployment, Get-LabGuardrailTags, New-LabGuardrailsGroup, Test-LabPersistent
