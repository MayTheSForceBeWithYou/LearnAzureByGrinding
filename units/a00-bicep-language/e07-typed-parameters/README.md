# a00-e07-typed-parameters `[WRITE]` (S)

## Goal

Write a storage account whose name and SKU are typed parameters with constraints.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- `accountName` is a string parameter with `minLength` 3 and `maxLength` 24.
- `skuName` is a string parameter whose allowed values include `Standard_LRS` and `Standard_GRS`.
- The compiled template contains `Microsoft.Storage/storageAccounts` and output `accountName`.
- `supportsHttpsTrafficOnly` is `true`.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
