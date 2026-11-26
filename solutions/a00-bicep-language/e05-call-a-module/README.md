# a00-e05-call-a-module `[WRITE]` (M)

## Goal

Write a `storage.bicep` module that declares a storage account, and call it from `main.bicep`.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The compiled deployment (including the module) contains `Microsoft.Storage/storageAccounts`.
- `main.bicep` calls the module with a `params` object whose names match the module parameters.
- Output `accountId` is the module's account id.
- `supportsHttpsTrafficOnly` is `true`.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

Module parameter names in the call must match the module file. Read outputs as `storageModule.outputs.accountId`.

</details>
