# a01-e07-change-the-scope `[MODIFY]` (M)

## Goal

Change this file from a resource-group-scoped storage deployment into a subscription-scoped deployment that creates a resource group.

> **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and it parses. The resources, property changes, or commands you must write are not there yet, so the tests fail. There are no placeholder resources, and nothing to uncomment or delete to make the tests pass.

## Constraints

- `targetScope` is `subscription`.
- The compiled `$schema` is `subscriptionDeploymentTemplate.json`.
- The compiled template contains `Microsoft.Resources/resourceGroups` with a location.
- Do not deploy a storage account directly from subscription scope (use a module for that; this exercise stops at the resource group).

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.

<details>
<summary>Hint</summary>

`Microsoft.Resources/resourceGroups` is a subscription-scope type. Location still belongs in a parameter.

</details>
