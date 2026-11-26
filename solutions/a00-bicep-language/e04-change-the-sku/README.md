# a00-e04-change-the-sku `[MODIFY]` (S)

## Goal

Change the storage account SKU from geo-redundant to the cheapest locally redundant SKU.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- The resource type stays `Microsoft.Storage/storageAccounts`.
- `sku.name` is `Standard_LRS`.
- Do not change HTTPS, TLS, or public-access settings.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
