BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a02-r02-budget-alert-thresholds' {
    It 'declares every resource type in ExpectResources' {
        Test-ExpectResources -Template $template -Types $manifest.ExpectResources | Should -BeNullOrEmpty
    }

    It 'has Actual 50/80/100 and Forecasted 80/100' {
        $b = @(Get-TemplateResources -Template $template -Type 'Microsoft.Consumption/budgets')
        $b.Count | Should -Be 1
        $n = Get-PropertyValue -Object $b[0].Resource -Path 'properties.notifications'
        $n.Found | Should -BeTrue
        $pairs = @($n.Value.Values | ForEach-Object { "$($_.thresholdType):$([int]$_.threshold)" })
        $pairs | Should -Contain 'Actual:50'
        $pairs | Should -Contain 'Actual:80'
        $pairs | Should -Contain 'Actual:100'
        $pairs | Should -Contain 'Forecasted:80'
        $pairs | Should -Contain 'Forecasted:100'
    }
}
