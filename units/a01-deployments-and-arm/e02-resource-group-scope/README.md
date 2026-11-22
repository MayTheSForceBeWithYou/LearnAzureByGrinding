# a01-e02-resource-group-scope `[WRITE]` (S)

## Goal

Write a resource-group-scoped Bicep file that deploys a storage account and outputs its id.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- `targetScope` is `resourceGroup` (or omitted, which is the same default).
- The compiled `$schema` is the resource-group deployment schema, not the subscription schema.
- The compiled template contains `Microsoft.Storage/storageAccounts` and output `accountId`.
- `supportsHttpsTrafficOnly` is `true`.

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
