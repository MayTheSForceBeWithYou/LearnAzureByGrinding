# a00-e03-first-resource `[WRITE]` (S)

## Goal

Write one StorageV2 account with a location parameter and outputs for the account name and resource id.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled template contains `Microsoft.Storage/storageAccounts`.
- `supportsHttpsTrafficOnly` is `true`.
- Outputs `accountName` and `accountId` exist.
- Use a parameter for location; do not hard-code a region.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`param location string = resourceGroup().location` and `uniqueString(resourceGroup().id)` for the name.

</details>
