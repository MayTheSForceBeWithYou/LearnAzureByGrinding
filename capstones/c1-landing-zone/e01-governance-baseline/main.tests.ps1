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

Describe 'c1-e01-governance-baseline' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'is a subscription-scoped template' {
        $template['$schema'] | Should -Match 'subscriptionDeploymentTemplate.json'
    }

    It 'the guardrails resource group uses the lagb- prefix and the course tag set' {
        $rg = @(Get-TemplateResources -Template $template -Type 'Microsoft.Resources/resourceGroups')
        $rg.Count | Should -Be 1
        $name = "$($rg[0].Name)"
        $nameOk = ($name -match 'lagb-') -or ($name -match "parameters\('rgName'\)")
        $nameOk | Should -BeTrue
        $loc = Get-PropertyValue -Object $rg[0].Resource -Path 'location'
        $loc.Found | Should -BeTrue
        $tags = Get-PropertyValue -Object $rg[0].Resource -Path 'tags'
        $tags.Found | Should -BeTrue
        $tagText = ConvertTo-Json $tags.Value -Depth 20 -Compress
        $usesTagParam = $tagText -match "parameters\('tags'\)"
        $course = Get-PropertyValue -Object $rg[0].Resource -Path 'tags.course'
        $hasCourse = $course.Found -and ("$($course.Value)" -match 'LearnAzureByGrinding')
        ($usesTagParam -or $hasCourse) | Should -BeTrue
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'LearnAzureByGrinding'
    }

    It 'the lock is CanNotDelete on the resource group' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Authorization/locks'; Path = 'properties.level'; Value = 'CanNotDelete' }
        ) | Should -BeNullOrEmpty
        $lock = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/locks')
        $lock.Count | Should -Be 1
        (ConvertTo-Json $template -Depth 40 -Compress) | Should -Match 'lagb-cannotdelete'
        $placed = @(Get-ExtensionResourcePlacements -Template $template -Type 'Microsoft.Authorization/locks')
        $placed.Count | Should -Be 1
        $placed[0].At | Should -Be 'resourceGroup'
    }

    It 'the Policy assignment references built-in Allowed locations by resource id at subscription scope' {
        $as = @(Get-TemplateResources -Template $template -Type 'Microsoft.Authorization/policyAssignments')
        $as.Count | Should -BeGreaterOrEqual 1
        (ConvertTo-Json $template -Depth 40 -Compress) | Should -Match 'lagb-allowed-locations'
        $defId = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyDefinitionId'
        $defId.Found | Should -BeTrue
        $raw = ConvertTo-Json $template -Depth 40 -Compress
        $raw | Should -Match 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
        $raw | Should -Match 'tenantResourceId|/providers/Microsoft\.Authorization/policyDefinitions/'
        $raw | Should -Not -Match "subscriptionResourceId\('Microsoft\.Authorization/policyDefinitions'"
        $copied = Get-PropertyValue -Object $as[0].Resource -Path 'properties.policyRule'
        $copied.Found | Should -BeFalse
        $scope = Get-PropertyValue -Object $as[0].Resource -Path 'scope'
        if ($scope.Found) { "$($scope.Value)" | Should -Not -Match 'resourceGroups' }
    }

    It 'the Reader assignment is guid-named at resource-group scope' {
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
        $n = [string]$ra[0].Name
        $n | Should -Match '\[guid\('
        $n | Should -Not -Match 'newGuid\('
        $n | Should -Not -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
        $n | Should -Match 'principalId'
        $placed = @(Get-ExtensionResourcePlacements -Template $template -Type 'Microsoft.Authorization/roleAssignments')
        $placed.Count | Should -Be 1
        $placed[0].At | Should -Be 'resourceGroup'
        "$($placed[0].Name)" | Should -Match 'resourceGroup\(\)\.id|resourceGroups|resourceId\('
        "$($placed[0].Name)" | Should -Not -Match 'subscription\(\)\.id'
    }

    It 'the budget is Monthly Cost with Actual 50/80/100 and Forecasted 80/100' {
        $b = @(Get-TemplateResources -Template $template -Type 'Microsoft.Consumption/budgets')
        $b.Count | Should -Be 1
        "$($b[0].Resource.apiVersion)" | Should -Match '2024-08-01'
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Consumption/budgets'; Path = 'properties.category'; Value = 'Cost' }
            @{ ResourceType = 'Microsoft.Consumption/budgets'; Path = 'properties.timeGrain'; Value = 'Monthly' }
        ) | Should -BeNullOrEmpty
        $n = Get-PropertyValue -Object $b[0].Resource -Path 'properties.notifications'
        $n.Found | Should -BeTrue
        $pairs = @($n.Value.Values | ForEach-Object { "$($_.thresholdType):$([int]$_.threshold)" })
        $pairs | Should -Contain 'Actual:50'
        $pairs | Should -Contain 'Actual:80'
        $pairs | Should -Contain 'Actual:100'
        $pairs | Should -Contain 'Forecasted:80'
        $pairs | Should -Contain 'Forecasted:100'
        "$($b[0].Name)" | Should -Not -Match 'lagb-monthly'
        (ConvertTo-Json $template -Depth 40 -Compress) | Should -Match 'lagb-c1-baseline'
    }
}

Describe 'c1-e01 down.ps1 (mocked LabGuard and az)' {
    BeforeAll {
        $root = $PSScriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
        Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
        Import-Module (Join-Path $root 'scripts/lab/LabGuard.psm1') -Force
        $script:Down = Join-Path $PSScriptRoot 'down.ps1'
        $script:LabEnv = [pscustomobject]@{
            prefix                  = 'lagb'
            location                = 'eastus'
            owner                   = 'n8'
            budgetName              = 'lagb-c1-baseline'
            expectedSubscriptionId  = '00000000-0000-0000-0000-000000000000'
        }
    }

    It 'removes the lock before deleting the resource group' {
        Enable-AzMock -Fixtures @{
            'lock delete'                 = '{}'
            'policy assignment delete'    = '{}'
            'role assignment list'        = '[]'
            'consumption budget delete'   = '{}'
            'group delete'                = '{}'
        }
        try {
            & $script:Down -LabEnv $script:LabEnv
            $calls = @(Get-AzMockCalls)
            $lockI = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match 'lock delete' } | Select-Object -First 1
            $groupI = 0..($calls.Count - 1) | Where-Object { $calls[$_] -match 'group delete' } | Select-Object -First 1
            $lockI | Should -Not -BeNullOrEmpty
            $groupI | Should -Not -BeNullOrEmpty
            $lockI | Should -BeLessThan $groupI
        } finally {
            Disable-AzMock
        }
    }

    It 'does not delete when -WhatIf is set' {
        Enable-AzMock -Fixtures @{
            'lock delete'               = '{}'
            'policy assignment delete'  = '{}'
            'role assignment list'      = '[]'
            'consumption budget delete' = '{}'
            'group delete'              = '{}'
        }
        try {
            & $script:Down -LabEnv $script:LabEnv -WhatIf
            @(Get-AzMockCalls) | Should -HaveCount 0
        } finally {
            Disable-AzMock
        }
    }
}
