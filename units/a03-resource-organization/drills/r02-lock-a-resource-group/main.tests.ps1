BeforeAll {
    function Get-ExtensionResourcePlacements {
        param(
            [Parameter(Mandatory)][System.Collections.IDictionary]$Template,
            [Parameter(Mandatory)][string]$Type
        )
        $hits = [System.Collections.Generic.List[object]]::new()
        function Walk([object]$resources, [string]$At) {
            if ($null -eq $resources) { return }
            foreach ($r in @($resources)) {
                if ($r -isnot [System.Collections.IDictionary] -or -not $r.Contains('type')) { continue }
                $t = [string]$r['type']
                if ($t -ieq $Type) {
                    $hits.Add([pscustomobject]@{ Resource = $r; Name = $r['name']; At = $At })
                }
                if ($t -ieq 'Microsoft.Resources/deployments') {
                    $child = $At
                    if ($r.Contains('resourceGroup') -and $null -ne $r['resourceGroup'] -and "$($r['resourceGroup'])") {
                        $child = 'resourceGroup'
                    }
                    $inner = $null
                    if ($r.Contains('properties') -and $r['properties'] -is [System.Collections.IDictionary]) {
                        $p = $r['properties']
                        if ($p.Contains('template') -and $p['template'] -is [System.Collections.IDictionary] -and $p['template'].Contains('resources')) {
                            $inner = $p['template']['resources']
                        }
                    }
                    Walk $inner $child
                }
                if ($r.Contains('resources')) { Walk $r['resources'] $At }
            }
        }
        $rootAt = if ("$($Template['$schema'])" -match 'subscriptionDeploymentTemplate') { 'subscription' } else { 'resourceGroup' }
        if ($Template.Contains('resources')) { Walk $Template['resources'] $rootAt }
        @($hits)
    }

    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a03-r02-lock-a-resource-group' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'the resource group uses the lagb- prefix and the course tag' {
        $rg = @(Get-TemplateResources -Template $template -Type 'Microsoft.Resources/resourceGroups')
        $rg.Count | Should -Be 1
        "$($rg[0].Name)" | Should -Match 'lagb-'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'location'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.course'; Value = 'LearnAzureByGrinding' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.unit'; Value = 'a03-resource-organization' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.exercise'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.owner'; Match = '.' }
            @{ ResourceType = 'Microsoft.Resources/resourceGroups'; Path = 'tags.expires'; Match = '.' }
        ) | Should -BeNullOrEmpty
    }

    It 'the lock is CanNotDelete on the resource group' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Authorization/locks'; Path = 'properties.level'; Value = 'CanNotDelete' }
        ) | Should -BeNullOrEmpty
        $lock = @(Get-ExtensionResourcePlacements -Template $template -Type 'Microsoft.Authorization/locks')
        $lock.Count | Should -Be 1
        $lock[0].At | Should -Be 'resourceGroup'
    }
}
