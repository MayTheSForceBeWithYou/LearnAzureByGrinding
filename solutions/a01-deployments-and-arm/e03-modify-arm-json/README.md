# a01-e03-modify-arm-json `[MODIFY]` (M)

## Goal

Modify the existing ARM JSON template so the storage account SKU is locally redundant.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- Edit `azuredeploy.json` (not Bicep).
- `sku.name` is `Standard_LRS`.
- Keep `$schema`, `contentVersion`, HTTPS, TLS, and name expression as shipped.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
