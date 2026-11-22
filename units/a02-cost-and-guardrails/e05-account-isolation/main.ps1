# Course fixtures for az account show vs .lab-env.json. Not a live call.
Set-StrictMode -Version 3.0
$AccountFixturePath = Join-Path $PSScriptRoot 'fixtures/account-show.json'
$LabEnvFixturePath = Join-Path $PSScriptRoot 'fixtures/lab-env.json'
