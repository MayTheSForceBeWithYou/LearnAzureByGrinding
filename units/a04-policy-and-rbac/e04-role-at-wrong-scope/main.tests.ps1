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

Describe 'a04-e04-role-at-wrong-scope' {
    It 'assigns built-in Reader' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $rd = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.roleDefinitionId'
        $rd.Found | Should -BeTrue
        $principal = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.principalId'
        $principal.Found | Should -BeTrue
        "$($principal.Value)" | Should -Match 'principalId'
        $pt = Get-PropertyValue -Object $ra[0].Resource -Path 'properties.principalType'
        $pt.Found | Should -BeTrue
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
        $raw | Should -Match 'subscriptionResourceId'
    }

    It 'names the assignment with guid(...), not a hard-coded or newGuid name' {
        $ra = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $n = [string]$ra[0].Name
        $n | Should -Match '\[guid\('
        $n | Should -Not -Match 'newGuid\('
        $n | Should -Not -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
        $n | Should -Match 'principalId'
    }

    It 'the assignment is at resource-group scope, not subscription' {
        $ra = @(Get-ExtensionResourcePlacements -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $ra.Count | Should -Be 1
        $ra[0].At | Should -Be 'resourceGroup'
        $n = [string]$ra[0].Name
        $n | Should -Match 'resourceGroup\(\)\.id|resourceGroups|resourceId\('
        $n | Should -Not -Match 'subscription\(\)\.id'
    }
}
