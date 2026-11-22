# a00-e06-lint-finding

## What was wrong
The storage account used a literal region string `eastus` for `location`.

## Mechanism
The course `bicepconfig.json` enables `no-hardcoded-location` at warning, and the harness treats warnings as failures. A location must come from a parameter (usually defaulting to `resourceGroup().location`).

## Which tool showed it
`bicep lint` rule `no-hardcoded-location` (also `pwsh -File scripts/check.ps1` / verify-all).
