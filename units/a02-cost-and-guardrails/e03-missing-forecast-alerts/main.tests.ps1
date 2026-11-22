BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}

Describe 'a02-e03-missing-forecast-alerts' {


    It 'has Forecasted notifications at 80 and 100' {
        $b = @(Get-TemplateResources -Template $template -Type 'Microsoft.Consumption/budgets')
        $b.Count | Should -Be 1
        $n = Get-PropertyValue -Object $b[0].Resource -Path 'properties.notifications'
        $n.Found | Should -BeTrue
        $forecast = @($n.Value.Values | Where-Object { $_.thresholdType -eq 'Forecasted' })
        @($forecast | ForEach-Object { [int]$_.threshold }) | Should -Contain 80
        @($forecast | ForEach-Object { [int]$_.threshold }) | Should -Contain 100
    }
}
