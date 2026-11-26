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

Describe 'a03-e04-lock-wrong-scope' {
    It 'the lock is CanNotDelete' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Authorization/locks'; Path = 'properties.level'; Value = 'CanNotDelete' }
        ) | Should -BeNullOrEmpty
    }

    It 'the lock is deployed at resource-group scope via a module, not at subscription' {
        $lock = @(Get-ExtensionResourcePlacements -Template $template -Type 'Microsoft.Authorization/locks')
        $lock.Count | Should -Be 1
        $lock[0].At | Should -Be 'resourceGroup'
    }
}
