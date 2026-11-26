BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a02-e01-budget-and-action-group' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'declares Actual 50/80/100 and Forecasted 80/100 notifications' {
        $b = @(Get-TemplateResources -Template $template -Type 'Microsoft.Consumption/budgets')
        $b.Count | Should -Be 1
        $n = Get-PropertyValue -Object $b[0].Resource -Path 'properties.notifications'
        $n.Found | Should -BeTrue
        $keys = @($n.Value.Keys)
        $types = @($n.Value.Values | ForEach-Object { $_.thresholdType })
        $thresholds = @($n.Value.Values | ForEach-Object { [int]$_.threshold })
        ($types | Where-Object { $_ -eq 'Actual' }).Count | Should -Be 3
        ($types | Where-Object { $_ -eq 'Forecasted' }).Count | Should -Be 2
        $thresholds | Should -Contain 50
        $thresholds | Should -Contain 80
        $thresholds | Should -Contain 100
    }
    It 'the action group is enabled and emails contactEmail' {
        Test-ExpectProperties -Template $template -Expect @(
            @{ ResourceType = 'Microsoft.Insights/actionGroups'; Path = 'properties.enabled'; Value = $true }
        ) | Should -BeNullOrEmpty
    }
}
